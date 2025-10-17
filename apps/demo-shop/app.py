import logging
import random
import time

import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from opentelemetry import metrics, trace
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from pydantic import BaseModel

# Initialize OpenTelemetry
trace.set_tracer_provider(TracerProvider())
tracer = trace.get_tracer(__name__)

# OTLP Exporters
span_exporter = OTLPSpanExporter(endpoint="http://otel-collector:4317", insecure=True)
span_processor = BatchSpanProcessor(span_exporter)
trace.get_tracer_provider().add_span_processor(span_processor)

metric_exporter = OTLPMetricExporter(
    endpoint="http://otel-collector:4317", insecure=True
)
metric_reader = PeriodicExportingMetricReader(
    metric_exporter, export_interval_millis=5000
)
metrics.set_meter_provider(MeterProvider(metric_readers=[metric_reader]))

# Initialize FastAPI
app = FastAPI(title="Demo Shop", version="1.0.0")

# Instrument FastAPI
FastAPIInstrumentor.instrument_app(app)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Metrics
meter = metrics.get_meter(__name__)
request_counter = meter.create_counter(
    "http_requests_total", description="Total HTTP requests"
)
request_duration = meter.create_histogram(
    "http_request_duration_seconds", description="HTTP request duration"
)


# Models
class Product(BaseModel):
    id: int
    name: str
    price: float
    stock: int


class OrderItem(BaseModel):
    product_id: int
    quantity: int


class Order(BaseModel):
    items: list[OrderItem]


# Sample data
products = {
    1: Product(id=1, name="Laptop", price=999.99, stock=10),
    2: Product(id=2, name="Mouse", price=29.99, stock=50),
    3: Product(id=3, name="Keyboard", price=79.99, stock=25),
    4: Product(id=4, name="Monitor", price=299.99, stock=15),
}


@app.get("/")
async def root():
    return {"message": "Welcome to Demo Shop"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


@app.get("/products")
async def get_products():
    with tracer.start_as_current_span("get_products") as span:
        span.set_attribute("products.count", len(products))
        request_counter.add(1, {"method": "GET", "endpoint": "/products"})

        # Simulate some processing time
        time.sleep(random.uniform(0.01, 0.1))

        return list(products.values())


@app.get("/products/{product_id}")
async def get_product(product_id: int):
    with tracer.start_as_current_span("get_product") as span:
        span.set_attribute("product.id", product_id)
        request_counter.add(1, {"method": "GET", "endpoint": "/products/{id}"})

        if product_id not in products:
            span.set_attribute("error", True)
            raise HTTPException(status_code=404, detail="Product not found")

        # Simulate some processing time
        time.sleep(random.uniform(0.01, 0.05))

        return products[product_id]


@app.post("/orders")
async def create_order(order: Order):
    with tracer.start_as_current_span("create_order") as span:
        span.set_attribute("order.items_count", len(order.items))
        request_counter.add(1, {"method": "POST", "endpoint": "/orders"})

        start_time = time.time()

        # Simulate order processing
        total_amount = 0
        for item in order.items:
            if item.product_id not in products:
                span.set_attribute("error", True)
                raise HTTPException(
                    status_code=400, detail=f"Product {item.product_id} not found"
                )

            product = products[item.product_id]
            if product.stock < item.quantity:
                span.set_attribute("error", True)
                raise HTTPException(
                    status_code=400,
                    detail=f"Insufficient stock for product {item.product_id}",
                )

            total_amount += product.price * item.quantity
            product.stock -= item.quantity

        # Simulate payment processing
        time.sleep(random.uniform(0.1, 0.3))

        # Randomly fail 5% of orders
        if random.random() < 0.05:
            span.set_attribute("error", True)
            raise HTTPException(status_code=500, detail="Payment processing failed")

        order_id = random.randint(1000, 9999)
        span.set_attribute("order.id", order_id)
        span.set_attribute("order.total_amount", total_amount)

        duration = time.time() - start_time
        request_duration.record(duration, {"method": "POST", "endpoint": "/orders"})

        return {
            "order_id": order_id,
            "total_amount": total_amount,
            "status": "confirmed",
        }


@app.get("/chaos")
async def chaos():
    """Endpoint to trigger various failure scenarios for testing"""
    scenario = random.choice(["slow", "error", "memory", "success"])

    if scenario == "slow":
        # Simulate slow response
        time.sleep(random.uniform(2, 5))
        return {"scenario": "slow", "message": "This was a slow response"}
    elif scenario == "error":
        # Simulate server error
        raise HTTPException(status_code=500, detail="Simulated server error")
    elif scenario == "memory":
        # Simulate memory spike (don't actually consume too much)
        data = ["x" * 1000 for _ in range(1000)]
        time.sleep(0.1)
        del data
        return {"scenario": "memory", "message": "Memory spike simulated"}
    else:
        return {"scenario": "success", "message": "All good!"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
