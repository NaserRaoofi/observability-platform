import { check, sleep } from "k6";
import http from "k6/http";
import { Rate } from "k6/metrics";

// Custom metrics
export let errorRate = new Rate("errors");

export let options = {
  stages: [
    { duration: "2m", target: 10 }, // Ramp up to 10 users
    { duration: "5m", target: 10 }, // Stay at 10 users
    { duration: "2m", target: 20 }, // Ramp up to 20 users
    { duration: "5m", target: 20 }, // Stay at 20 users
    { duration: "2m", target: 0 }, // Ramp down to 0 users
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"], // 95% of requests should be below 500ms
    errors: ["rate<0.1"], // Error rate should be below 10%
  },
};

const BASE_URL = "http://demo-shop:8000";

export default function () {
  // Browse products
  let response = http.get(`${BASE_URL}/products`);
  check(response, {
    "products list status is 200": (r) => r.status === 200,
  }) || errorRate.add(1);

  sleep(1);

  // Get specific product
  let productId = Math.floor(Math.random() * 4) + 1;
  response = http.get(`${BASE_URL}/products/${productId}`);
  check(response, {
    "product detail status is 200": (r) => r.status === 200,
  }) || errorRate.add(1);

  sleep(1);

  // Create order (30% chance)
  if (Math.random() < 0.3) {
    let order = {
      items: [
        {
          product_id: productId,
          quantity: Math.floor(Math.random() * 3) + 1,
        },
      ],
    };

    response = http.post(`${BASE_URL}/orders`, JSON.stringify(order), {
      headers: { "Content-Type": "application/json" },
    });

    check(response, {
      "order creation status is 200": (r) => r.status === 200,
    }) || errorRate.add(1);
  }

  // Occasional chaos endpoint hit (5% chance)
  if (Math.random() < 0.05) {
    response = http.get(`${BASE_URL}/chaos`);
    // Don't count chaos endpoint errors against our error rate
  }

  sleep(2);
}
