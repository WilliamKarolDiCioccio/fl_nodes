import 'package:flutter/material.dart';

/// Base class for all types of entries that can appear inside a section.
/// (Items, submenus, etc.)
abstract class FlMenuEntryDataModel {
  const FlMenuEntryDataModel();

  String get idName;
  bool get isEnabled => true;
}

/// Represents a single clickable item in a menu.
@immutable
class FlMenuItemDataModel extends FlMenuEntryDataModel {
  @override
  final String idName;
  @override
  final bool isEnabled;

  final String label;
  final IconData? icon;
  final Function(String)? onPressed;

  const FlMenuItemDataModel({
    required this.idName,
    required this.label,
    this.icon,
    this.onPressed,
    this.isEnabled = true,
  });
}

/// Represents a submenu containing other entries.
@immutable
class FlSubmenuDataModel extends FlMenuEntryDataModel {
  @override
  final String idName;
  @override
  final bool isEnabled;

  final String? label;
  final IconData? icon;
  final List<FlMenuEntryDataModel> items;

  const FlSubmenuDataModel({
    required this.idName,
    required this.items,
    this.label,
    this.icon,
    this.isEnabled = true,
  });
}

/// Represents a search bar entry in the menu.
class FlSearchBarDataModel extends FlMenuEntryDataModel {
  @override
  final String idName;
  @override
  final bool isEnabled = false;

  String? query;
  String? initialQuery;

  FlSearchBarDataModel({this.idName = 'fl_search_bar'});
}

/// A section groups multiple menu entries and can optionally have
/// its own padding, heading, or visual separation.
@immutable
class FlMenuSectionDataModel {
  final String? label;
  final List<FlMenuEntryDataModel> items;
  final EdgeInsetsGeometry? padding;

  const FlMenuSectionDataModel({required this.items, this.label, this.padding});
}

/// The root data model for a context menu.
class FlMenuDataModel {
  final List<FlMenuSectionDataModel> sections;

  const FlMenuDataModel({required this.sections});

  /// Returns all flattened entries
  Iterable<FlMenuEntryDataModel> get allEntries sync* {
    for (final section in sections) {
      for (final entry in section.items) {
        yield entry;
        if (entry is FlSubmenuDataModel) {
          yield* entry.items;
        }
      }
    }
  }
}
