import 'package:example/l10n/app_localizations.dart';
import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HierarchyWidget extends StatefulWidget {
  final FlNodeEditorController controller;
  final bool isCollapsed;

  const HierarchyWidget({
    required this.controller,
    required this.isCollapsed,
    super.key,
  });

  @override
  State<HierarchyWidget> createState() => _HierarchyWidgetState();
}

class _HierarchyWidgetState extends State<HierarchyWidget> {
  String _searchQuery = '';
  HierarchySortOption _sortOption = HierarchySortOption.name;
  bool _showOnlySelected = false;

  @override
  void initState() {
    super.initState();
    _subscribeToControllerEvents();
  }

  void _subscribeToControllerEvents() {
    widget.controller.eventBus.events.listen((event) {
      if (event.isHandled) return;

      if (event is FlNodeSelectionEvent ||
          event is FlNodeDeselectionEvent ||
          event is FlDragSelectionEvent ||
          event is FlAddNodeEvent ||
          event is FlRemoveNodeEvent ||
          event is FlLoadProjectEvent ||
          event is FlNewProjectEvent ||
          event is FlPasteSelectionEvent ||
          event is FlCutSelectionEvent) {
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  void _onNodeTap(FlNodeDataModel node) {
    widget.controller.focusNodesById(
      {node.id},
      holdSelection: HardwareKeyboard.instance.isControlPressed,
    );
  }

  List<FlNodeDataModel> _getFilteredAndSortedNodes() {
    var nodes = widget.controller.nodesAsList;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      nodes = nodes.where((node) {
        return node.prototype
            .displayName(context)
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by selection if needed
    if (_showOnlySelected) {
      nodes = nodes.where((node) => node.state.isSelected).toList();
    }

    // Sort nodes
    switch (_sortOption) {
      case HierarchySortOption.name:
        nodes.sort(
          (a, b) => a.prototype
              .displayName(context)
              .compareTo(b.prototype.displayName(context)),
        );
        break;
      case HierarchySortOption.type:
        nodes.sort(
          (a, b) => a.prototype.runtimeType
              .toString()
              .compareTo(b.prototype.runtimeType.toString()),
        );
        break;
      case HierarchySortOption.position:
        nodes.sort((a, b) {
          final aDistance = a.offset.dx + a.offset.dy;
          final bDistance = b.offset.dx + b.offset.dy;
          return aDistance.compareTo(bDistance);
        });
        break;
    }

    return nodes;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(51),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilters(),
          _buildNodeStats(),
          Expanded(
            child: _buildNodeList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(51),
          ),
        ),
      ),
      child: Row(
        spacing: 8,
        children: [
          Icon(
            Icons.account_tree,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          Text(
            "Node Hierarchy",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final strings = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          // Search field
          TextField(
            decoration: InputDecoration(
              hintText: strings.searchNodesHint,
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              isDense: true,
            ),
            style: Theme.of(context).textTheme.bodyMedium,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          // Filter and sort controls
          Row(
            mainAxisSize: MainAxisSize.max,
            spacing: 8,
            children: [
              // Sort dropdown
              Expanded(
                child: DropdownButtonFormField<HierarchySortOption>(
                  isExpanded: true,
                  value: _sortOption,
                  decoration: InputDecoration(
                    labelText: strings.sortByLabel,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isDense: true,
                  ),
                  items: HierarchySortOption.values.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(
                        option.displayName,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortOption = value;
                      });
                    }
                  },
                ),
              ),

              // Show only selected toggle
              Tooltip(
                message: strings.showOnlySelectedTooltip,
                child: FilterChip(
                  label: Icon(
                    Icons.filter_list,
                    size: 16,
                    color: _showOnlySelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  selected: _showOnlySelected,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlySelected = selected;
                    });
                  },
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNodeStats() {
    final strings = AppLocalizations.of(context)!;
    final allNodes = widget.controller.nodesAsList;
    final filteredNodes = _getFilteredAndSortedNodes();
    final selectedCount = allNodes.where((n) => n.state.isSelected).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withAlpha(127),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(25),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            strings.showingNodesCount(filteredNodes.length, allNodes.length),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          if (selectedCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                strings.selectedCount(selectedCount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 10,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNodeList() {
    final strings = AppLocalizations.of(context)!;
    final nodes = _getFilteredAndSortedNodes();

    if (nodes.isEmpty) {
      return Center(
        child: Column(
          spacing: 16,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.account_tree,
              size: 48,
              color:
                  Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(127),
            ),
            Text(
              _searchQuery.isNotEmpty
                  ? strings.noNodesFound
                  : strings.noNodesInGraph,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withAlpha(179),
                  ),
            ),
            if (_searchQuery.isNotEmpty)
              Text(
                strings.tryDifferentSearchTerm,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant
                          .withAlpha(127),
                    ),
              ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      itemCount: nodes.length,
      scrollDirection: Axis.vertical,
      itemBuilder: (context, index) {
        final node = nodes[index];
        final isSelected = node.state.isSelected;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _onNodeTap(node),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withAlpha(51)
                    : Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withAlpha(76),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      // Node type icon
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _getNodeTypeColor(node).withAlpha(51),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          _getNodeTypeIcon(node),
                          size: 16,
                          color: _getNodeTypeColor(node),
                        ),
                      ),

                      // Node name
                      Text(
                        node.prototype.displayName(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                      ),

                      // Selection indicator
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Node details
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withAlpha(127),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'x: ${node.offset.dx.toStringAsFixed(0)}, y: ${node.offset.dy.toStringAsFixed(0)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withAlpha(205),
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getNodeTypeColor(FlNodeDataModel node) {
    final idName = node.prototype.idName;

    if (idName.contains('value')) return Colors.orange;
    if (idName.contains('generator')) return Colors.blue;
    if (idName.contains('math')) return Colors.teal;
    if (idName.contains('logic')) return Colors.red;
    if (idName.contains('flow')) return Colors.green;
    if (idName.contains('io')) return Colors.purple;

    return Colors.grey;
  }

  IconData _getNodeTypeIcon(FlNodeDataModel node) {
    final idName = node.prototype.idName;

    if (idName.contains('value')) return Icons.data_object;
    if (idName.contains('generator')) return Icons.computer;
    if (idName.contains('math')) return Icons.calculate;
    if (idName.contains('logic')) return Icons.account_tree;
    if (idName.contains('flow')) return Icons.alt_route;
    if (idName.contains('io')) return Icons.input;

    return Icons.circle;
  }
}

enum HierarchySortOption {
  name('Name'),
  type('Type'),
  position('Position');

  const HierarchySortOption(this.displayName);

  final String displayName;
}
