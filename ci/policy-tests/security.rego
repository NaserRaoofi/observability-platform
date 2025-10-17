package kubernetes.security

# Deny containers without resource limits
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits
    msg := sprintf("Container '%s' does not have resource limits defined", [container.name])
}

# Deny containers without resource requests
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.requests
    msg := sprintf("Container '%s' does not have resource requests defined", [container.name])
}

# Deny containers running as root
deny[msg] {
    input.kind == "Deployment"
    input.spec.template.spec.securityContext.runAsUser == 0
    msg := "Container should not run as root user"
}

# Require security context
deny[msg] {
    input.kind == "Deployment"
    not input.spec.template.spec.securityContext
    msg := "Pod must have securityContext defined"
}

# Deny privileged containers
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("Container '%s' should not run in privileged mode", [container.name])
}

# Require readiness probes
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.readinessProbe
    msg := sprintf("Container '%s' must have readinessProbe defined", [container.name])
}

# Require liveness probes
deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.livenessProbe
    msg := sprintf("Container '%s' must have livenessProbe defined", [container.name])
}
