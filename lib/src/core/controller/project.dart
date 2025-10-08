import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

import 'package:fl_nodes/src/core/controller/callback.dart';
import 'package:fl_nodes/src/core/controller/core.dart';
import 'package:fl_nodes/src/core/events/events.dart';
import 'package:fl_nodes/src/core/localization/delegate.dart';

import '../models/data.dart';

typedef ProjectSaver = Future<bool> Function(Map<String, dynamic> jsonData);
typedef ProjectLoader = Future<Map<String, dynamic>?> Function(bool isSaved);
typedef ProjectCreator = Future<bool> Function(bool isSaved);

/// A helper class that handles the conversion of data to and from JSON.
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

  FlNodeEditorProjectDataModel projectData = FlNodeEditorProjectDataModel(
    nodes: {},
    links: {},
  );

  bool isSaved = true;
  DateTime? lastSaveTime;

  Timer? _autoSaveTimer;
  Timer? _saveDebounceTimer;

  Offset get viewportOffset => controller.viewportOffset;
  double get viewportZoom => controller.viewportZoom;

  final Future<bool> Function(Map<String, dynamic> jsonData)? projectSaver;
  final Future<Map<String, dynamic>?> Function(bool isSaved)? projectLoader;
  final Future<bool> Function(bool isSaved)? projectCreator;

  // Unlike with nodes, there is no reason not to share them between node editor instances.
  static final Map<Type, DataHandler> _dataHandlers = {
    bool: DataHandler(
      (data) => data.toString(),
      (json) => json.toLowerCase() == 'true',
    ),
    int: DataHandler(
      (data) => data.toString(),
      (json) => int.parse(json),
    ),
    double: DataHandler(
      (data) => data.toString(),
      (json) => double.parse(json),
    ),
    String: DataHandler(
      (data) => data,
      (json) => json,
    ),
    List: DataHandler(
      (data) => jsonEncode(data),
      (json) => jsonDecode(json) as List<dynamic>,
    ),
    Map: DataHandler(
      (data) => jsonEncode(data),
      (json) => jsonDecode(json) as Map<String, dynamic>,
    ),
  };

  Map<Type, DataHandler> get dataHandlers => _dataHandlers;

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

  /// Handles events from the controller and manages the project state accordingly.
  void _handleProjectEvents(NodeEditorEvent event) {
    if (event is FlAddNodeEvent ||
        event is FlRemoveNodeEvent ||
        event is FlAddLinkEvent ||
        event is FlRemoveLinkEvent ||
        event is FlDragSelectionEndEvent ||
        (event is FlNodeFieldEvent &&
            event.eventType == FlFieldEventType.submit)) {
      isSaved = false;

      if ((_autoSaveTimer == null || !_autoSaveTimer!.isActive) &&
          controller.config.autoSave) {
        _autoSaveTimer =
            Timer.periodic(controller.config.autoSaveInterval, (timer) {
          if (!isSaved) save();
        });
      }
    }
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
    _dataHandlers[T] = DataHandler(
      (data) => toJson(data),
      (json) => fromJson(json),
    );
  }

  /// Unregisters a custom data handler for a specific type.
  void unregisterDataHandler<T>() {
    _unregisterDataHandler<T>();
  }

  static void _unregisterDataHandler<T>() {
    _dataHandlers.remove(T);
  }

  /// Clears the history and sets the project as saved.
  void clear() {
    controller.clear();
    controller.history.clear();
    controller.runner.clear();

    isSaved = true;
  }

  /// This method wraps [_toJson] and adds additional
  ///
  /// The behavior of this method is determined by the [projectSaver] callback and user defined logic.
  ///
  /// e.g. Save to a file, save to a database, etc.
  void save({BuildContext? context}) async {
    if (_saveDebounceTimer != null && _saveDebounceTimer!.isActive) return;

    _saveDebounceTimer = Timer(controller.config.manualSaveDebounce, () {});

    final strings = FlNodeEditorLocalizations.of(context);

    late final Map<String, dynamic> jsonData;

    try {
      jsonData = projectData.toJson(dataHandlers);
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

    isSaved = true;
    lastSaveTime = DateTime.now();

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

    clear();

    try {
      projectData = FlNodeEditorProjectDataModel.fromJson(
        jsonData,
        controller.nodePrototypes,
        dataHandlers,
      );
    } catch (e) {
      controller.onCallback?.call(
        FlCallbackType.error,
        strings.failedToLoadProjectErrorMsg(e.toString()),
      );
      return;
    }

    // Normally this would be handled by the node editor itself, but since we're loading
    // a project, we need to manually set the offsets of unbound nodes otherwise we would,
    // once again, add the nodes to the project data, which would be incorrect.
    for (final node in projectData.nodes.values) {
      controller.unboundNodeOffsets[node.id] = node.offset;
    }

    // These too require manual setting as they are not strictly part of the project data.
    // Their value at the moment of saving the project is what matters. They also trigger
    // animations when set via the controller, which is a nice touch.
    controller.setViewportOffset(projectData.viewportOffset, absolute: true);
    controller.setViewportZoom(projectData.viewportZoom, absolute: true);

    isSaved = true;

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

    clear();

    projectData = FlNodeEditorProjectDataModel(
      nodes: {},
      links: {},
    );

    isSaved = false;

    controller.eventBus.emit(FlNewProjectEvent(id: const Uuid().v4()));

    controller.onCallback?.call(
      FlCallbackType.success,
      strings.newProjectCreatedSuccessfullyMsg,
    );
  }
}
