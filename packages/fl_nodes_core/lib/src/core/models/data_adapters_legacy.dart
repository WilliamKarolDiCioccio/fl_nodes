import 'package:flutter/material.dart';

import 'data.dart';

extension FlLinkDataModelLegacyAdapter on FlLinkDataModel {
  Map<String, dynamic> toJsonLegacy() {
    return {
      'id': id,
      'from': ports.from.nodeId,
      'to': ports.to.nodeId,
      'fromPort': ports.from.portId,
      'toPort': ports.to.portId,
    };
  }

  static FlLinkDataModel fromJsonLegacy(Map<String, dynamic> json) {
    return FlLinkDataModel(
      id: json['id'],
      // What you see here is a mistake in the legacy format that we have to keep for compatibility
      ports: (
        from: (
          nodeId: json['from'],
          portId: json['to'],
        ),
        to: (
          nodeId: json['fromPort'],
          portId: json['toPort'],
        ),
      ),
      state: FlLinkState(),
    );
  }
}

extension FlPortDataModelLegacyAdapter on FlPortDataModel {
  Map<String, dynamic> toJsonLegacy() {
    return {
      'idName': prototype.idName,
      'links': links.map((link) => link.toJsonLegacy()).toList(),
    };
  }

  static FlPortDataModel fromJsonLegacy(
    Map<String, dynamic> json,
    Map<String, FlPortPrototype> portPrototypes,
  ) {
    if (!portPrototypes.containsKey(json['idName'].toString())) {
      throw Exception('Port prototype not found');
    }

    final prototype = portPrototypes[json['idName'].toString()]!;

    final instance = FlPortDataModel(
      prototype: prototype,
      state: FlPortState(),
    );

    instance.links = (json['links'] as List<dynamic>)
        .map(
            (linkJson) => FlLinkDataModelLegacyAdapter.fromJsonLegacy(linkJson))
        .toSet();

    return instance;
  }
}

extension FlFieldDataModelLegacyAdapter on FlFieldDataModel {
  Map<String, dynamic> toJsonLegacy(Map<Type, DataHandler> dataHandlers) {
    return {
      'idName': prototype.idName,
      'data': dataHandlers[prototype.dataType]?.toJson(data),
    };
  }

  static FlFieldDataModel fromJsonLegacy(
    Map<String, dynamic> json,
    Map<String, FlFieldPrototype> fieldPrototypes,
    Map<Type, DataHandler> dataHandlers,
  ) {
    if (!fieldPrototypes.containsKey(json['idName'].toString())) {
      throw Exception('Field prototype not found');
    }

    final prototype = fieldPrototypes[json['idName'].toString()]!;

    return FlFieldDataModel(
      prototype: prototype,
      data: json['data'] != 'null'
          ? dataHandlers[prototype.dataType]?.fromJson(json['data'])
          : null,
    );
  }
}

extension FlNodeStateLegacyAdapter on FlNodeState {
  Map<String, dynamic> toJsonLegacy() {
    return {
      'isSelected': isSelected,
      'isCollapsed': isCollapsed,
    };
  }

  static FlNodeState fromJsonLegacy(Map<String, dynamic> json) {
    return FlNodeState(
      isSelected: json['isSelected'],
      isCollapsed: json['isCollapsed'],
    );
  }
}

extension FlNodeDataModelLegacyAdapter on FlNodeDataModel {
  Map<String, dynamic> toJsonLegacy(Map<Type, DataHandler> dataHandlers) {
    return {
      'id': id,
      'idName': prototype.idName,
      'ports': ports.map((k, v) => MapEntry(k, v.toJsonLegacy())),
      'fields': fields.map((k, v) => MapEntry(k, v.toJsonLegacy(dataHandlers))),
      'state': state.toJsonLegacy(),
      'offset': [offset.dx, offset.dy],
      'customData': customData.map((k, v) {
        final handler = dataHandlers[v.runtimeType];
        return MapEntry(k, handler?.toJson(v) ?? v);
      }),
    };
  }

  static FlNodeDataModel fromJsonLegacy(
    Map<String, dynamic> json, {
    required Map<String, FlNodePrototype> nodePrototypes,
    required Map<Type, DataHandler> dataHandlers,
  }) {
    if (!nodePrototypes.containsKey(json['idName'].toString())) {
      throw Exception('Node prototype not found');
    }

    final prototype = nodePrototypes[json['idName'].toString()]!;

    final portPrototypes = Map.fromEntries(
      prototype.ports.map(
        (prototype) => MapEntry(prototype.idName, prototype),
      ),
    );

    final ports = (json['ports'] as Map<String, dynamic>).map(
      (id, portJson) {
        return MapEntry(
          id,
          FlPortDataModelLegacyAdapter.fromJsonLegacy(portJson, portPrototypes),
        );
      },
    );

    final fieldPrototypes = Map.fromEntries(
      prototype.fields.map(
        (prototype) => MapEntry(prototype.idName, prototype),
      ),
    );

    final fields = (json['fields'] as Map<String, dynamic>).map(
      (id, fieldJson) {
        return MapEntry(
          id,
          FlFieldDataModelLegacyAdapter.fromJsonLegacy(
            fieldJson,
            fieldPrototypes,
            dataHandlers,
          ),
        );
      },
    );

    final instance = FlNodeDataModel(
      id: json['id'],
      prototype: prototype,
      ports: ports,
      fields: fields,
      customData: {},
      state: FlNodeState(isCollapsed: json['state']['isCollapsed']),
      offset: Offset(json['offset'][0], json['offset'][1]),
    );

    return instance;
  }
}

extension FlNodeEditorProjectDataModelLegacyAdapter
    on FlNodeEditorProjectDataModel {
  Map<String, dynamic> toJsonLegacy(Map<Type, DataHandler> dataHandlers) {
    final nodesJson =
        nodes.values.map((node) => node.toJsonLegacy(dataHandlers)).toList();

    return {
      'viewport': {
        'offset': [viewportOffset.dx, viewportOffset.dy],
        'zoom': viewportZoom,
      },
      'nodes': nodesJson,
    };
  }

  static FlNodeEditorProjectDataModel fromJsonLegacy(
    Map<String, dynamic> json,
    Map<String, FlNodePrototype> nodePrototypes,
    Map<Type, DataHandler> dataHandlers,
  ) {
    final nodesJson = json['nodes'] as List<dynamic>;
    final nodes = <String, FlNodeDataModel>{};
    final links = <String, FlLinkDataModel>{};

    for (final nodeJson in nodesJson) {
      final node = FlNodeDataModelLegacyAdapter.fromJsonLegacy(
        nodeJson,
        nodePrototypes: nodePrototypes,
        dataHandlers: dataHandlers,
      );

      for (final port in node.ports.values) {
        for (final link in port.links) {
          links[link.id] = link;
        }
      }

      nodes[node.id] = node;
    }

    return FlNodeEditorProjectDataModel(
      nodes: nodes,
      links: links,
      viewportOffset: Offset(
        (json['viewport']['offset'][0] as num).toDouble(),
        (json['viewport']['offset'][1] as num).toDouble(),
      ),
      viewportZoom: (json['viewport']['zoom'] as num).toDouble(),
    );
  }
}
