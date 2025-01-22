import 'package:fl_nodes/src/core/controllers/node_editor_events.dart';
import 'package:flutter/material.dart';

import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';

import 'package:fl_nodes/src/core/utils/serialization.dart';

/// Entities are split in two categories: Prototypes and Instances.
///
/// Prototypes are the blueprint for the instances. They define the structure
/// of the instances, like the name, description, color, ports, etc.
/// Instances are the actual objects that are created based on the prototypes
/// and hold the data and state of the application.

/// A group is a collection of nodes that are visually grouped together.
final class Group {
  final String name;
  final String description;
  final Color color;
  final Rect area;
  bool isHovered = false;

  Group({
    required this.name,
    this.description = '',
    this.color = Colors.grey,
    required this.area,
  });

  Group copyWith({
    String? name,
    String? description,
    Color? color,
    Rect? area,
  }) {
    return Group(
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      area: area ?? this.area,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'color': colorToRGBAString(color),
      'area': [area.left, area.top, area.width, area.height],
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      name: json['name'],
      description: json['description'],
      color: colorFromRGBAString(json['color']),
      area: Rect.fromLTWH(
        json['area'][0],
        json['area'][1],
        json['area'][2],
        json['area'][3],
      ),
    );
  }
}

/// A link is a connection between two ports.
final class Link {
  final String id;
  final Tuple4<String, String, String, String> fromTo;
  bool isHovered = false;

  Link({
    required this.id,
    required this.fromTo,
  });

  Link copyWith({
    String? id,
    Tuple4<String, String, String, String>? fromTo,
    List<Offset>? joints,
  }) {
    return Link(
      id: id ?? this.id,
      fromTo: fromTo ?? this.fromTo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'from': fromTo.item1,
      'to': fromTo.item2,
      'fromPort': fromTo.item3,
      'toPort': fromTo.item4,
    };
  }

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      id: json['id'],
      fromTo: Tuple4(
        json['from'],
        json['to'],
        json['fromPort'],
        json['toPort'],
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Link &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fromTo == other.fromTo;

  @override
  int get hashCode => id.hashCode ^ fromTo.hashCode;
}

/// A port prototype is the blueprint for a port instance.
///
/// It defines the name, data type, direction, and if it allows multiple links.
abstract class PortPrototype {
  final String name;
  final Type dataType;
  final bool isInput;
  final bool allowMultipleLinks;

  PortPrototype({
    required this.name,
    this.dataType = dynamic,
    required this.isInput,
    this.allowMultipleLinks = true,
  });
}

class InputPortPrototype extends PortPrototype {
  InputPortPrototype({
    required super.name,
    super.dataType,
    super.allowMultipleLinks,
  }) : super(isInput: true);
}

class OutputPortPrototype extends PortPrototype {
  OutputPortPrototype({
    required super.name,
    super.dataType,
    super.allowMultipleLinks,
  }) : super(isInput: false);
}

/// A port is a connection point on a node.
///
/// In addition to the prototype, it holds the data, links, and offset.
final class PortInstance {
  final String id;
  final String name;
  dynamic data;
  final Type dataType;
  final bool isInput;
  final bool allowMultipleLinks;
  Set<Link> links = {};
  Offset offset; // Determined by Flutter
  final GlobalKey key = GlobalKey(); // Determined by Flutter

  PortInstance({
    required this.id,
    required this.name,
    required this.data,
    required this.dataType,
    required this.isInput,
    required this.allowMultipleLinks,
    this.offset = Offset.zero,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'data': data,
      'isInput': isInput,
      'allowMultipleLinks': allowMultipleLinks,
      'links': links.map((link) => link.toJson()).toList(),
    };
  }

  factory PortInstance.fromJson(
    Map<String, dynamic> json,
    PortPrototype prototype,
  ) {
    final instance = PortInstance(
      id: json['id'],
      name: json['name'],
      data: json['data'],
      dataType: prototype.dataType,
      isInput: json['isInput'],
      allowMultipleLinks: json['allowMultipleLinks'],
    );

    instance.links = (json['links'] as List<dynamic>)
        .map((linkJson) => Link.fromJson(linkJson))
        .toSet();

    return instance;
  }

