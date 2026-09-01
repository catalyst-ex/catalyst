# Catalyst

Catalyst is a dynamic patching system and "meta-framework" for scaffolding production-ready Elixir applications.

## Goals

- Automation: Eliminate repetitive manual setup for new client projects (CI/CD, Linters, Docker, Security).
- Consistency: Enforce architectural standards (folder structure, naming conventions) from line one.
- Flexibility: Allow features to be toggled via a configuration struct rather than maintaining multiple massive "boilerplate" repos.
- Safety: Use AST (Abstract Syntax Tree) manipulation for code editing, avoiding brittle regex replacements.

## High-Level Architecture

Catalyst operates on a Declarative Pipeline model. It does not execute logic immediately; instead, it resolves a list of intent (Actions) which are then executed by a central engine.

Core Concepts:

- Configuration
- Plugin System
- Action Engine
- Executor

## Project Structure

```txt
catalyst/
├── lib/
│   ├── catalyst.ex                 # Main Pipeline
│   ├── catalyst/
│   │   ├── action.ex               # Action Behaviour
│   │   ├── config.ex               # Configuration Structs
│   │   ├── plugin.ex               # Plugin Behaviour
│   │   ├── cli/                    # CLI support and registry lookup
│   │   ├── actions.ex              # Actions Type Contract
│   │   ├── actions/
│   │   │   ├── add_file.ex         # Action Struct + Runner
│   │   │   ├── add_dependency.ex   # Action Struct + Runner
│   │   │   ├── system_command.ex   # Action Struct + Runner
│   │   │   └── executor.ex         # Central Action Dispatcher
│   └── mix/tasks/                  # Global Mix archive commands
│       ├── catalyst.run.ex
│       ├── catalyst.plugin.ex
│       └── catalyst.registry.ex
└── mix.exs
```

## Commands

Catalyst runs from a config file:

> mix catalyst.run path/to/config.exs

Catalyst can generate a plugin registry from plugin source files:

> mix catalyst.registry --out registry.json lib/catalyst/plugins/*.ex

Use `--check` in CI to verify the registry is up to date:

> mix catalyst.registry --check --out registry.json lib/catalyst/plugins/*.ex

Official plugins live in the sibling `catalyst-plugins` repository.
The core package owns the engine, action APIs, and plugin behavior; the plugins
package owns built-in plugin modules and their templates.

## Configuration

Catalyst config supports two modes:

- `mode: :new` — scaffold a brand-new project at `app.path`
- `mode: :existing` — run Catalyst actions against an existing Mix project

Example (`mode: :new`):

```elixir
alias Catalyst.Config
alias Catalyst.Plugins

%Config{
	version: 1,
	mode: :new,
	app: %Config.App{
		name: "My App",
		path: "my_app",
		module: "MyApp"
	},
	plugins: [
		{Plugins.PhoenixBase,
		 phoenix: "1.18.4",
		 flags: [install: false, ecto: false, mailer: false]},
		{Plugins.Credo},
		{Plugins.Sobelow, strict_post_validate: false}
	]
}
```

Example (`mode: :existing`):

```elixir
alias Catalyst.Config
alias Catalyst.Plugins

%Config{
	version: 1,
	mode: :existing,
	app: %Config.App{
		path: "."
	},
	plugins: [
		{Plugins.Credo},
		{Plugins.Sobelow, strict_post_validate: false}
	]
}
```
