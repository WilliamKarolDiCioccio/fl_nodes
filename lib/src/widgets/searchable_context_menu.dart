import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/models/entities.dart';
import 'context_menu.dart';

class SearchableNodeMenu extends StatefulWidget {
  final List<MapEntry<String, NodePrototype>> nodePrototypes;
  final Offset position;
  final Function(String nodeKey) onNodeSelected;
  final VoidCallback? onDismiss;

  const SearchableNodeMenu({
    super.key,
    required this.nodePrototypes,
    required this.position,
    required this.onNodeSelected,
    this.onDismiss,
  });

  @override
  State<SearchableNodeMenu> createState() => _SearchableNodeMenuState();
}

class _SearchableNodeMenuState extends State<SearchableNodeMenu> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<MapEntry<String, NodePrototype>> _filteredNodes = [];
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _filteredNodes = List.from(widget.nodePrototypes);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterNodes(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredNodes = List.from(widget.nodePrototypes);
      } else {
        _filteredNodes = widget.nodePrototypes.where((entry) {
          final displayName = entry.value.displayName.toLowerCase();
          final description = entry.value.description.toLowerCase();
          final searchQuery = query.toLowerCase();

          // Search in display name, description, and node key
          return displayName.contains(searchQuery) ||
              description.contains(searchQuery) ||
              entry.key.toLowerCase().contains(searchQuery);
        }).toList();
      }
      _selectedIndex = _filteredNodes.isNotEmpty ? 0 : -1;
    });
  }

  void _selectNode(int index) {
    if (index >= 0 && index < _filteredNodes.length) {
      final selectedEntry = _filteredNodes[index];
      widget.onNodeSelected(selectedEntry.key);
      Navigator.of(context).pop();
    }
  }

  void _handleKeyboard(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1) % _filteredNodes.length;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = _selectedIndex > 0
              ? _selectedIndex - 1
              : _filteredNodes.length - 1;
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (_selectedIndex >= 0) {
          _selectNode(_selectedIndex);
        }
      } else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyboard,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF2D2D2D),
        child: Container(
          width: 280,
          constraints: const BoxConstraints(
            maxHeight: 400,
            minHeight: 200,
          ),
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.add, color: Colors.white70, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Create Node',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 8),

              // Search bar
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Search nodes...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                    prefixIcon:
                        Icon(Icons.search, color: Colors.white38, size: 16),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  onChanged: _filterNodes,
                ),
              ),
              const SizedBox(height: 8),

              // Results
              Flexible(
                child: _filteredNodes.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No nodes found',
                            style: TextStyle(color: Colors.white38),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredNodes.length,
                        itemBuilder: (context, index) {
                          final entry = _filteredNodes[index];
                          final isSelected = index == _selectedIndex;

                          return InkWell(
                            onTap: () => _selectNode(index),
                            onHover: (hovering) {
                              if (hovering) {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.blue.withOpacity(0.3)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.widgets,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.value.displayName,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : const Color(0xFFDEDEDE),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (entry.value.description.isNotEmpty)
                                          Text(
                                            entry.value.description,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white70
                                                  : Colors.white54,
                                              fontSize: 11,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Footer with help text
              if (_filteredNodes.isNotEmpty) ...[
                const Divider(color: Colors.white24, height: 1),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    '↑↓ Navigate • ↵ Select • Esc Cancel',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a searchable node creation menu at the specified position
Future<void> showSearchableNodeMenu(
  BuildContext context, {
  required List<MapEntry<String, NodePrototype>> nodePrototypes,
  required Offset position,
  required Function(String nodeKey) onNodeSelected,
  VoidCallback? onDismiss,
}) async {
  // Ensure we're not showing multiple context menus
  if (isContextMenuVisible) return;

  isContextMenuVisible = true;

  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Stack(
      children: [
        // Background that closes the menu when tapped
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              overlayEntry.remove();
              isContextMenuVisible = false;
              onDismiss?.call();
            },
            child: Container(color: Colors.transparent),
          ),
        ),
        // The actual menu
        Positioned(
          left: position.dx,
          top: position.dy,
          child: SearchableNodeMenu(
            nodePrototypes: nodePrototypes,
            position: position,
            onNodeSelected: (nodeKey) {
              overlayEntry.remove();
              isContextMenuVisible = false;
              onNodeSelected(nodeKey);
            },
            onDismiss: () {
              overlayEntry.remove();
              isContextMenuVisible = false;
              onDismiss?.call();
            },
          ),
        ),
      ],
    ),
  );

  overlay.insert(overlayEntry);

  // Clean up when the overlay is removed
  overlayEntry.addListener(() {
    if (!overlayEntry.mounted) {
      isContextMenuVisible = false;
    }
  });
}
