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
│   │   ├── config.ex               # Configuration Structs
│   │   ├── plugin.ex               # Plugin Behaviour
│   │   ├── action.ex               # Action Struct Definitions
│   │   ├── action/
│   │   │   └── executor.ex         # Side-effect Runner
│   │   └── plugin/
│   │       └── phoenix_base.ex     # Core Generator Plugin 
│   │       └── elixir_base.ex      # Core Generator Plugin
│   └── mix/
│       └── tasks/
│           └── catalyst.new.ex     # CLI Entry Point
└── mix.exs
```

## Commands

To generate plain elixir app:

> mix catalyst.new [app_name] --plain

To generate phoenix app:

> mix catalyst.new [app_name]