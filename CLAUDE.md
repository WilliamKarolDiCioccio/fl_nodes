# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## General Instructions

- In all interactions and commit messages, be extremely concise and sacrifice grammar for the sake of concision.
- At the end of each plan, me a list of unresolved questions to answer,
  if any. Make the questions extremely concise. Sacrifice grammar for the sake
  of concision.

## Project Overview

FlNodes is a modular Flutter framework for building node-based visual editors and graph interfaces. This is a **Melos-managed monorepo** with specialized packages for different layers of abstraction.

### Package Architecture

- **`fl_nodes_core`**: Core engine handling rendering (using Flutter shaders), infrastructure, and the low-level node graph system. This is where the fundamental logic lives.
- **`fl_nodes`**: High-level proxy package that re-exports `fl_nodes_core` for backward compatibility with earlier versions.
- **`fl_context_menu`**: Utility package for context menus used in examples.
- **`fl_nodes_visual_scripting`** & **`fl_nodes_mind_maps`**: Placeholder packages for future specialized implementations.

## Essential Commands

### Initial Setup

```bash
melos bootstrap
```

### Development

```bash
# Run main example (opens in Chrome)
melos run example

# Run in profile/release mode
melos run example:profile
melos run example:release

# Format code
melos run format

# Analyze code
melos run analyze

# Run tests
melos run test
```

### Working with Individual Packages

When working on a specific package, you can use standard Flutter commands within that package directory, but prefer `melos` commands from the root for consistency.

## Core Architecture

### Controller-Based System

The framework is built around `FlNodesController` (packages/fl_nodes_core/lib/src/core/controller/core.dart), which orchestrates the entire node editor. The controller:

- Manages viewport (offset, zoom, LOD levels)
- Maintains node/link collections and their state
- Provides specialized subsystems as helpers:
  - **`runner`**: Graph execution engine for visual scripting (packages/fl_nodes_core/lib/src/core/controller/runner.dart)
  - **`clipboard`**: Copy/paste operations
  - **`history`**: Undo/redo management
  - **`project`**: Save/load project data
  - **`overlay`**: UI overlay management
- Uses an event bus (`NodeEditorEventBus`) for communication between subsystems

### Data Models

Node graph data is organized hierarchically:

- **`FlNodePrototype`**: Template definition for a node type (registered with the controller)
- **`FlNodeDataModel`**: Runtime instance of a node with state, ports, fields, and position
- **`FlPortPrototype`** / **`FlPortDataModel`**: Port definitions and instances (data/control, input/output)
- **`FlLinkDataModel`**: Connection between two ports
- **`FlFieldDataModel`**: Editable fields within nodes

All located in packages/fl_nodes_core/lib/src/core/models/data.dart

### Event System

The framework uses a hierarchical event system (packages/fl_nodes_core/lib/src/core/events/events.dart):

- **Event Classes**: Semantic categories (FlGraphEditClassEvent, FlViewportClassEvent, etc.)
- **Event Categories**: Mixins for rendering traits (FlTreeEventCat, FlPaintEventCat, FlLayoutEventCat)
- **Dirty Flags**: Controller maintains `nodesDataDirty` and `linksDataDirty` flags to optimize repaints

Events flow through the `eventBus` and can be marked as `isHandled`, `isUndoable`, or `isSideEffect`.

### Graph Execution (Runner)

The `FlNodesExecutionHelper` provides visual scripting execution:

- Builds execution graph via topological sorting
- Handles hierarchical subgraphs for control flow
- Manages data dependencies between nodes
- Tracks execution state per node (idle, pending, executing, stepped, completed, exception)
- Supports auto-rebuild and auto-execution modes (configured via `FlNodesConfig`)

### Rendering Architecture

- **Custom RenderObject**: packages/fl_nodes_core/lib/src/widgets/node_editor_render_object.dart handles low-level rendering
- **Flutter Shaders**: Grid rendering uses a custom fragment shader (packages/fl_nodes_core/shaders/grid.frag)
- **LOD System**: Level-of-detail rendering based on zoom level (0-4 levels)
- **Spatial Hashing**: `SpatialHashGrid` accelerates node selection by area queries

### State Management

- Uses `ChangeNotifier` on the controller
- `ValueNotifier` for viewport properties (offset, zoom, LOD level)
- Separate state objects (`FlNodeState`, `FlLinkState`, `FlPortState`) within data models
- Selection tracked in controller's `selectedNodeIds` and `selectedLinkIds` sets

## Coding Conventions

### Linting Rules

- Explicit return types required (`always_declare_return_types`)
- Prefer `final` for local variables (`prefer_final_locals`)
- Trailing commas required (`require_trailing_commas`)
- No `print()` statements (`avoid_print`) - use proper logger
- All futures must be awaited (`unawaited_futures`)

### Important Patterns

1. **Snap-to-Grid**: Nodes maintain both snapped (`node.offset`) and unsnapped (`unboundNodeOffsets[id]`) positions
2. **Event Handling**: Always check `event.isHandled` before processing events in listeners
3. **Dirty Flags**: Set `nodesDataDirty` or `linksDataDirty` when making changes that affect rendering
4. **Node Prototypes**: Register with `controller.registerNodePrototype()` before use, identified by human-readable `idName` strings (not UUIDs)
5. **Port Linking**: Links are directional and enforced (output → input). Use `port.canLinkTo()` to validate before creating links.

## Key Files

- **Controller**: packages/fl_nodes_core/lib/src/core/controller/core.dart
- **Data Models**: packages/fl_nodes_core/lib/src/core/models/data.dart
- **Events**: packages/fl_nodes_core/lib/src/core/events/events.dart
- **Runner**: packages/fl_nodes_core/lib/src/core/controller/runner.dart
- **Node Editor Widget**: packages/fl_nodes_core/lib/src/widgets/node_editor.dart
- **Main Export**: packages/fl_nodes_core/lib/fl_nodes_core.dart

## Testing & Running

- Example app location: examples/fl_nodes_example
- Always run from root using `melos run example` for consistency
- Tests run with `melos run test` across all packages

## Special Considerations

- This framework uses Flutter shaders - ensure `flutter pub get` has been run after adding shader assets
- The framework maintains backward compatibility through the `fl_nodes` proxy package
- When adding features to core, consider whether they belong in `fl_nodes_core` (engine-level) or future specialized packages
- Graph execution is optional - the framework supports pure visual editing without execution logic
