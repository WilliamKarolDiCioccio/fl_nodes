import 'package:flutter/material.dart';

import 'package:fl_nodes/src/core/models/data.dart';
import 'package:fl_nodes/src/core/models/data_adapters_legacy.dart';

extension FlLinkDataModelV1Adapter on FlLinkDataModel {
  Map<String, dynamic> toJsonV1() => toJsonLegacy();

  static FlLinkDataModel fromJsonV1(Map<String, dynamic> json) =>
      FlLinkDataModelLegacyAdapter.fromJsonLegacy(json);
}

extension FlPortDataModelV1Adapter on FlPortDataModel {
  Map<String, dynamic> toJsonV1() => toJsonLegacy();

  static FlPortDataModel fromJsonV1(
    Map<String, dynamic> json,
    Map<String, FlPortPrototype> portPrototypes,
  ) =>
      FlPortDataModelLegacyAdapter.fromJsonLegacy(json, portPrototypes);
}

extension FlFieldDataModelV1Adapter on FlFieldDataModel {
  Map<String, dynamic> toJsonV1(Map<Type, DataHandler> dataHandlers) =>
      toJsonLegacy(dataHandlers);

  static FlFieldDataModel fromJsonV1(
    Map<String, dynamic> json,
    Map<String, FlFieldPrototype> fieldPrototypes,
    Map<Type, DataHandler> dataHandlers,
  ) =>
      FlFieldDataModelLegacyAdapter.fromJsonLegacy(
        json,
        fieldPrototypes,
        dataHandlers,
      );
}

extension FlNodeStateV1Adapter on FlNodeState {
  Map<String, dynamic> toJsonV1() => toJsonLegacy();

  static FlNodeState fromJsonV1(Map<String, dynamic> json) =>
      FlNodeStateLegacyAdapter.fromJsonLegacy(json);
}

extension FlNodeDataModelV1Adapter on FlNodeDataModel {
  Map<String, dynamic> toJsonV1(Map<Type, DataHandler> dataHandlers) {
    return {
      'id': id,
      'idName': prototype.idName,
      'ports': ports.map((k, v) => MapEntry(k, v.toJson())),
      'fields': fields.map((k, v) => MapEntry(k, v.toJson(dataHandlers))),
      'state': state.toJson(),
      'offset': [offset.dx, offset.dy],
      'customData': customData.map((k, v) {
        final handler = dataHandlers[v.runtimeType];
        return MapEntry(k, handler?.toJson(v) ?? v);
      }),
    };
  }

  static FlNodeDataModel fromJsonV1(
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
          FlPortDataModelV1Adapter.fromJsonV1(portJson, portPrototypes),
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
          FlFieldDataModelV1Adapter.fromJsonV1(
            fieldJson,
            fieldPrototypes,
            dataHandlers,
          ),
        );
      },
    );

    final customData = (json['customData'] as Map<String, dynamic>).map((k, v) {
      final type = prototype.customData
          .firstWhere(
            (element) => element.$1 == k,
            orElse: () => ('', dynamic, null),
          )
          .$2;

      if (type == dynamic) return MapEntry(k, v);

      final handler = dataHandlers[type];
      return MapEntry(k, handler?.fromJson(v) ?? v);
    });

    final instance = FlNodeDataModel(
      id: json['id'],
      prototype: prototype,
      ports: ports,
      fields: fields,
      customData: customData,
      state: FlNodeState(isCollapsed: json['state']['isCollapsed']),
      offset: Offset(json['offset'][0], json['offset'][1]),
    );

    return instance;
  }
}

extension FlNodesGroupDataModelV1Adapter on FlNodesGroupDataModel {
  Map<String, dynamic> toJsonV1() => {
        'id': id,
        'name': name,
        'nodeIds': nodeIds.toList(),
      };

  static FlNodesGroupDataModel fromJsonV1(Map<String, dynamic> json) =>
      FlNodesGroupDataModel(
        id: json['id'],
        name: json['name'],
        nodeIds:
            (json['nodeIds'] as List<dynamic>).map((e) => e.toString()).toSet(),
      );
}

extension FlNodeEditorProjectDataModelV1Adapter
    on FlNodeEditorProjectDataModel {
  Map<String, dynamic> toJsonV1(Map<Type, DataHandler> dataHandlers) {
    final nodesJson =
        nodes.values.map((node) => node.toJson(dataHandlers)).toList();

    return {
      'version': 1,
      'packageVersion': packageVersion,
      'appVersion': appVersion,
      'viewport': {
        'offset': [viewportOffset.dx, viewportOffset.dy],
        'zoom': viewportZoom,
      },
      'nodes': nodesJson,
    };
  }

  static FlNodeEditorProjectDataModel fromJsonV1(
    Map<String, dynamic> json,
    Map<String, FlNodePrototype> nodePrototypes,
    Map<Type, DataHandler> dataHandlers,
  ) {
    int? version;
    if (json['version'] != null) {
      version = int.parse(json['version'].toString());
    }

    if (version == null) {
      return FlNodeEditorProjectDataModelLegacyAdapter.fromJsonLegacy(
        json,
        nodePrototypes,
        dataHandlers,
      );
    }

    late String packageSemVerStr;
    if (json['packageVersion'] != null) {
      packageSemVerStr = json['packageVersion'] as String;
    }

    late String appSemVerStr;
    if (json['appVersion'] != null) {
      appSemVerStr = json['appVersion'] as String;
    }

    final nodesJson = json['nodes'] as List<dynamic>;
    final nodes = <String, FlNodeDataModel>{};
    final links = <String, FlLinkDataModel>{};

    for (final nodeJson in nodesJson) {
      final node = FlNodeDataModelV1Adapter.fromJsonV1(
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
      packageVersion: packageSemVerStr,
      appVersion: appSemVerStr,
      nodes: nodes,
      links: links,
      viewportOffset: Offset(
        (json['viewport']['offset'][0] as num).toDouble(),
        (json['viewport']['offset'][1] as num).toDouble(),
      ),
      viewportZoom: (json['viewport']['zoom'] as num).toDouble(),
    );
  }

  FlNodeEditorProjectDataModel copyWith() {
    return FlNodeEditorProjectDataModel(
      packageVersion: packageVersion,
      appVersion: appVersion,
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
