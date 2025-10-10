# **🏗️ FlNodes Framework**

[![melos](https://img.shields.io/badge/maintained%20with-melos-f700ff.svg?style=flat-square)](https://github.com/invertase/melos)

The **FlNodes Framework** is a modular, scalable ecosystem for building sophisticated node-based applications in Flutter. Designed for developers who need professional-grade visual editors, workflow tools, and graph-based interfaces, FlNodes provides a complete solution from low-level rendering to high-level abstractions.

---

<p align="center">
  <img src="https://raw.githubusercontent.com/WilliamKarolDiCioccio/fl_nodes/refs/heads/main/.github/images/node_editor_example.webp" alt="FlNodes Example" />
</p>

<p align="center">
  <i >A screenshot from our visual scripting example app</i>
</p>

---

### 💡 Use Cases

Whether you're building tools for developers, designers, or end-users, **FlNodes** provides the building blocks for:

- 🎮 **Visual Scripting Editors** – Game logic, automation flows, or state machines.
- 🛠 **Workflow & Process Designers** – Business rules, decision trees, and automation paths.
- 🎨 **Shader & Material Graphs** – Build custom shaders visually.
- 📊 **Dataflow Tools** – ETL pipelines, AI workflows, and processing graphs.
- 🤖 **ML Architecture Visualizers** – Visualize and configure neural networks.
- 🔊 **Modular Audio Systems** – Synthesizers, effect chains, or sequencing tools.
- 🧠 **Graph-Based UIs** – Mind maps, dependency trees, and hierarchical structures.

---

## 🏗️ Framework Architecture

The FlNodes Framework is organized as a monorepo with specialized packages:

### 📦 Core Packages

- [**`fl_nodes_core`**](https://github.com/WilliamKarolDiCioccio/fl_nodes/tree/main/packages/fl_nodes_core) – The engine that powers the FlNodes Framework.

- [**`fl_nodes`**](https://github.com/WilliamKarolDiCioccio/fl_nodes/tree/main/packages/fl_nodes) – A proxy export package that maintains backward compatibility with earlier versions of the FlNodes framework.

### 🔌 Coming Soon

- **`fl_nodes_visual_scripting`** 
- **`fl_nodes_mind_maps`** 
- **`fl_nodes_flow_graphs`**

---

## 📚 **Getting Started**

For a fast and easy setup, check out our [Quickstart Guide](https://github.com/WilliamKarolDiCioccio/fl_nodes/wiki/Quickstart). It covers the basics to get you up and running with **FlNodes** in no time!

If you're migrating from an earlier version, the `fl_nodes` package maintains backward compatibility while providing access to the new modular architecture.

---

## 📦 **Installation**

Choose the package that fits your needs:

```yaml
dependencies:
  # For most users - high-level API with full features
  fl_nodes: ^latest_version

  # For advanced users needing low-level control
  fl_nodes_core: ^latest_version
```

Regardless of the package you choose you must add the following asset:

```yaml
flutter:
  shaders:
    - packages/fl_nodes_core/shaders/grid.frag
```

Then, run:

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
