# **fl_nodes_core**

[![pub package](https://img.shields.io/pub/v/fl_nodes_core.svg)](https://pub.dev/packages/fl_nodes_core)

> **Advanced Package**: This is the foundational core of the FlNodes Framework. Most users should use **Domain Packages** (coming soon, pre-built for specific use cases) such as `fl_nodes_visual_scripting` and `fl_nodes_mind_maps`. Use `fl_nodes_core` directly only if you have specialized low-level requirements.

---

## 📦 About This Package

`fl_nodes_core` is the engine that powers the FlNodes Framework. It provides the fundamental building blocks for node-based interfaces: rendering, hit testing, graph management, and state control.

### What This Package Provides

- **Low-level rendering** – Hardware-accelerated canvas operations
- **Node controller** – State management and lifecycle
- **Graph data structures** – Nodes, ports, edges, and relationships
- **Input handling** – Mouse, touch, and gesture processing
- **Hit testing** – Efficient spatial queries for user interactions
- **Viewport management** – Pan, zoom, and coordinate transformations
- **Serialization foundation** – Core save/load infrastructure

---

## 📦 Installation

Add `fl_nodes_core` to your `pubspec.yaml`:

```yaml
dependencies:
  fl_nodes_core: ^latest_version
```

And add the following asset:

```yaml
flutter:
  shaders:
    - packages/fl_nodes_core/shaders/grid.frag
```

Then run:

```bash
flutter pub get
```

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
