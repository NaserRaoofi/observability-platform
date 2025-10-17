# Terraform Tests

This directory contains tests for Terraform configurations to ensure infrastructure compliance and security.

## Test Categories

### 1. Security Tests (tfsec)

- Encryption validation
- IAM policy compliance
- Network security rules
- Resource tagging requirements

### 2. Compliance Tests

- Naming conventions
- Resource limits
- Cost optimization rules
- Backup requirements

### 3. Quality Tests

- Code formatting
- Documentation requirements
- Variable validation
- Output validation

## Running Tests

### Local Testing

```bash
# Format check
terraform fmt -check -recursive ../../terraform/

# Security scan
tfsec ../../terraform/

# Custom tests
go test ./...
```

### CI/CD Integration

Tests are automatically run in GitHub Actions on:

- Pull requests
- Push to main branch
- Manual workflow dispatch

## Test Files

### tfsec Configuration

```yaml
# .tfsec.yml
severity: MEDIUM
include:
  - aws-*
exclude:
  - aws-s3-bucket-public-read-prohibited # If public buckets are intentional
```

### Custom Test Examples

```hcl
# test_naming_convention.go
func TestNamingConvention(t *testing.T) {
    // Test that all resources follow naming convention
}

# test_security_groups.go
func TestSecurityGroups(t *testing.T) {
    // Test that security groups are properly configured
}
```

## Best Practices

- Write tests before implementing infrastructure
- Use descriptive test names
- Test both positive and negative scenarios
- Keep tests simple and focused
- Document test requirements
