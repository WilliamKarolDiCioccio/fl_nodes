import 'package:flutter/material.dart';

import 'package:fl_nodes_core/src/core/models/data.dart';

extension FlLinkDataModelLegacyAdapter on FlLinkDataModel {
  Map<String, dynamic> toJsonLegacy(Map<Type, DataHandler> dataHandlers) => {
        'id': id,
        'from': ports.$1.nodeId,
        'to': ports.$2.nodeId,
        'fromPort': ports.$1.portId,
        'toPort': ports.$2.portId,
      };

  static FlLinkDataModel fromJsonLegacy(
    Map<String, dynamic> json,
    Map<Type, DataHandler> dataHandlers,
  ) =>
      FlLinkDataModel(
        id: json['id'] as String,
        // What you see here is a mistake in the legacy format that we have to keep for compatibility
        ports: (
          (
            nodeId: json['from'] as String,
            portId: json['to'] as String,
          ),
          (
            nodeId: json['fromPort'] as String,
            portId: json['toPort'] as String,
          ),
        ),
        state: FlLinkState(),
      );
}

extension FlPortDataModelLegacyAdapter on FlPortDataModel {
  Map<String, dynamic> toJsonLegacy(Map<Type, DataHandler> dataHandlers) => {
        'idName': prototype.idName,
        'links': links.map((link) => link.toJsonLegacy(dataHandlers)).toList(),
      };

  static FlPortDataModel fromJsonLegacy(
    Map<String, dynamic> json,
    Map<Type, DataHandler> dataHandlers,
    Map<String, FlPortPrototype> portPrototypes,
  ) {
    if (!portPrototypes.containsKey(json['idName'].toString())) {
      throw Exception('Port prototype not found');
    }

    final FlPortPrototype prototype = portPrototypes[json['idName'].toString()]!;

    final instance = FlPortDataModel(
      prototype: prototype,
      state: FlPortState(),
    );

    instance.links = (json['links'] as List<dynamic>)
        .map(
          (linkJson) => FlLinkDataModelLegacyAdapter.fromJsonLegacy(
            linkJson as Map<String, dynamic>,
            dataHandlers,
          ),
        )
        .toSet();

    return instance;
  }
}

extension FlFieldDataModelLegacyAdapter on FlFieldDataModel {
  Map<String, dynamic> toJsonLegacy(Map<Type, DataHandler> dataHandlers) => {
        'idName': prototype.idName,
        'data': dataHandlers[prototype.dataType]?.toJson(data),
      };

  static FlFieldDataModel fromJsonLegacy(
    Map<String, dynamic> json,
    Map<String, FlFieldPrototype> fieldPrototypes,
    Map<Type, DataHandler> dataHandlers,
  ) {
    if (!fieldPrototypes.containsKey(json['idName'].toString())) {
      throw Exception('Field prototype not found');
    }

    final FlFieldPrototype prototype = fieldPrototypes[json['idName'].toString()]!;

    return FlFieldDataModel(
      prototype: prototype,
      data: json['data'] != 'null'
          ? dataHandlers[prototype.dataType]?.fromJson(json['data'] as String)
          : null,
    );
  }
}

extension FlNodeStateLegacyAdapter on FlNodeState {
  Map<String, dynamic> toJsonLegacy() => {
        'isSelected': isSelected,
        'isCollapsed': isCollapsed,
      };

  static FlNodeState fromJsonLegacy(Map<String, dynamic> json) => FlNodeState(
        isSelected: json['isSelected'] as bool,
        isCollapsed: json['isCollapsed'] as bool,
      );
}

