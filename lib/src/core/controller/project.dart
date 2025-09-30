import 'dart:convert';

import 'package:fl_nodes/src/core/controller/callback.dart';
import 'package:fl_nodes/src/core/controller/core.dart';
import 'package:fl_nodes/src/core/events/events.dart';
import 'package:fl_nodes/src/core/localization/delegate.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/data.dart';

typedef ProjectSaver = Future<bool> Function(Map<String, dynamic> jsonData);
typedef ProjectLoader = Future<Map<String, dynamic>?> Function(bool isSaved);
typedef ProjectCreator = Future<bool> Function(bool isSaved);

class DataHandler {
  final String Function(dynamic data) toJson;
  final dynamic Function(String json) fromJson;

  DataHandler(this.toJson, this.fromJson);
}

/// A class that manages the project data of the node editor.
///
/// The package does not provide a default implementation for saving and loading project data,
/// instead it simpliy converts the project data to JSON and vice versa. JSON was chosen as it
/// was quick and easy to implement and can be easily manipulated and converted to other formats
/// (e.g. structured data in a database).
class FlNodeEditorProjectHelper {
  final FlNodeEditorController controller;

  bool _isSaved = true;
  bool get isSaved => _isSaved;

  Offset get viewportOffset => controller.viewportOffset;
  double get viewportZoom => controller.viewportZoom;

  final Future<bool> Function(Map<String, dynamic> jsonData)? projectSaver;
  final Future<Map<String, dynamic>?> Function(bool isSaved)? projectLoader;
  final Future<bool> Function(bool isSaved)? projectCreator;

  // Unlike with nodes, there is no reason not to share them between node editor instances.
  static final Map<String, DataHandler> _dataHandlers = {
    'bool': DataHandler(
      (data) => data.toString(),
      (json) => json.toLowerCase() == 'true',
    ),
    'int': DataHandler(
      (data) => data.toString(),
      (json) => int.parse(json),
    ),
    'double': DataHandler(
      (data) => data.toString(),
      (json) => double.parse(json),
    ),
    'String': DataHandler(
      (data) => data,
      (json) => json,
    ),
    'List': DataHandler(
      (data) => jsonEncode(data),
      (json) => jsonDecode(json) as List<dynamic>,
    ),
    'Map': DataHandler(
      (data) => jsonEncode(data),
      (json) => jsonDecode(json) as Map<String, dynamic>,
    ),
  };

  Map<String, DataHandler> get dataHandlers => _dataHandlers;

  /// The [projectSaver] callback is used to save the project data, should return a boolean.
  /// The [projectLoader] callback is used to load the project data, should return a JSON object.
  /// The [projectCreator] callback is used to create a new project, should return a boolean.
  FlNodeEditorProjectHelper(
    this.controller, {
    required this.projectSaver,
    required this.projectLoader,
    required this.projectCreator,
  }) {
    controller.eventBus.events.listen(_handleProjectEvents);
  }

  /// Registers a custom data handler for a specific type.
  void registerDataHandler<T>({
    required String Function(dynamic data) toJson,
    required T Function(String json) fromJson,
  }) {
    _registerDataHandler<T>(toJson: toJson, fromJson: fromJson);
  }

  static void _registerDataHandler<T>({
    required String Function(dynamic data) toJson,
    required T Function(String json) fromJson,
  }) {
    _dataHandlers[T.toString()] = DataHandler(
      (data) => toJson(data),
      (json) => fromJson(json),
    );
  }

  /// Unregisters a custom data handler for a specific type.
  void unregisterDataHandler<T>() {
    _unregisterDataHandler<T>();
  }

  static void _unregisterDataHandler<T>() {
    _dataHandlers.remove(T.toString());
  }

  /// Clears the history and sets the project as saved.
  void clear() {
    controller.history.clear();
    controller.runner.dispose();

    _isSaved = true;
  }

  /// Handles project related events.
  ///
  /// - [FlSaveProjectEvent]: Sets the project as saved.
  /// - [FlLoadProjectEvent]: Sets the project as saved and clears the history.
  /// - [FlNewProjectEvent]: Clears the project.
  ///
  /// If the event is undoable, the project is set as unsaved.
  void _handleProjectEvents(NodeEditorEvent event) {
    if (event.isUndoable) _isSaved = false;

    if (event is FlSaveProjectEvent) {
      _isSaved = true;
    } else if (event is FlLoadProjectEvent) {
      _isSaved = true;
      controller.history.clear();
    } else if (event is FlNewProjectEvent) {
      _isSaved = true;
      controller.clear();
    }
  }

