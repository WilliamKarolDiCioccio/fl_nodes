# Gemini Project Context: FlNodes Framework

## General Instructions

- In all interactions and commit messages, be extremely concise and sacrifice grammar for the sake of concision.
- At the end of each plan, me a list of unresolved questions to answer,
  if any. Make the questions extremely concise. Sacrifice grammar for the sake
  of concision.

## Project Overview

This project is the **FlNodes Framework**, a modular, scalable ecosystem for building sophisticated node-based applications in Flutter. It is designed for creating professional-grade visual editors, workflow tools, and graph-based interfaces.

The project is structured as a monorepo managed with [Melos](https://melos.invertase.dev/). The architecture consists of several specialized packages:

- `fl_nodes_core`: The core engine that powers the framework, handling low-level rendering (using Flutter shaders) and infrastructure.
- `fl_nodes`: The main package that provides the high-level API. It acts as a proxy, exporting the core functionalities and maintaining backward compatibility.
- `fl_context_menu`: A utility package for creating context menus, likely used within the examples.
- Other packages like `fl_nodes_visual_scripting` and `fl_nodes_mind_maps` are planned.

The primary purpose of this framework is to enable the development of applications involving:

- Visual Scripting Editors
- Workflow & Process Designers
- Shader & Material Graphs
- Dataflow Tools
- Mind Maps and other Graph-Based UIs

## Building and Running

The project uses [Melos](https://melos.invertase.dev/) to manage common development tasks across the monorepo. The main scripts are defined in the root `pubspec.yaml`.

### Initial Setup

To get started with the project and install all dependencies for all packages, run the following Melos command from the root of the project:

```bash
melos bootstrap
```

### Running the Example Application

The main example application is located in `examples/fl_nodes_example`. It showcases the various features of the FlNodes framework. To run it, use the following Melos script:

```bash
melos run example
```

This will launch the example app in Google Chrome. There are also scripts for running in profile and release modes:

```bash
# Profile mode
melos run example:profile

# Release mode
melos run example:release
```

### Running Tests

To run all the tests across all packages in the monorepo, use the following Melos script:

```bash
melos run test
```

### Code Formatting and Analysis

To format the code and run the linter, use the following Melos scripts:

```bash
# Format all code
melos run format

# Analyze all code
melos run analyze
```

## Development Conventions

The project follows the standard Flutter linting rules (`package:flutter_lints/flutter.yaml`) with some specific additions and configurations defined in the `analysis_options.yaml` files within each package.

Key coding style conventions include:

- **Explicit Types:** Functions and methods should have explicit return types (`always_declare_return_types: true`).
- **Asynchronous Code:** `Future`s must be awaited (`await_only_futures: true`), and `unawaited_futures` are flagged.
- **Immutability:** Prefer `final` for local variables (`prefer_final_locals: true`) and `const` for constructors and declarations where possible.
- **Trailing Commas:** Trailing commas are required (`require_trailing_commas: true`) to improve auto-formatting with `dart format`.
- **No Print Statements:** The use of `print()` is discouraged and will be flagged by the linter (`avoid_print: true`). Use a proper logger instead.
- **Strong Mode:** The analyzer uses strong mode, but with `implicit-casts` and `implicit-dynamic` enabled, which is a slightly less strict configuration.
