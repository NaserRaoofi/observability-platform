# Linting Configuration

This directory contains linting configurations and scripts for maintaining code quality across the observability stack.

## Supported File Types

### YAML/YML Files

- Kubernetes manifests
- Helm values
- GitHub Actions workflows
- Docker Compose files

### Markdown Files

- Documentation
- README files
- Runbooks

### JSON Files

- Grafana dashboards
- Configuration files

### Terraform Files

- .tf files
- .tfvars files

## Linting Tools

### yamllint

Configuration for YAML file linting

```yaml
# .yamllint.yml
extends: default
rules:
  line-length:
    max: 120
  indentation:
    spaces: 2
```

### markdownlint

Configuration for Markdown file linting

```json
{
  "MD013": { "line_length": 120 },
  "MD033": false,
  "MD041": false
}
```

### jsonlint

Basic JSON validation and formatting

## Running Linters

### Local Execution

```bash
# All files
make lint

# Specific types
./ci/lint/lint-yaml.sh
./ci/lint/lint-markdown.sh
./ci/lint/lint-json.sh
```

### CI/CD Integration

Linting is automatically run in GitHub Actions on:

- Pull requests
- Push to main branch

## Configuration Files

- `.yamllint.yml` - YAML linting rules
- `.markdownlint.json` - Markdown linting rules
- `lint-config.json` - General linting configuration