  /// Private method to convert the project data to JSON.
  ///
  /// Even doe counterintuitive, this method is the one actually responsible for saving the project data other than serializing the project data.
  /// This choice was made to avoid redundancy and to keep the project data saving logic in one place.
  Map<String, dynamic> _toJson() {
    final nodesJson = controller.nodes.values
        .map((node) => node.toJson(dataHandlers))
        .toList();

    return {
      'viewport': {
        'offset': [viewportOffset.dx, viewportOffset.dy],
        'zoom': viewportZoom,
      },
      'nodes': nodesJson,
    };
  }

  /// Private method to convert the JSON data to project data.
  ///
  /// Even doe counterintuitive, this method is the one actually responsible for loading the project data other than deserializing the JSON data.
  /// This choice was made to avoid redundancy and to keep the project data loading logic in one place.
  (Offset, double, Set<FlNodeDataModel>)? _fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return null;

    final viewportJson = json['viewport'] as Map<String, dynamic>;

    controller.setViewportOffset(
      Offset(
        viewportJson['offset'][0] as double,
        viewportJson['offset'][1] as double,
      ),
      absolute: true,
    );

    controller.setViewportZoom(
      viewportJson['zoom'] as double,
      absolute: true,
    );

    final nodesJson = json['nodes'] as List<dynamic>;

    final nodes = nodesJson.map((node) {
      return FlNodeDataModel.fromJson(
        node,
        nodePrototypes: controller.nodePrototypes,
        dataHandlers: dataHandlers,
      );
    }).toSet();

    for (final node in nodes) {
      controller.addNodeFromExisting(node, isHandled: true);
    }

    return (viewportOffset, viewportZoom, nodes);
  }

  /// This method wraps [_toJson] and adds additional
  ///
  /// The behavior of this method is determined by the [projectSaver] callback and user defined logic.
  ///
  /// e.g. Save to a file, save to a database, etc.
  void save({BuildContext? context}) async {
    final strings = FlNodeEditorLocalizations.of(context);

    late final Map<String, dynamic> jsonData;

    try {
      jsonData = _toJson();
    } catch (e) {
      controller.onCallback?.call(
        FlCallbackType.error,
        strings.failedToSaveProjectErrorMsg(e.toString()),
      );
      return;
    }

    if (jsonData.isEmpty) return;

    final hasSaved = await projectSaver?.call(jsonData);
    if (hasSaved == false) return;

    _isSaved = true;

    controller.eventBus.emit(FlSaveProjectEvent(id: const Uuid().v4()));

    controller.onCallback?.call(
      FlCallbackType.success,
      strings.projectSavedSuccessfullyMsg,
    );
  }

  /// This method wraps [_fromJson] and adds additional
  ///
  /// The behavior of this method is determined by the [projectLoader] callback and user defined logic.
  ///
  /// e.g. If the project data is invalid, the user will be prompted to save the project.
  void load({Map<String, dynamic>? data, BuildContext? context}) async {
    final strings = FlNodeEditorLocalizations.of(context);

    late final Map<String, dynamic>? jsonData;

    if (data != null) {
      jsonData = data;
    } else {
      jsonData = await projectLoader?.call(isSaved);
    }

    if (jsonData == null) {
      controller.onCallback?.call(
        FlCallbackType.error,
        strings.failedToLoadProjectErrorMsg('jsonData == null'),
      );
      return;
    }

    controller.clear();

    try {
      _fromJson(jsonData);
    } catch (e) {
      controller.onCallback?.call(
        FlCallbackType.error,
        strings.failedToLoadProjectErrorMsg(e.toString()),
      );
      return;
    }

    controller.eventBus.emit(FlLoadProjectEvent(id: const Uuid().v4()));

    controller.onCallback?.call(
      FlCallbackType.success,
      strings.projectLoadedSuccessfullyMsg,
    );
  }

  /// Creates a new project by clearing the current one.
  ///
  /// The behavior of this method is determined by the [projectCreator] callback and user defined logic.
  ///
  /// e.g. If the project is not saved, the user will be prompted to save the project.
  void create({BuildContext? context}) async {
    final strings = FlNodeEditorLocalizations.of(context);

    final shouldProceed = await projectCreator?.call(isSaved);

    if (shouldProceed == false) return;

    controller.eventBus.emit(FlNewProjectEvent(id: const Uuid().v4()));

    controller.onCallback?.call(
      FlCallbackType.success,
      strings.newProjectCreatedSuccessfullyMsg,
    );
  }
}