  PortInstance copyWith({
    String? id,
    String? name,
    dynamic data,
    Type? dataType,
    bool? isInput,
    bool? allowMultipleLinks,
    Set<Link>? links,
    Offset? offset,
  }) {
    final instance = PortInstance(
      id: id ?? this.id,
      name: name ?? this.name,
      data: data ?? this.data,
      dataType: dataType ?? this.dataType,
      isInput: isInput ?? this.isInput,
      allowMultipleLinks: allowMultipleLinks ?? this.allowMultipleLinks,
      offset: offset ?? this.offset,
    );

    instance.links = links ?? this.links;

    return instance;
  }
}

/// A field prototype is the blueprint for a field instance.
///
/// It is used to store variables for use in the onExecute function of a node.
/// If explicitly allowed, the user can change the value of the field.
class FieldPrototype {
  final String name;
  final Type dataType;
  final bool isEditable;
  final dynamic defaultData;
  final Widget Function(dynamic data) visualizerBuilder;
  final Function(FieldInstance field)? onVisualizerTap;
  final Widget Function(
    BuildContext context,
    Function() removeOverlay,
    dynamic data,
    Function(dynamic data, {required FieldEventType eventType}) setData,
  )? editorBuilder;

  FieldPrototype({
    required this.name,
    required this.dataType,
    this.isEditable = false,
    this.defaultData,
    required this.visualizerBuilder,
    this.onVisualizerTap,
    this.editorBuilder,
  }) : assert(onVisualizerTap != null || editorBuilder != null);
}

/// A field is a variable that can be used in the onExecute function of a node.
///
/// In addition to the prototype, it holds the data.
class FieldInstance {
  final String id;
  final String name;
  final bool isEditable;
  final Widget Function(dynamic data) visualizerBuilder;
  final Function(FieldInstance field)? onVisualizerTap;
  final Widget Function(
    BuildContext context,
    Function() removeOverlay,
    dynamic data,
    Function(dynamic data, {required FieldEventType eventType}) setData,
  )? editorBuilder;
  final editorOverlayController = OverlayPortalController();
  dynamic data;
  final Type dataType;
  final GlobalKey key = GlobalKey(); // Determined by Flutter

  FieldInstance({
    required this.id,
    required this.name,
    required this.isEditable,
    required this.visualizerBuilder,
    required this.onVisualizerTap,
    required this.editorBuilder,
    required this.data,
    required this.dataType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isEditable': isEditable,
      'data': data,
    };
  }

  factory FieldInstance.fromJson(
    Map<String, dynamic> json,
    FieldPrototype prototype,
  ) {
    return FieldInstance(
      id: json['id'],
      name: json['name'],
      isEditable: json['isEditable'],
      visualizerBuilder: prototype.visualizerBuilder,
      onVisualizerTap: prototype.onVisualizerTap,
      editorBuilder: prototype.editorBuilder,
      data: json['data'],
      dataType: prototype.dataType,
    );
  }

  FieldInstance copyWith({
    String? id,
    String? name,
    bool? isEditable,
    Widget Function(dynamic data)? visualizerBuilder,
    Function(FieldInstance field)? onVisualizerTap,
    Widget Function(
      BuildContext context,
      Function() removeOverlay,
      dynamic data,
      Function(dynamic data, {required FieldEventType eventType}) setData,
    )? editorBuilder,
    dynamic data,
    Type? dataType,
  }) {
    return FieldInstance(
      id: id ?? this.id,
      name: name ?? this.name,
      isEditable: isEditable ?? this.isEditable,
      visualizerBuilder: visualizerBuilder ?? this.visualizerBuilder,
      onVisualizerTap: onVisualizerTap ?? this.onVisualizerTap,
      editorBuilder: editorBuilder ?? this.editorBuilder,
      data: data ?? this.data,
      dataType: dataType ?? this.dataType,
    );
  }
}

/// A node prototype is the blueprint for a node instance.
///
/// It defines the name, description, color, ports, fields, and onExecute function.
final class NodePrototype {
  final String name;
  final String description;
  final Color color;
  final List<PortPrototype> ports;
  final List<FieldPrototype> fields;
  final Function(
    Map<String, PortInstance> inputs,
    Map<String, FieldInstance> fields,
    Map<String, PortInstance> outputs,
  ) onExecute;

  NodePrototype({
    required this.name,
    this.description = '',
    this.color = Colors.grey,
    this.ports = const [],
    this.fields = const [],
    required this.onExecute,
  });
}

/// The state of a node widget.
final class NodeState {
  bool isSelected;
  bool isCollapsed;

  NodeState({
    this.isSelected = false,
    this.isCollapsed = false,
  });