extension FlNodeDataModelLegacyAdapter on FlNodeDataModel {
  Map<String, dynamic> toJsonLegacy(Map<Type, DataHandler> dataHandlers) => {
        'id': id,
        'idName': prototype.idName,
        'ports': ports.map((k, v) => MapEntry(k, v.toJsonLegacy(dataHandlers))),
        'fields': fields.map((k, v) => MapEntry(k, v.toJsonLegacy(dataHandlers))),
        'state': state.toJsonLegacy(),
        'offset': [offset.dx, offset.dy],
        'customData': customData.map((k, v) {
          final DataHandler? handler = dataHandlers[v.runtimeType];
          return MapEntry(k, handler?.toJson(v) ?? v);
        }),
      };

  static FlNodeDataModel fromJsonLegacy(
    Map<String, dynamic> json, {
    required Map<String, FlNodePrototype> nodePrototypes,
    required Map<Type, DataHandler> dataHandlers,
  }) {
    if (!nodePrototypes.containsKey(json['idName'].toString())) {
      throw Exception('Node prototype not found');
    }

    final FlNodePrototype prototype = nodePrototypes[json['idName'].toString()]!;

    final Map<String, FlPortPrototype> portPrototypes = Map.fromEntries(
      prototype.portPrototypes.map(
        (prototype) => MapEntry(prototype.idName, prototype),
      ),
    );

    final Map<String, FlPortDataModel> ports = (json['ports'] as Map<String, dynamic>).map(
      (id, portJson) => MapEntry(
        id,
        FlPortDataModelLegacyAdapter.fromJsonLegacy(
          portJson as Map<String, dynamic>,
          dataHandlers,
          portPrototypes,
        ),
      ),
    );

    final Map<String, FlFieldPrototype> fieldPrototypes = Map.fromEntries(
      prototype.fieldPrototypes.map(
        (prototype) => MapEntry(prototype.idName, prototype),
      ),
    );

    final Map<String, FlFieldDataModel> fields = (json['fields'] as Map<String, dynamic>).map(
      (id, fieldJson) => MapEntry(
        id,
        FlFieldDataModelLegacyAdapter.fromJsonLegacy(
          fieldJson as Map<String, dynamic>,
          fieldPrototypes,
          dataHandlers,
        ),
      ),
    );

    final instance = FlNodeDataModel(
      id: json['id'] as String,
      prototype: prototype,
      ports: ports,
      fields: fields,
      customData: {},
      state: FlNodeState(
        isCollapsed: (json['state'] as Map<String, dynamic>)['isCollapsed'] as bool,
      ),
      offset: Offset(
        ((json['offset'] as List<dynamic>)[0] as num).toDouble(),
        ((json['offset'] as List<dynamic>)[1] as num).toDouble(),
      ),
    );

    return instance;
  }
}

extension FlNodesProjectDataModelLegacyAdapter on FlNodesProjectDataModel {
  Map<String, dynamic> toJsonLegacy(Map<Type, DataHandler> dataHandlers) {
    final List<Map<String, dynamic>> nodesJson =
        nodes.values.map((node) => node.toJsonLegacy(dataHandlers)).toList();

    return {
      'viewport': {
        'offset': [viewportOffset.dx, viewportOffset.dy],
        'zoom': viewportZoom,
      },
      'nodes': nodesJson,
    };
  }

  static FlNodesProjectDataModel fromJsonLegacy(
    Map<String, dynamic> json,
    Map<String, FlNodePrototype> nodePrototypes,
    Map<Type, DataHandler> dataHandlers,
  ) {
    final nodesJson = json['nodes'] as List<dynamic>;
    final nodes = <String, FlNodeDataModel>{};
    final links = <String, FlLinkDataModel>{};

    for (final nodeJson in nodesJson) {
      final FlNodeDataModel node = FlNodeDataModelLegacyAdapter.fromJsonLegacy(
        nodeJson as Map<String, dynamic>,
        nodePrototypes: nodePrototypes,
        dataHandlers: dataHandlers,
      );

      for (final FlPortDataModel port in node.ports.values) {
        for (final FlLinkDataModel link in port.links) {
          links[link.id] = link;
        }
      }

      nodes[node.id] = node;
    }

    return FlNodesProjectDataModel(
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
