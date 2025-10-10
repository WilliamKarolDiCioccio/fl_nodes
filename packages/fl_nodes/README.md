# **fl_nodes**

[![pub package](https://img.shields.io/pub/v/fl_nodes.svg)](https://pub.dev/packages/fl_nodes)

> **Migration Notice**: This package now serves as a compatibility layer for the FlNodes Framework. It re-exports functionality from `fl_nodes_core` to ensure a smooth migration path for existing projects.

---

<p align="center">
  <img src="https://raw.githubusercontent.com/WilliamKarolDiCioccio/fl_nodes/refs/heads/main/.github/images/node_editor_example.webp" alt="FlNodes Example" />
</p>

<p align="center">
  <i >A screenshot from our visual scripting example app</i>
</p>

---

## 📦 About This Package

The `fl_nodes` package is a proxy export package that maintains backward compatibility with earlier versions of the FlNodes framework. As FlNodes has evolved into a modular monorepo architecture, this package ensures that existing codebases can migrate seamlessly without breaking changes.

### What This Package Does

- **Re-exports** all public APIs from `fl_nodes_core`
- **Maintains** the same import paths and API surface
- **Simplifies** migration for existing projects
- **Provides** a stable entry point while the framework evolves

---

### 🔄 Migration Path

This package will continue to receive updates and maintain compatibility as the framework evolves. If you need more control or want to use the framework's modular architecture directly, consider using `fl_nodes_core` or the upcoming specialized packages.

---

### 💡 Use Cases

- 🎮 **Visual Scripting Editors** – Game logic, automation flows, state machines
- 🛠 **Workflow & Process Designers** – Business rules, decision trees, automation
- 🎨 **Shader & Material Graphs** – Visual shader creation
- 📊 **Dataflow Tools** – ETL pipelines, AI workflows, processing graphs
- 🤖 **ML Architecture Visualizers** – Neural network visualization
- 🔊 **Modular Audio Systems** – Synthesizers, effect chains, sequencers
- 🧠 **Graph-Based UIs** – Mind maps, dependency trees, hierarchies

---

## 🌟 Key Features

- ✅ **Customizable UI** – Override widgets, ports, fields, and layouts
- 💾 **Pluggable Storage** – JSON serialization with full control
- ⚡ **Optimized Performance** – Hardware-accelerated rendering
- 🔗 **Flexible Graph System** – Directional edges, typed ports, nested data
- 📏 **Scalable Architecture** – From simple diagrams to complex editors
- 🌐 **Localization Support** – Multi-language ready
- 🎨 **Beautiful by Default** – Minimal dependencies, easy to style

---

## 🛠 Roadmap

We're iterating fast, thanks to community adoption, forks, and feedback. Here's what's next:

### ⚙️ Performance Enhancements

- 📝 **Static Branch Precomputation** – Improve runtime by detecting and collapsing static branches in execution graphs.
- 🏃‍♂️‍➡️ **Graph Compilation Parallelization** – Make the editor more responsive by moving graph compilation to a separate isolate.

### 📚 Documentation Improvements

- Expanded API docs and usage examples.
- Guides for building tools like mind maps, audio tools, or ML visualizers.

### 🎛 General-Purpose Flexibility

- 🤖 **Node Configuration State Machine** – Dynamically add or remove ports and fields on nodes at runtime, allowing node structure to adapt automatically based on current links and input data.
- 🧑‍🤝‍🧑 **Node Grouping** – Enable users to select multiple nodes and group them together for easier organization, movement, and management within complex graphs.
- ♻️ **Reusable Graph Macros** – Allow users to define, save, and reuse templates or functions made up of multiple nodes, streamlining the creation of common patterns and workflows.
- 🎩 **Enhanced Editor Mode** – Introduce advanced, opt-in editing tools and keyboard shortcuts to improve productivity and provide a more powerful graph editing experience.

---

## 📦 Installation

Add `fl_nodes` to your `pubspec.yaml`:

```yaml
dependencies:
  fl_nodes: ^latest_version
```

Add the required assets to your `pubspec.yaml`:

```yaml
flutter:
  shaders:
    - packages/fl_nodes/shaders/grid.frag
```

Then run:

```bash
flutter pub get
```

---

## 🧩 **Examples & Demo**

Explore fully working examples:

- 📄 **[Code Example](https://github.com/WilliamKarolDiCioccio/fl_nodes/blob/main/example/lib/main.dart)**
- 🌍 **[Live Example](https://williamkaroldicioccio.github.io/fl_nodes/)**

---

### 🕹️ Current input support

**Legend:**

- ✅ Supported
- ❌ Unsupported
- ⚠️ Partial
- 🧪 Untested

| 🖥️Desktop and 💻 laptop: | Windows | Linux | macOS |
| ------------------------- | ------- | ----- | ----- |
| **native/mouse**          | ✅       | ✅     | ✅     |
| **native/trackpad**       | ✅       | ⚠️    | ✅     |
| **web/mouse**             | ✅       | ✅     | ✅     |
| **web/trackpad**          | ❌       | ❌     | ❌     |

| 📱Mobile   | Android | iOS |
| ---------- | ------- | --- |
| **native** | ✅       | 🧪  |
| **web**    | ✅       | 🧪  |

---

## 🙌 **Contributing**

We'd love your help in making **FlNodes** even better! You can contribute by:

- 💡 [Suggesting new features](https://github.com/WilliamKarolDiCioccio/fl_nodes/issues)
- 🐛 [Reporting bugs](https://github.com/WilliamKarolDiCioccio/fl_nodes/issues)
- 🔧 [Submitting pull requests](https://github.com/WilliamKarolDiCioccio/fl_nodes/pulls)
- 👏 [**Sharing what you've built**](https://github.com/WilliamKarolDiCioccio/fl_nodes/discussions/49)

---

## 📜 **License**

**FlNodes** is open-source and released under the [MIT License](LICENSE.md).
Contributions are welcome!

---

## 🚀 **Let's Build Together!**

Enjoy using **FlNodes** and create amazing node-based UIs for your Flutter apps! 🌟