  factory NodeState.fromJson(Map<String, dynamic> json) {
    return NodeState(
      isSelected: json['isSelected'],
      isCollapsed: json['isCollapsed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isSelected': isSelected,
      'isCollapsed': isCollapsed,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeState &&
          runtimeType == other.runtimeType &&
          isSelected == other.isSelected &&
          isCollapsed == other.isCollapsed;

  @override
  int get hashCode => isSelected.hashCode ^ isCollapsed.hashCode;
}

/// A node is a component in the node editor.
///
/// It holds the instances of the ports and fields, the offset, the data and the state.
final class NodeInstance {
  final String id;
  final String name;
  final String description;
  final Color color;
  final Map<String, PortInstance> ports;
  final Map<String, FieldInstance> fields;
  final NodeState state = NodeState();
  final Function(
    Map<String, PortInstance> inputs,
    Map<String, FieldInstance> fields,
    Map<String, PortInstance> outputs,
  ) onExecute;
  final Function(NodeInstance node) onRendered;
  Offset offset; // User or system defined offset
  final GlobalKey key = GlobalKey(); // Determined by Flutter

  NodeInstance({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.ports,
    required this.fields,
    required this.onExecute,
    required this.onRendered,
    this.offset = Offset.zero,
  });

  NodeInstance copyWith({
    String? id,
    String? name,
    String? description,
    String? prototypeName,
    Color? color,
    Map<String, PortInstance>? ports,
    Map<String, FieldInstance>? fields,
    NodeState? state,
    Function(
      Map<String, PortInstance> inputs,
      Map<String, FieldInstance> fields,
      Map<String, PortInstance> outputs,
    )? onExecute,
    Function(NodeInstance node)? onRendered,
    Offset? offset,
  }) {
    return NodeInstance(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      ports: ports ?? this.ports,
      fields: fields ?? this.fields,
      onExecute: onExecute ?? this.onExecute,
      onRendered: onRendered ?? this.onRendered,
      offset: offset ?? this.offset,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': colorToRGBAString(color),
      'ports': ports.map((_, port) => MapEntry(port.id, port.toJson())),
      'fields': fields.map((_, field) => MapEntry(field.id, field.toJson())),
      'state': state.toJson(),
      'offset': [offset.dx, offset.dy],
    };
  }

  factory NodeInstance.fromJson(
    Map<String, dynamic> json, {
    required Map<String, NodePrototype> prototypes,
    required Function(NodeInstance node) onRendered,
  }) {
    if (!prototypes.containsKey(json['name'].toString())) {
      throw Exception('Node prototype not found');
    }

    final prototype = prototypes[json['name'].toString()]!;

    // Ensure `json['ports']` is properly typed
    final ports = (json['ports'] as Map<String, dynamic>).map(
      (id, portJson) {
        final portPrototype =
            prototype.ports[json['ports'].keys.toList().indexOf(id)];
        return MapEntry(
          id,
          PortInstance.fromJson(portJson, portPrototype),
        );
      },
    );

    // Ensure `json['fields']` is properly typed
    final fields = (json['fields'] as Map<String, dynamic>).map(
      (id, fieldJson) {
        final prototypeField =
            prototype.fields[json['fields'].keys.toList().indexOf(id)];
        return MapEntry(
          id,
          FieldInstance.fromJson(fieldJson, prototypeField),
        );
      },
    );

    final instance = NodeInstance(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      color: prototype.color,
      ports: ports,
      fields: fields,
      onExecute: prototype.onExecute,
      onRendered: onRendered,
      offset: Offset(json['offset'][0], json['offset'][1]),
    );

    instance.state.isSelected = NodeState.fromJson(json['state']).isSelected;
    instance.state.isCollapsed = NodeState.fromJson(json['state']).isCollapsed;

    return instance;
  }
}

PortInstance createPort(PortPrototype prototype) {
  return PortInstance(
    id: const Uuid().v4(),
    name: prototype.name,
    data: null,
    dataType: prototype.dataType,
    isInput: prototype.isInput,
    allowMultipleLinks: prototype.allowMultipleLinks,
  );
}

FieldInstance createField(FieldPrototype prototype) {
  return FieldInstance(
    id: const Uuid().v4(),
    name: prototype.name,
    isEditable: prototype.isEditable,
    visualizerBuilder: prototype.visualizerBuilder,
    onVisualizerTap: prototype.onVisualizerTap,
    editorBuilder: prototype.editorBuilder,
    data: prototype.defaultData,
    dataType: prototype.dataType,
  );
}

NodeInstance createNode(
  NodePrototype prototype, {
  Offset? offset,
  required Function(NodeInstance node) onRendered,
}) {
  return NodeInstance(
    id: const Uuid().v4(),
    name: prototype.name,
    description: prototype.description,
    color: prototype.color,
    ports: prototype.ports.asMap().map((_, portPrototype) {
      final port = createPort(portPrototype);
      return MapEntry(port.id, port);
    }),
    fields: prototype.fields.asMap().map((_, fieldPrototype) {
      final field = createField(fieldPrototype);
      return MapEntry(field.id, field);
    }),
    onExecute: prototype.onExecute,
    onRendered: onRendered,
    offset: offset ?? Offset.zero,
  );
}
