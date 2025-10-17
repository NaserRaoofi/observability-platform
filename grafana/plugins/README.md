# Grafana Plugins

This directory contains custom Grafana plugins for the observability stack.

## Available Plugins

### Custom Plugins

- Place custom panel plugins here
- Place custom datasource plugins here
- Place custom app plugins here

## Installation

### Manual Installation

1. Place plugin directory in this folder
2. Restart Grafana pod
3. Enable plugin in Grafana admin panel

### Automated Installation

```yaml
# Add to Grafana Helm values
plugins:
  - custom-plugin-name
```

## Development

### Creating a Custom Panel Plugin

```bash
npx @grafana/toolkit plugin:create my-panel
cd my-panel
npm install
npm run build
```

### Plugin Structure

```
my-plugin/
├── src/
│   ├── plugin.json
│   ├── module.ts
│   └── components/
├── package.json
└── README.md
```

## Security Notes

- Only install trusted plugins
- Review plugin source code before installation
- Monitor plugin resource usage
- Keep plugins updated
