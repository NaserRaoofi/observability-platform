# Promtail - Log Collection Agent

This directory contains Grafana Promtail configuration using the official `grafana/promtail` chart for comprehensive Kubernetes log collection.

## Overview

Promtail is a log collection agent designed to work with Loki that provides:

- **Pod Log Collection**: Automatically discovers and collects logs from all Kubernetes pods
- **Log Processing**: Parses container logs, extracts metadata, and adds labels
- **Service Discovery**: Kubernetes-native discovery with automatic labeling
- **Reliable Delivery**: Retry logic and backoff for guaranteed log delivery
- **Minimal Footprint**: Lightweight DaemonSet with optimized resource usage

## Purpose

- **Log Collection**: Gathers logs from Kubernetes pods and nodes
- **Label Extraction**: Automatically extracts Kubernetes metadata as labels
- **Efficient Shipping**: Optimized for Loki's log format and API
- **Service Discovery**: Automatically discovers new pods and services

## Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Application │───▶│  Promtail   │───▶│    Loki     │
│    Logs     │    │  DaemonSet  │    │  (Storage)  │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Components

- **DaemonSet**: Runs on every node to collect logs
- **ConfigMap**: Configuration for log discovery and parsing
- **ServiceAccount**: RBAC permissions for Kubernetes API access
- **Service**: Internal communication endpoint

## Configuration Highlights

- **Node-level collection**: Gathers logs from all pods on each node
- **Kubernetes integration**: Automatic service discovery and labeling
- **Multi-tenant support**: Compatible with Loki's tenant isolation
- **Efficient batching**: Optimized log shipping to reduce overhead

## Integration

Works seamlessly with:

- **Loki**: Primary log storage backend
- **Grafana**: Log visualization and exploration
- **Kubernetes**: Native service discovery and metadata extraction
