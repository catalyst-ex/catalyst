# Catalyst CLI

Global Mix tasks for Catalyst.

This package is intended to be published as a Mix archive so users can run
commands such as `mix catalyst.run` and `mix catalyst.plugin` without adding
the CLI package directly to each project.

Plugin discovery is registry-based. If no registry config is present, the CLI
uses the official `catalyst-plugins` registry. Users can replace that default
with registry URLs or JSON files in `.catalyst.exs` or
`~/.catalyst/config.exs`:

```elixir
[
  registries: [
    "https://example.com/catalyst-registry.json",
    "priv/catalyst-registry.json"
  ]
]
```

Registry files use this shape:

```json
{
  "schema_version": 1,
  "package": "catalyst_plugins",
  "requirement": "~> 1.0",
  "plugins": {
    "credo": "Catalyst.Plugins.Credo",
    "sobelow": "Catalyst.Plugins.Sobelow"
  }
}
```
