import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import '../services/log_service.dart';

class LogPanel extends StatefulWidget {
  final double initialHeight;
  final double minHeight;
  final double maxHeight;

  const LogPanel({
    super.key,
    this.initialHeight = 150,
    this.minHeight = 100,
    this.maxHeight = 300,
  });

  @override
  State<LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends State<LogPanel> {
  final LogService _logService = LogService();
  bool _expanded = false;
  double _logHeight = 0; // Will be initialized in initState
  final Set<LogLevel> _visibleLevels = Set.from(LogLevel.values);
  bool _autoScroll = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _logHeight = widget.initialHeight;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _clearLogs() {
    _logService.clearLogs();
  }

  void _copyLogs() {
    final logs = _logService.logs;
    if (logs.isEmpty) return;

    final filteredLogs = logs
        .where((log) => _visibleLevels.contains(log.level))
        .map((log) => log.toString())
        .join('\n');

    Clipboard.setData(ClipboardData(text: filteredLogs)).then((_) {
      showSnackbar(
        context,
        const Snackbar(
          content: Text('Logs copied to clipboard'),
        ),
      );
    });
  }

  void _toggleLogLevel(LogLevel level) {
    setState(() {
      if (_visibleLevels.contains(level)) {
        _visibleLevels.remove(level);
      } else {
        _visibleLevels.add(level);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with toggle
        GestureDetector(
          onTap: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          child: Tooltip(
            message: _expanded ? "Collapse log panel" : "Expand log panel",
            child: Container(
              height: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              color: FluentTheme.of(context).accentColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    _expanded
                        ? FluentIcons.chevron_down
                        : FluentIcons.chevron_up,
                    size: 12,
                  ),
                  const SizedBox(width: 8),
                  const Text('System Log', style: TextStyle(fontSize: 11)),
                  const Spacer(),
                  // Active processes counter
                  StreamBuilder<Map<String, String>>(
                    stream: _logService.processStream,
                    initialData: _logService.activeProcesses,
                    builder: (context, snapshot) {
                      final processes = snapshot.data ?? {};
                      return Text(
                        '${processes.length} active processes',
                        style: TextStyle(
                          fontSize: 10,
                          color: FluentTheme.of(context).accentColor,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // Process status area (always visible)
        Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          color: FluentTheme.of(context).cardColor,
          child: StreamBuilder<Map<String, String>>(
            stream: _logService.processStream,
            initialData: _logService.activeProcesses,
            builder: (context, snapshot) {
              final processes = snapshot.data ?? {};
              if (processes.isEmpty) {
                return const Center(
                  child: Text('No active processes',
                      style: TextStyle(fontSize: 10)),
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: processes.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final entry = processes.entries.elementAt(index);
                        return Tooltip(
                          message: entry.value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 10,
                                height: 10,
                                child: ProgressRing(strokeWidth: 2),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entry.value,
                                style: const TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // Expanded log view (only visible when expanded)
        if (_expanded)
          Column(
            children: [
              // Log filter and controls
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                color: FluentTheme.of(context).micaBackgroundColor,
                child: Row(
                  children: [
                    // Filter buttons
                    for (final level in LogLevel.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: Tooltip(
                          message: "Toggle ${level.name} logs",
                          child: ToggleButton(
                            checked: _visibleLevels.contains(level),
                            onChanged: (_) => _toggleLogLevel(level),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _getLogColor(context, level),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  level.name[0].toUpperCase() +
                                      level.name.substring(1),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const Spacer(),

                    // Auto-scroll toggle
                    Tooltip(
                      message: "Toggle auto-scroll to newest logs",
                      child: ToggleButton(
                        checked: _autoScroll,
                        onChanged: (value) {
                          setState(() {
                            _autoScroll = value;
                          });
                        },
                        child: const Icon(FluentIcons.down, size: 10),
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Copy logs button
                    Tooltip(
                      message: "Copy logs to clipboard",
                      child: IconButton(
                        icon: const Icon(FluentIcons.copy, size: 10),
                        onPressed: _copyLogs,
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Clear logs button
                    Tooltip(
                      message: "Clear all logs",
                      child: IconButton(
                        icon: const Icon(FluentIcons.clear, size: 10),
                        onPressed: _clearLogs,
                      ),
                    ),
                  ],
                ),
              ),

              // Resizable log area
              GestureDetector(
                onVerticalDragUpdate: (details) {
                  setState(() {
                    _logHeight = (_logHeight - details.delta.dy)
                        .clamp(widget.minHeight, widget.maxHeight);
                  });
                },
                child: Container(
                  height: 8,
                  color: FluentTheme.of(context)
                      .micaBackgroundColor
                      .withOpacity(0.5),
                  child: Center(
                    child: Container(
                      width: 30,
                      height: 2,
                      color:
                          FluentTheme.of(context).accentColor.withOpacity(0.5),
                    ),
                  ),
                ),
              ),

              // Log content
              Container(
                height: _logHeight,
                color: FluentTheme.of(context).scaffoldBackgroundColor,
                child: StreamBuilder<List<LogEntry>>(
                  stream: _logService.logStream,
                  initialData: _logService.logs,
                  builder: (context, snapshot) {
                    final logs = snapshot.data ?? [];
                    final filteredLogs = logs
                        .where((log) => _visibleLevels.contains(log.level))
                        .toList();

                    // Auto-scroll to bottom if enabled
                    if (_autoScroll && filteredLogs.isNotEmpty) {
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

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 2.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Log indicator
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 3, right: 6),
                                decoration: BoxDecoration(
                                  color: _getLogColor(context, log.level),
                                  shape: BoxShape.circle,
                                ),
                              ),

                              // Timestamp
                              Text(
                                _formatTimestamp(log.timestamp),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: FluentTheme.of(context)
                                      .typography
                                      .caption!
                                      .color,
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Log message
                              Expanded(
                                child: Text(
                                  log.message,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _getLogColor(context, log.level),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }

  Color _getLogColor(BuildContext context, LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return Colors.red;
      case LogLevel.warning:
        return Colors.orange;
      case LogLevel.process:
        return Colors.blue;
      case LogLevel.info:
      default:
        return FluentTheme.of(context).typography.body!.color!;
    }
  }
}
