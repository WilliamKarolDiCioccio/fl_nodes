import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

import 'package:fl_nodes/src/constants.dart';
import 'package:fl_nodes/src/core/controller/core.dart';
import 'package:fl_nodes/src/core/events/events.dart';
import 'package:fl_nodes/src/core/helpers/single_listener_change_notifier.dart';
import 'package:fl_nodes/src/core/models/data_adapters_v1.dart';
import 'package:fl_nodes/src/styles/styles.dart';

typedef LocalizedString = String Function(BuildContext context);

typedef FromTo = ({String from, String to, String fromPort, String toPort});

/// A helper class that handles the conversion of data to and from JSON.
class DataHandler {
  final String Function(dynamic data) toJson;
  final dynamic Function(String json) fromJson;

  DataHandler(this.toJson, this.fromJson);
}

/// The state of a link painted on the canvas.
class FlLinkState {
  bool isHovered; // Not saved as it is only used during rendering
  bool isSelected; // Not saved as it is only used during rendering

  FlLinkState({
    this.isHovered = false,
    this.isSelected = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlLinkState &&
          runtimeType == other.runtimeType &&
          isHovered == other.isHovered &&
          isSelected == other.isSelected;

  @override
  int get hashCode => isHovered.hashCode ^ isSelected.hashCode;
}

/// A link is a connection between two ports.
final class FlLinkDataModel {
  final String id;
  final FromTo fromTo;
  final FlLinkState state;

  FlLinkDataModel({
    required this.id,
    required this.fromTo,
    required this.state,
  });

  Map<String, dynamic> toJson() => toJsonV1();

  factory FlLinkDataModel.fromJson(Map<String, dynamic> json) =>
      FlLinkDataModelV1Adapter.fromJsonV1(json);

  FlLinkDataModel copyWith({
    String? id,
    FromTo? fromTo,
    FlLinkState? state,
    List<Offset>? joints,
  }) {
    return FlLinkDataModel(
      id: id ?? this.id,
      fromTo: fromTo ?? this.fromTo,
      state: state ?? this.state,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlLinkDataModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fromTo == other.fromTo;

  @override
  int get hashCode => id.hashCode ^ fromTo.hashCode;
}

class TempLinkDataModel {
  final FlLinkStyle style;
  final Offset from;
  final Offset to;

  TempLinkDataModel({
    required this.style,
    required this.from,
    required this.to,
  });
}

enum FlPortDirection {
  input,
  output,
  ignore,
}

enum FlPortType {
  data,
  control,
  ignore,
}

/// A port prototype is the blueprint for a port instance.
///
/// It defines the name, data type, direction, and if it allows multiple links.
abstract class FlPortPrototype {
  final String idName;
  final LocalizedString displayName;
  final PortStyleBuilder styleBuilder;
  final Type dataType;
  final FlPortDirection direction;
  final FlPortType type;

  FlPortPrototype({
    required this.idName,
    required this.displayName,
    this.styleBuilder = flDefaultPortStyleBuilder,
    this.dataType = dynamic,
    required this.direction,
    required this.type,
  });

  bool compatibleWith(FlPortPrototype other);
}

class FlDataInputPortPrototype<T> extends FlPortPrototype {
  FlDataInputPortPrototype({
    required super.idName,
    required super.displayName,
    super.styleBuilder,
  }) : super(
          dataType: T,
          direction: FlPortDirection.input,
          type: FlPortType.data,
        );

  // called by [DataOutputPortPrototype.compatibleWith], see note there
  bool _isCompatibleWithOutput(FlPortPrototype other) =>
      other is FlDataOutputPortPrototype<T>;

  @override
  bool compatibleWith(FlPortPrototype other) => _isCompatibleWithOutput(other);
}

class FlDataOutputPortPrototype<T> extends FlPortPrototype {
  FlDataOutputPortPrototype({
    required super.idName,
    required super.displayName,
    super.styleBuilder,
  }) : super(
          dataType: T,
          direction: FlPortDirection.output,
          type: FlPortType.data,
        );

  // the check we'd like to make here is:
  //    other is DataInputPortPrototype<U> && T is U
  //      => if [other] is an Input<Animal>, then we should be an Output<Animal/Cat/Dog/...>
  // which could also be written:
  //    DataInputPortPrototype<T> is other.runtimeType
  //    => Input<Cat> is Input<Animal>
  //
  // unfortunately dart's type/reflection system is extremely limited,
  // so you can't easily do that sort of check; instead, we (ab)use the
  // fact that /instances/ know the actual type parameter, so we ask it
  // to perform the type check for us
  @override
  bool compatibleWith(FlPortPrototype other) =>
      other is FlDataInputPortPrototype && other._isCompatibleWithOutput(this);
}

class FlControlInputPortPrototype extends FlPortPrototype {
  FlControlInputPortPrototype({
    required super.idName,
    required super.displayName,
    required super.styleBuilder,
  }) : super(direction: FlPortDirection.input, type: FlPortType.control);

  @override
  bool compatibleWith(FlPortPrototype other) =>
      other is FlControlOutputPortPrototype;
}

class FlControlOutputPortPrototype extends FlPortPrototype {
  FlControlOutputPortPrototype({
    required super.idName,
    required super.displayName,
    required super.styleBuilder,
  }) : super(direction: FlPortDirection.output, type: FlPortType.control);

  @override
  bool compatibleWith(FlPortPrototype other) =>
      other is FlControlInputPortPrototype;
}

class FlGenericPortPrototype extends FlPortPrototype {
  FlGenericPortPrototype({
    required super.idName,
    required super.displayName,
    super.styleBuilder,
  }) : super(direction: FlPortDirection.ignore, type: FlPortType.ignore);

  @override
  bool compatibleWith(FlPortPrototype other) => true;
}

/// The state of a port painted on the canvas.
class FlPortState with SingleListenerChangeNotifier {
  bool _isHovered;
  bool get isHovered => _isHovered;
  set isHovered(bool val) {
    if (_isHovered == val) return;
    _isHovered = val;
    notifyListeners();
  }

  FlPortState({
    bool isHovered = false,
  }) : _isHovered = isHovered;

  // since isHovered is only meaningful during rendering, no need to save/restore it
  factory FlPortState.fromJson(Map<String, dynamic> json) => FlPortState();
  Map<String, dynamic> toJson() => {};

  FlPortState copyWith({bool? isHovered}) =>
      FlPortState(isHovered: isHovered ?? this.isHovered);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlPortState &&
          runtimeType == other.runtimeType &&
          isHovered == other.isHovered;

  @override
  int get hashCode => isHovered.hashCode;
}

/// A port is a connection point on a node.
///
/// In addition to the prototype, it holds the data, links, and offset.
final class FlPortDataModel {
  final FlPortPrototype prototype;
  dynamic data; // Not saved as it is only used during in graph execution
  Set<FlLinkDataModel> links = {};
  final FlPortState state;
  Offset offset; // Determined by Flutter
  final GlobalKey key = GlobalKey(); // Determined by Flutter

  FlPortDataModel({
    required this.prototype,
    required this.state,
    this.offset = Offset.zero,
  }) {
    // rebuild the cached style when the state changes
    state.listener = () => _portStyle = null;
  }

  FlPortStyle? _portStyle;
  FlPortStyle get style => _portStyle ??= prototype.styleBuilder(state);

  Map<String, dynamic> toJson() => toJsonV1();

  factory FlPortDataModel.fromJson(
    Map<String, dynamic> json,
    Map<String, FlPortPrototype> portPrototypes,
  ) =>
      FlPortDataModelV1Adapter.fromJsonV1(json, portPrototypes);

  FlPortDataModel copyWith({
    dynamic data,
    Set<FlLinkDataModel>? links,
    FlPortState? state,
    Offset? offset,
  }) {
    final instance = FlPortDataModel(
      prototype: prototype,
      // we can't reuse the same instance, since they should only
      // notify the new [PortInstance] object, not the old ones
      state: (state ?? this.state).copyWith(),
      offset: offset ?? this.offset,
    );

    instance.links = links ?? this.links;

    return instance;
  }
}

typedef OnVisualizerTap = Function(
  dynamic data,
  Function(dynamic data) setData,
);

typedef EditorBuilder = Widget Function(
  BuildContext context,
  Function() removeOverlay,
  dynamic data,
  Function(dynamic data, {required FlFieldEventType eventType}) setData,
);

/// A field prototype is the blueprint for a field instance.
///
/// It is used to store variables for use in the onExecute function of a node.
/// If explicitly allowed, the user can change the value of the field.
class FlFieldPrototype {
  final String idName;
  final LocalizedString displayName;
  final FlFieldStyle style;
  final Type dataType;
  final dynamic defaultData;
  final Widget Function(dynamic data) visualizerBuilder;
  final OnVisualizerTap? onVisualizerTap;
  final EditorBuilder? editorBuilder;

  FlFieldPrototype({
    required this.idName,
    required this.displayName,
    this.style = const FlFieldStyle.basic(),
    this.dataType = dynamic,
    this.defaultData,
    required this.visualizerBuilder,
    this.onVisualizerTap,
    this.editorBuilder,
  }) : assert(onVisualizerTap != null || editorBuilder != null);
}

/// A field is a variable that can be used in the onExecute function of a node.
///
/// In addition to the prototype, it holds the data.
class FlFieldDataModel {
  final FlFieldPrototype prototype;
  final editorOverlayController = OverlayPortalController();
  dynamic data;
  final GlobalKey key = GlobalKey(); // Determined by Flutter

  FlFieldDataModel({
    required this.prototype,
    required this.data,
  });

  Map<String, dynamic> toJson(Map<Type, DataHandler> dataHandlers) =>
      toJsonV1(dataHandlers);

  factory FlFieldDataModel.fromJson(
    Map<String, dynamic> json,
    Map<String, FlFieldPrototype> fieldPrototypes,
    Map<Type, DataHandler> dataHandlers,
  ) =>
      FlFieldDataModelV1Adapter.fromJsonV1(json, fieldPrototypes, dataHandlers);

  FlFieldDataModel copyWith({dynamic data}) {
    return FlFieldDataModel(prototype: prototype, data: data ?? this.data);
  }
}

typedef OnNodeExecute = Future<void> Function(
  Map<String, dynamic> ports,
  Map<String, dynamic> fields,
  Map<String, dynamic> execState,
  Future<void> Function(Set<String>) forward,
  void Function(Set<(String, dynamic)>) put,
);

/// A node prototype is the blueprint for a node instance.
///
/// It defines the name, description, color, ports, fields, and onExecute function.
final class FlNodePrototype {
  final String idName;
  final LocalizedString displayName;
  final LocalizedString description;
  final NodeStyleBuilder styleBuilder;
  final NodeHeaderStyleBuilder headerStyleBuilder;
  final List<FlPortPrototype> ports;
  final List<FlFieldPrototype> fields;
  final List<(String, Type, dynamic)> customData;
  final List<(String, Type, dynamic)> customState;
  final OnNodeExecute? onExecute;

  FlNodePrototype({
    required this.idName,
    required this.displayName,
    required this.description,
    this.styleBuilder = flDefaultNodeStyleBuilder,
    this.headerStyleBuilder = flDefaultNodeHeaderStyleBuilder,
    this.ports = const [],
    this.fields = const [],
    this.customData = const [],
    this.customState = const [],
    this.onExecute,
  });
}

/// The state of a node widget.
final class FlNodeState {
  bool isSelected; // Not saved as it is only used during rendering
  bool isCollapsed;
  bool isHovered;
  Map<String, dynamic> customState;

  FlNodeState({
    this.customState = const {},
    this.isSelected = false,
    this.isCollapsed = false,
    this.isHovered = false,
  });

  Map<String, dynamic> toJson() => toJsonV1();

  factory FlNodeState.fromJson(Map<String, dynamic> json) =>
      FlNodeStateV1Adapter.fromJsonV1(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlNodeState &&
          runtimeType == other.runtimeType &&
          isSelected == other.isSelected &&
          isCollapsed == other.isCollapsed;

  @override
  int get hashCode => isSelected.hashCode ^ isCollapsed.hashCode;
}

/// A node is a component in the node editor.
///
/// It holds the instances of the ports and fields, the offset, the data and the state.
final class FlNodeDataModel {
  final String id; // Stored to acceleate lookups

  // The resolved style for the node.
  late FlNodeStyle builtStyle;
  late FlNodeHeaderStyle builtHeaderStyle;

  final FlNodePrototype prototype;
  final Map<String, FlPortDataModel> ports;
  final Map<String, FlFieldDataModel> fields;
  final Map<String, dynamic> customData;
  final FlNodeState state;
  Offset offset; // User or system defined offset
  final GlobalKey key = GlobalKey(); // Determined by Flutter

  FlNodeDataModel({
    required this.id,
    required this.prototype,
    required this.ports,
    required this.fields,
    required this.state,
    this.customData = const {},
    this.offset = Offset.zero,
  });

  Map<String, dynamic> toJson(Map<Type, DataHandler> dataHandlers) =>
      toJsonV1(dataHandlers);

  factory FlNodeDataModel.fromJson(
    Map<String, dynamic> json, {
    required Map<String, FlNodePrototype> nodePrototypes,
    required Map<Type, DataHandler> dataHandlers,
  }) =>
      FlNodeDataModelV1Adapter.fromJsonV1(
        json,
        nodePrototypes: nodePrototypes,
        dataHandlers: dataHandlers,
      );

  FlNodeDataModel copyWith({
    String? id,
    Color? color,
    Map<String, FlPortDataModel>? ports,
    Map<String, FlFieldDataModel>? fields,
    FlNodeState? state,
    Function(FlNodeDataModel node)? onRendered,
    Offset? offset,
  }) {
    return FlNodeDataModel(
      id: id ?? this.id,
      prototype: prototype,
      ports: ports ?? this.ports,
      state: state ?? this.state,
      fields: fields ?? this.fields,
      offset: offset ?? this.offset,
    );
  }
}

final class FlNodesGroupDataModel {
  final String id;
  final String name;
  final Set<String> nodeIds;

  FlNodesGroupDataModel({
    required this.id,
    required this.name,
    required this.nodeIds,
  });

  Map<String, dynamic> toJson() => toJsonV1();

  factory FlNodesGroupDataModel.fromJson(Map<String, dynamic> json) =>
      FlNodesGroupDataModelV1Adapter.fromJsonV1(json);
}

FlPortDataModel createPort(String idName, FlPortPrototype prototype) {
  return FlPortDataModel(prototype: prototype, state: FlPortState());
}

FlFieldDataModel createField(String idName, FlFieldPrototype prototype) {
  return FlFieldDataModel(prototype: prototype, data: prototype.defaultData);
}

FlNodeState createNodeState(
  FlNodePrototype prototype,
) {
  return FlNodeState(
    customState: Map.fromEntries(
      prototype.customState.map((e) => MapEntry(e.$1, e.$3)),
    ),
  );
}

FlNodeDataModel createNode(
  FlNodePrototype prototype, {
  required FlNodeEditorController controller,
  required Offset offset,
}) {
  return FlNodeDataModel(
    id: const Uuid().v4(),
    prototype: prototype,
    ports: Map.fromEntries(
      prototype.ports.map((prototype) {
        final instance = createPort(prototype.idName, prototype);
        return MapEntry(prototype.idName, instance);
      }),
    ),
    fields: Map.fromEntries(
      prototype.fields.map((prototype) {
        final instance = createField(prototype.idName, prototype);
        return MapEntry(prototype.idName, instance);
      }),
    ),
    customData: Map.fromEntries(
      prototype.customData.map((e) => MapEntry(e.$1, e.$3)),
    ),
    state: createNodeState(prototype),
    offset: offset,
  );
}

FlNodesGroupDataModel createNodesGroup(
  String name,
  Set<String> nodeIds,
) {
  return FlNodesGroupDataModel(
    id: const Uuid().v4(),
    name: name,
    nodeIds: nodeIds,
  );
}

/// A container for all the data in a project.
class FlNodeEditorProjectDataModel {
  final String packageVersion;
  String appVersion;
  Offset viewportOffset;
  double viewportZoom;
  final Map<String, FlNodeDataModel> nodes;
  final Map<String, FlLinkDataModel> links;

  FlNodeEditorProjectDataModel({
    this.packageVersion = kPackageVersion,
    this.appVersion = '1.0.0',
    required this.nodes,
    required this.links,
    this.viewportOffset = Offset.zero,
    this.viewportZoom = 1.0,
  });

  Map<String, dynamic> toJson(
    Map<Type, DataHandler> dataHandlers,
  ) =>
      toJsonV1(dataHandlers);

  factory FlNodeEditorProjectDataModel.fromJson(
    Map<String, dynamic> json,
    Map<String, FlNodePrototype> nodePrototypes,
    Map<Type, DataHandler> dataHandlers,
  ) =>
      FlNodeEditorProjectDataModelV1Adapter.fromJsonV1(
        json,
        nodePrototypes,
        dataHandlers,
      );

  FlNodeEditorProjectDataModel copyWith() {
    return FlNodeEditorProjectDataModel(
      viewportOffset: viewportOffset,
      viewportZoom: viewportZoom,
      nodes: Map.fromEntries(
        nodes.entries.map((e) => MapEntry(e.key, e.value.copyWith())),
      ),
      links: Map.fromEntries(
        links.entries.map((e) => MapEntry(e.key, e.value)),
      ),
    );
  }
}
