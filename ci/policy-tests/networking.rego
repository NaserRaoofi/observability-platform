package kubernetes.networking

# Require NetworkPolicy for all namespaces with pods
deny[msg] {
    input.kind == "Namespace"
    input.metadata.name != "kube-system"
    input.metadata.name != "kube-public"
    input.metadata.name != "default"
    msg := sprintf("Namespace '%s' should have NetworkPolicy defined", [input.metadata.name])
}

# Deny services without proper selectors
deny[msg] {
    input.kind == "Service"
    not input.spec.selector
    msg := "Service must have selector defined"
}

# Require TLS for Ingress
deny[msg] {
    input.kind == "Ingress"
    not input.spec.tls
    msg := "Ingress must have TLS configuration"
}

# Deny LoadBalancer services in non-production environments
deny[msg] {
    input.kind == "Service"
    input.spec.type == "LoadBalancer"
    input.metadata.namespace != "ingress-nginx"
    msg := "LoadBalancer services should only be used in ingress-nginx namespace"
}
