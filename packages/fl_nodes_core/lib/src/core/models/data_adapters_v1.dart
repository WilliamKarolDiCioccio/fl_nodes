import 'package:flutter/material.dart';

import 'package:fl_nodes_core/src/core/models/data.dart';
import 'package:fl_nodes_core/src/core/models/data_adapters_legacy.dart';

extension FlLinkDataModelV1Adapter<T> on FlLinkDataModel {
  Map<String, dynamic> toJsonV1() => {
        'id': id,
        'from': {
          'nodeId': ports.$1.nodeId,
          'portId': ports.$1.portId,
        },
        'to': {
          'nodeId': ports.$2.nodeId,
          'portId': ports.$2.portId,
        },
        'labelData': null,
      };

  static FlLinkDataModel fromJsonV1(
    Map<String, dynamic> json,
    Map<Type, DataHandler> dataHandlers,
  ) {
    final from = json['from'] as Map<String, dynamic>;
    final to = json['to'] as Map<String, dynamic>;
    return FlLinkDataModel(
      id: json['id'] as String,
      ports: (
        (
          nodeId: from['nodeId'] as String,
          portId: from['portId'] as String,
        ),
        (
          nodeId: to['nodeId'] as String,
          portId: to['portId'] as String,
        ),
      ),
      state: FlLinkState(),
    );
  }
}

extension FlPortDataModelV1Adapter on FlPortDataModel {
  Map<String, dynamic> toJsonV1() => {
        'idName': prototype.idName,
        'links': links.map((link) => link.toJsonV1()).toList(),
      };

  static FlPortDataModel fromJsonV1(
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
          (linkJson) => FlLinkDataModelV1Adapter.fromJsonV1(
            linkJson as Map<String, dynamic>,
            dataHandlers,
          ),
        )
        .toSet();

    return instance;
  }
}

extension FlFieldDataModelV1Adapter on FlFieldDataModel {
  Map<String, dynamic> toJsonV1(Map<Type, DataHandler> dataHandlers) => toJsonLegacy(dataHandlers);

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
  Map<String, dynamic> toJsonV1(Map<Type, DataHandler> dataHandlers) => {
        'id': id,
        'idName': prototype.idName,
        'ports': ports.map((k, v) => MapEntry(k, v.toJsonV1())),
        'fields': fields.map((k, v) => MapEntry(k, v.toJsonV1(dataHandlers))),
        'state': state.toJsonV1(),
        'offset': [offset.dx, offset.dy],
        'customData': customData.map((k, v) {
          final DataHandler? handler = dataHandlers[v.runtimeType];
          return MapEntry(k, handler?.toJson(v) ?? v);
        }),
      };

  static FlNodeDataModel fromJsonV1(
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
        FlPortDataModelV1Adapter.fromJsonV1(
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
        FlFieldDataModelV1Adapter.fromJsonV1(
          fieldJson as Map<String, dynamic>,
          fieldPrototypes,
          dataHandlers,
        ),
      ),
    );

    final Map<String, dynamic> customData =
        (json['customData'] as Map<String, dynamic>).map((k, v) {
      final Type type = prototype.customData
          .firstWhere(
            (element) => element.$1 == k,
            orElse: () => ('', dynamic, null),
          )
          .$2;

      if (type == dynamic) return MapEntry(k, v);

      final DataHandler? handler = dataHandlers[type];
      return MapEntry(k, handler?.fromJson(v as String) ?? v);
    });

    final instance = FlNodeDataModel(
      id: json['id'] as String,
      prototype: prototype,
      ports: ports,
      fields: fields,
      customData: customData,
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

extension FlNodesGroupDataModelV1Adapter on FlNodesGroupDataModel {
  Map<String, dynamic> toJsonV1() => {
        'id': id,
        'name': name,
        'nodeIds': nodeIds.toList(),
      };

  static FlNodesGroupDataModel fromJsonV1(Map<String, dynamic> json) => FlNodesGroupDataModel(
        id: json['id'] as String,
        name: json['name'] as String,
        nodeIds: (json['nodeIds'] as List<dynamic>).map((e) => e.toString()).toSet(),
      );
}

extension FlNodesProjectDataModelV1Adapter on FlNodesProjectDataModel {
  Map<String, dynamic> toJsonV1(Map<Type, DataHandler> dataHandlers) {
    final List<Map<String, dynamic>> nodesJson =
        nodes.values.map((node) => node.toJsonV1(dataHandlers)).toList();

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

  static FlNodesProjectDataModel fromJsonV1(
    Map<String, dynamic> json,
    Map<String, FlNodePrototype> nodePrototypes,
    Map<Type, DataHandler> dataHandlers,
  ) {
    int? version;
    if (json['version'] != null) {
      version = int.parse(json['version'].toString());
    }

    if (version == null) {
      return FlNodesProjectDataModelLegacyAdapter.fromJsonLegacy(
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
      final FlNodeDataModel node = FlNodeDataModelV1Adapter.fromJsonV1(
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

  FlNodesProjectDataModel copyWith() => FlNodesProjectDataModel(
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
