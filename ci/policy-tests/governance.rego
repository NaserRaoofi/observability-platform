package kubernetes.governance

import rego.v1

# Resource naming conventions
deny contains msg if {
    input.metadata.name
    not regex.match("^[a-z][a-z0-9-]*[a-z0-9]$", input.metadata.name)
    msg := sprintf("Resource name '%s' must follow kebab-case convention", [input.metadata.name])
}

# Required labels for observability platform
required_labels := {
    "app.kubernetes.io/part-of",
    "app.kubernetes.io/component",
    "app.kubernetes.io/version",
}

deny contains msg if {
    input.kind in ["Deployment", "StatefulSet", "DaemonSet", "Service"]
    missing := required_labels - {label | input.metadata.labels[label]}
    count(missing) > 0
    msg := sprintf("Missing required labels: %v", [missing])
}

# Resource limits enforcement
deny contains msg if {
    input.kind in ["Deployment", "StatefulSet", "DaemonSet"]
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Container '%s' must have memory limits", [container.name])
}

deny contains msg if {
    input.kind in ["Deployment", "StatefulSet", "DaemonSet"]
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("Container '%s' must have CPU limits", [container.name])
}

# Image policy
deny contains msg if {
    input.kind in ["Deployment", "StatefulSet", "DaemonSet"]
    container := input.spec.template.spec.containers[_]
    endswith(container.image, ":latest")
    msg := sprintf("Container '%s' should not use 'latest' tag", [container.name])
}

# PVC storage class requirement
deny contains msg if {
    input.kind == "PersistentVolumeClaim"
    not input.spec.storageClassName
    msg := "PersistentVolumeClaim must specify a storageClassName"
}

# Service type restrictions
deny contains msg if {
    input.kind == "Service"
    input.spec.type == "LoadBalancer"
    input.metadata.namespace != "ingress-system"
    msg := "LoadBalancer services should only be used in ingress-system namespace"
}

# Horizontal Pod Autoscaler requirements
deny contains msg if {
    input.kind in ["Deployment", "StatefulSet"]
    input.spec.replicas > 3
    not has_hpa
    msg := sprintf("Resource '%s' with >3 replicas should have HPA configured", [input.metadata.name])
}

has_hpa if {
    # This would need to be checked against existing HPAs in the cluster
    # For static analysis, we can check if HPA is defined in the same manifest
    input.kind == "HorizontalPodAutoscaler"
}

# Network policy requirement for sensitive workloads
sensitive_components := {
    "grafana",
    "mimir",
    "loki",
    "tempo",
    "alertmanager"
}

deny contains msg if {
    input.kind in ["Deployment", "StatefulSet"]
    component := input.metadata.labels["app.kubernetes.io/component"]
    component in sensitive_components
    input.metadata.namespace != "observability"
    msg := sprintf("Sensitive component '%s' must be deployed in 'observability' namespace", [component])
}

# ConfigMap and Secret size limits
deny contains msg if {
    input.kind == "ConfigMap"
    total_size := sum([count(input.data[key]) | key := input.data[_]])
    total_size > 1048576  # 1MB
    msg := "ConfigMap size should not exceed 1MB"
}

# Ingress TLS requirement
deny contains msg if {
    input.kind == "Ingress"
    not input.spec.tls
    msg := "Ingress must have TLS configured"
}
