# AGENTS.md

Instructions for AI coding agents (Claude Code, Gemini, etc.) working in this repo.

## General Instructions

- Be extremely concise in all interactions and commit messages. Sacrifice grammar for concision.
- At the end of each plan, provide a list of unresolved questions (if any). Keep them extremely concise.

## Project Overview

FlNodes — modular Flutter framework for node-based visual editors and graph interfaces. Melos-managed monorepo.

### Package Architecture

Workspace members (see `pubspec.yaml` `workspace:` section):

- **`packages/fl_nodes_core`**: Core engine — rendering (Flutter shaders), infrastructure, node graph system. Where fundamental logic lives.
- **`packages/fl_nodes`**: Proxy package re-exporting `fl_nodes_core` for backward compatibility.
- **`packages/fl_context_menu`**: Context menu utility used in examples.
- **`examples/fl_nodes_example`**: Main example app showcasing the framework.
- **`examples/fl_context_menu_example`**: Context menu example.
- **`benchmarks`**: Performance benchmarks.

`packages/fl_nodes_visual_scripting` and `packages/fl_nodes_mind_maps` are stub packages in the workspace (not yet implemented).

## Commands

All defined in root `pubspec.yaml` under `melos: scripts:`:

```bash
melos bootstrap              # Install all deps
melos run example            # Run example in Chrome
melos run example:profile    # Profile mode
melos run example:release    # Release mode
melos run format             # dart format across all packages
melos run analyze            # dart analyze --fatal-infos across all packages
```

**Note:** There is no `melos run test` script. Run tests manually per-package with `flutter test`.

## Core Architecture

The codebase is best understood by reading these key files directly:

### Controller (`packages/fl_nodes_core/lib/src/core/controller/`)

- **`core.dart`** — `FlNodesController`: Central orchestrator. Manages viewport (offset/zoom/LOD), node/link collections, selection state, dirty flags.
- **`runner.dart`** — `FlNodesExecutionHelper`: Graph execution via topological sorting, hierarchical subgraphs, per-node execution state tracking. Optional — framework works without it.
- **`clipboard.dart`** — Copy/paste operations
- **`history.dart`** — Undo/redo
- **`project.dart`** — Save/load
- **`overlay.dart`** — UI overlay management
- **`callback.dart`** — Callback handling

### Data Models (`packages/fl_nodes_core/lib/src/core/models/data.dart`)

Hierarchical: `FlNodePrototype` → `FlNodeDataModel` with `FlPortPrototype`/`FlPortDataModel`, `FlFieldPrototype`/`FlFieldDataModel`, `FlLinkDataModel`. State objects: `FlNodeState`, `FlPortState`, `FlLinkState`.

### Event System (`packages/fl_nodes_core/lib/src/core/events/`)

- **`events.dart`** — Event classes (`FlGraphEditClassEvent`, `FlViewportClassEvent`) and category mixins (`FlTreeEventCat`, `FlPaintEventCat`, `FlLayoutEventCat`)
- **`bus.dart`** — `NodeEditorEventBus` for inter-subsystem communication

### Rendering (`packages/fl_nodes_core/lib/src/widgets/`)

- **`node_editor.dart`** — Main widget
- **`node_editor_render_object.dart`** — Custom RenderObject for low-level rendering
- **`../../../shaders/grid.frag`** — Fragment shader for grid rendering

### Other Core (`packages/fl_nodes_core/lib/src/core/`)

- **`containers/spatial_hash_grid.dart`** — `SpatialHashGrid` for spatial queries
- **`models/config.dart`** — `FlNodesConfig` (auto-build/auto-exec settings)

## Coding Conventions

### Linting

Rules configured in `examples/fl_nodes_example/analysis_options.yaml` (the most complete config). Core packages inherit from `package:flutter_lints/flutter.yaml`.

Key rules enforced:

- Explicit return types (`always_declare_return_types`)
- `final` for locals (`prefer_final_locals`)
- Trailing commas required (`require_trailing_commas`)
- No `print()` (`avoid_print`) — use proper logger
- All futures awaited (`unawaited_futures`)

### Key Patterns

1. **Snap-to-Grid**: Nodes have snapped (`node.offset`) and unsnapped (`unboundNodeOffsets[id]`) positions
2. **Event Handling**: Check `event.isHandled` before processing
3. **Dirty Flags**: Set `nodesDataDirty`/`linksDataDirty` for rendering changes
4. **Node Prototypes**: Register via `controller.registerNodePrototype()` — uses human-readable `idName` strings, not UUIDs
5. **Port Linking**: Directional (output → input). Validate with `port.canLinkTo()`

### State Management

- `ChangeNotifier` on controller
- `ValueNotifier` for viewport properties
- Selection tracked in `selectedNodeIds`/`selectedLinkIds` sets

## Special Considerations

- Flutter shaders require `flutter pub get` after adding shader assets
- Backward compat maintained via the `fl_nodes` proxy package
- New engine-level features go in `fl_nodes_core`; domain-specific features go in specialized packages
- Graph execution is optional — pure visual editing works without it
