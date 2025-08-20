import 'package:example/l10n/app_localizations.dart';
import 'package:fl_nodes/fl_nodes.dart';
import 'package:flutter/material.dart';

class SearchWidget extends StatefulWidget {
  final FlNodeEditorController controller;

  const SearchWidget({
    required this.controller,
    super.key,
  });

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final List<String> _searchResults = [];
  int _currentFocusIndex = -1;
  bool _isSearching = false;
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toNextResult() {
    if (_searchResults.isEmpty) return;

    setState(() {
      _currentFocusIndex = (_currentFocusIndex + 1) % _searchResults.length;
    });

    _focusCurrentResult();
  }

  void _toPreviousResult() {
    if (_searchResults.isEmpty) return;

    setState(() {
      _currentFocusIndex = _currentFocusIndex <= 0
          ? _searchResults.length - 1
          : _currentFocusIndex - 1;
    });

    _focusCurrentResult();
  }

  void _focusCurrentResult() {
    if (_currentFocusIndex >= 0 && _currentFocusIndex < _searchResults.length) {
      final nodeId = _searchResults[_currentFocusIndex];
      widget.controller.focusNodesById({nodeId});
    }
  }

  void _resetFocus() {
    setState(() {
      _currentFocusIndex = -1;
    });
  }

  String _getResultText() {
    if (_isSearching) {
      return AppLocalizations.of(context)!.searching;
    }

    if (_searchResults.isEmpty) {
      return AppLocalizations.of(context)!.noResults;
    }

    if (_currentFocusIndex >= 0) {
      return AppLocalizations.of(context)!.resultPosition(
        _currentFocusIndex + 1,
        _searchResults.length,
      );
    }

    return AppLocalizations.of(context)!.resultsCount(
      _searchResults.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      height: 50,
      duration: const Duration(milliseconds: 900),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: AppLocalizations.of(context)!.searchNodesTooltip,
            icon: Icon(
              _showSearch ? Icons.close : Icons.search,
              size: 32,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;

                if (!_showSearch) {
                  _searchController.clear();
                  _searchResults.clear();
                  _resetFocus();
                } else {
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      // ignore: use_build_context_synchronously
                      FocusScope.of(context).requestFocus(_searchFocusNode);
                    }
                  });
                }
              });
            },
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SizeTransition(
                sizeFactor: animation,
                axis: Axis.horizontal,
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: _showSearch
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          key: ValueKey<bool>(_showSearch),
                          width: 200,
                          child: TextField(
                            autofocus: true,
                            focusNode: _searchFocusNode,
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText:
                                  '${AppLocalizations.of(context)!.searchNodesTooltip}...',
                              hintStyle: const TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(color: Colors.white),
                            onChanged: (value) async {
                              if (value.isEmpty) {
                                setState(() {
                                  _isSearching = false;
                                  _searchResults.clear();
                                  _resetFocus();
                                });
                                return;
                              }

                              setState(() {
                                _isSearching = true;
                                _searchResults.clear();
                                _resetFocus();
                              });

                              try {
                                final results = await widget.controller
                                    .searchNodesByName(context, value);

                                // Only update if the search term hasn't changed
                                if (_searchController.text == value) {
                                  setState(() {
                                    _searchResults.clear();
                                    _searchResults.addAll(results);
                                    _isSearching = false;
                                  });
                                }
                              } catch (e) {
                                if (_searchController.text == value) {
                                  setState(() {
                                    _isSearching = false;
                                  });
                                }
                              }
                            },
                            onSubmitted: (value) {
                              if (_searchResults.isNotEmpty) {
                                if (_currentFocusIndex >= 0 &&
                                    _searchResults.length > 1) {
                                  _toNextResult();
                                } else {
                                  setState(() {
                                    _currentFocusIndex = 0;
                                  });
                                  _focusCurrentResult();
                                }

                                _searchFocusNode.requestFocus();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_searchResults.isNotEmpty) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.keyboard_arrow_up,
                              color: Colors.white,
                            ),
                            onPressed: _toPreviousResult,
                            tooltip:
                                AppLocalizations.of(context)!.previousResult,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                            ),
                            onPressed: _toNextResult,
                            tooltip: AppLocalizations.of(context)!.nextResult,
                          ),
                        ],
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 80),
                          child: Text(
                            _getResultText(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
