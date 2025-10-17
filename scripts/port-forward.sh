#!/bin/bash

set -e

ENVIRONMENT=${1:-dev}
NAMESPACE="observability"

echo "🔗 Setting up port forwarding for $ENVIRONMENT environment..."

# Function to check if port is already in use
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        echo "⚠️  Port $port is already in use"
        return 1
    fi
    return 0
}

# Function to start port forward in background
start_port_forward() {
    local service=$1
    local local_port=$2
    local remote_port=$3

    if check_port $local_port; then
        echo "🚀 Port forwarding $service: localhost:$local_port -> $service:$remote_port"
        kubectl port-forward -n $NAMESPACE svc/$service $local_port:$remote_port &

        # Store PID for cleanup
        echo $! >> /tmp/port-forward-pids
    fi
}

# Create PID file for cleanup
rm -f /tmp/port-forward-pids
touch /tmp/port-forward-pids

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
kubectl wait --for=condition=ready pod -l app=grafana -n $NAMESPACE --timeout=300s || echo "Grafana not ready"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus -n $NAMESPACE --timeout=300s || echo "Prometheus not ready"

# Port forward main services
start_port_forward "grafana" 3000 3000
start_port_forward "prometheus-server" 9090 9090
start_port_forward "mimir-gateway" 8080 8080
start_port_forward "loki-gateway" 3100 3100
start_port_forward "tempo-query" 16686 16686
start_port_forward "otel-collector" 4317 4317
start_port_forward "demo-shop" 8000 8000

echo ""
echo "🎉 Port forwarding setup complete!"
echo ""
echo "🔗 Access URLs:"
echo "   - Grafana:      http://localhost:3000"
echo "   - Prometheus:   http://localhost:9090"
echo "   - Mimir:        http://localhost:8080"
echo "   - Loki:         http://localhost:3100"
echo "   - Tempo/Jaeger: http://localhost:16686"
echo "   - OTEL Collector: localhost:4317 (gRPC)"
echo "   - Demo Shop:    http://localhost:8000"
echo ""
echo "🔑 Default Grafana credentials:"
echo "   Username: admin"
echo "   Password: admin (change on first login)"
echo ""
echo "🛑 To stop all port forwarding:"
echo "   ./scripts/cleanup.sh"
echo ""
echo "💡 Tip: Keep this terminal open to maintain port forwarding"

# Function to cleanup on script exit
cleanup() {
    echo ""
    echo "🧹 Cleaning up port forwarding..."
    if [ -f /tmp/port-forward-pids ]; then
        while read pid; do
            kill $pid 2>/dev/null || true
        done < /tmp/port-forward-pids
        rm -f /tmp/port-forward-pids
    fi
}

# Set trap to cleanup on script exit
trap cleanup EXIT

# Keep script running
echo "Press Ctrl+C to stop port forwarding"
wait
