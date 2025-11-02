package main

# Resource naming conventions
deny[msg] {
    input.metadata.name
    not regex.match("^[a-z][a-z0-9-]*[a-z0-9]$", input.metadata.name)
    msg := sprintf("Resource name '%s' must follow kebab-case convention", [input.metadata.name])
}

# Required labels for observability platform
deny[msg] {
    input.kind == "Deployment"
    not input.metadata.labels["app.kubernetes.io/part-of"]
    msg := "Deployment must have 'app.kubernetes.io/part-of' label"
}

deny[msg] {
    input.kind == "Deployment"
    not input.metadata.labels["app.kubernetes.io/component"]
    msg := "Deployment must have 'app.kubernetes.io/component' label"
}

deny[msg] {
    input.kind == "Deployment"
    not input.metadata.labels["app.kubernetes.io/version"]
    msg := "Deployment must have 'app.kubernetes.io/version' label"
}

# Resource limits enforcement
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Container '%s' must have memory limits", [container.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("Container '%s' must have CPU limits", [container.name])
}

# Image policy - no latest tags
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    endswith(container.image, ":latest")
    msg := sprintf("Container '%s' should not use 'latest' tag", [container.name])
}

# Replica count requirements for production
deny[msg] {
    input.kind == "Deployment"
    input.spec.replicas < 2
    input.metadata.namespace != "development"
    input.metadata.namespace != "default"
    msg := "Production deployments should have at least 2 replicas for high availability"
}
