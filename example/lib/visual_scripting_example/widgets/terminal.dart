import 'package:example/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum LogLevel {
  info('Info', Icons.info_outline, Colors.blue),
  warning('Warning', Icons.warning_amber, Colors.orange),
  error('Error', Icons.error_outline, Colors.red),
  success('Success', Icons.check_circle_outline, Colors.green),
  debug('Debug', Icons.bug_report, Colors.purple);

  const LogLevel(this.displayName, this.icon, this.color);

  final String displayName;
  final IconData icon;
  final Color color;
}

class LogEntry {
  final String message;
  final LogLevel level;
  final DateTime timestamp;
  final String? nodeId;
  final String? nodeName;

  LogEntry({
    required this.message,
    required this.level,
    required this.timestamp,
    this.nodeId,
    this.nodeName,
  });
}

class TerminalController extends ChangeNotifier {
  static TerminalController? _instance;

  static TerminalController get instance {
    _instance ??= TerminalController._internal();
    return _instance!;
  }

  TerminalController._internal();

  factory TerminalController() {
    return instance;
  }

  final List<LogEntry> _logs = [];

  List<LogEntry> get logs => List.unmodifiable(_logs);

  void addLog(
    String message,
    LogLevel level, {
    String? nodeId,
    String? nodeName,
  }) {
    _logs.add(
      LogEntry(
        message: message,
        level: level,
        timestamp: DateTime.now(),
        nodeId: nodeId,
        nodeName: nodeName,
      ),
    );
    notifyListeners();
  }

  void info(String message, {String? nodeId, String? nodeName}) {
    addLog(message, LogLevel.info, nodeId: nodeId, nodeName: nodeName);
  }

  void warning(String message, {String? nodeId, String? nodeName}) {
    addLog(message, LogLevel.warning, nodeId: nodeId, nodeName: nodeName);
  }

  void error(String message, {String? nodeId, String? nodeName}) {
    addLog(message, LogLevel.error, nodeId: nodeId, nodeName: nodeName);
  }

  void success(String message, {String? nodeId, String? nodeName}) {
    addLog(message, LogLevel.success, nodeId: nodeId, nodeName: nodeName);
  }

  void debug(String message, {String? nodeId, String? nodeName}) {
    addLog(message, LogLevel.debug, nodeId: nodeId, nodeName: nodeName);
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  static void resetInstance() {
    _instance?.dispose();
    _instance = null;
  }

  @override
  void dispose() {
    _logs.clear();
    super.dispose();
  }
}

class TerminalWidget extends StatefulWidget {
  final bool isCollapsed;
  final TerminalController controller;

  const TerminalWidget({
    required this.controller,
    required this.isCollapsed,
    super.key,
  });

  @override
  State<TerminalWidget> createState() => _TerminalWidgetState();
}

class _TerminalWidgetState extends State<TerminalWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
    widget.controller.addListener(_onLogsChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onLogsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onLogsChanged() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addWelcomeMessage() {
    widget.controller.success('Terminal initialized');
    widget.controller
        .info('Ready to receive output from visual scripting nodes');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(51),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildLogList(),
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
            Icons.terminal,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          Text(
            "Output Terminal",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: AppLocalizations.of(context)!.clearLogsTooltip,
            onPressed: widget.controller.logs.isEmpty
                ? null
                : widget.controller.clearLogs,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildLogList() {
    final logs = widget.controller.logs;

    if (logs.isEmpty) {
      return Center(
        child: Column(
          spacing: 16,
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.terminal,
              size: 48,
              color:
                  Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(127),
            ),
            Text(
              AppLocalizations.of(context)!.terminalNoOutput,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withAlpha(179),
                  ),
            ),
            Text(
              AppLocalizations.of(context)!.terminalPlaceholder,
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
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return _buildLogEntry(log);
      },
    );
  }

  Widget _buildLogEntry(LogEntry log) {
    final timeStr = _formatTime(log.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withAlpha(51),
          borderRadius: BorderRadius.circular(6),
          border: Border(
            left: BorderSide(
              color: log.level.color,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Row(
              spacing: 8,
              children: [
                Icon(
                  log.level.icon,
                  size: 16,
                  color: log.level.color,
                ),
                Text(
                  timeStr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withAlpha(179),
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: log.level.color.withAlpha(51),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    log.level.displayName.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: log.level.color,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: SelectableText(
                log.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:'
        '${time.second.toString().padLeft(2, '0')}';
  }
}
