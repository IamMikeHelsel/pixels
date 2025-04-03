import 'package:fluent_ui/fluent_ui.dart';
import '../services/log_service.dart';

class LogPanel extends StatefulWidget {
  const LogPanel({super.key});

  @override
  State<LogPanel> createState() => _LogPanelState();
}

class _LogPanelState extends State<LogPanel> {
  final LogService _logService = LogService();
  bool _expanded = false;

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
          child: Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            color: FluentTheme.of(context).accentColor.withOpacity(0.1),
            child: Row(
              children: [
                Icon(
                  _expanded ? FluentIcons.chevron_down : FluentIcons.chevron_up,
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

              // Display up to 2 active processes
              final entries = processes.entries.take(2).toList();
              return Row(
                children: [
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i > 0) const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        entries[i].value,
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),

        // Expanded log view (only visible when expanded)
        if (_expanded)
          Container(
            height: 150,
            color: FluentTheme.of(context).scaffoldBackgroundColor,
            child: StreamBuilder<List<LogEntry>>(
              stream: _logService.logStream,
              initialData: _logService.logs,
              builder: (context, snapshot) {
                final logs = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log =
                        logs[logs.length - 1 - index]; // Show newest first
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 2.0),
                      child: Text(
                        log.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getLogColor(context, log.level),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
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
