import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'services/backend_service.dart';
import 'services/log_service.dart';
import 'services/app_lifecycle_manager.dart';
import 'screens/home_screen.dart';
import 'widgets/log_panel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final backendService = BackendService();
    final logService = LogService();

    // Log app startup
    logService.log('Application starting...');

    return FluentApp(
      title: 'Pixels',
      theme: FluentThemeData(
        accentColor: Colors.blue,
        visualDensity: VisualDensity.standard,
        brightness: Brightness.light,
      ),
      darkTheme: FluentThemeData(
        accentColor: Colors.blue,
        visualDensity: VisualDensity.standard,
        brightness: Brightness.dark,
      ),
      home: AppLifecycleManager(
        backendService: backendService,
        child: Provider<LogService>.value(
          value: logService,
          child: Provider<BackendService>.value(
            value: backendService,
            child: AppShell(backendService: backendService),
          ),
        ),
      ),
    );
  }
}

class AppShell extends StatefulWidget {
  final BackendService backendService;

  const AppShell({
    super.key,
    required this.backendService,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isBackendConnected = false;

  @override
  void initState() {
    super.initState();
    _checkBackendConnection();

    // Listen to backend status changes
    widget.backendService.statusStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isBackendConnected = isConnected;
        });
      }
    });
  }

  Future<void> _checkBackendConnection() async {
    try {
      final bool isRunning = await widget.backendService.checkBackendStatus();
      if (mounted) {
        setState(() {
          _isBackendConnected = isRunning;
        });
      }
    } catch (e) {
      // Backend is not running
      LogService()
          .log('Error checking backend connection: $e', level: LogLevel.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Menu
        TopMenuBar(backendService: widget.backendService),

        // Main Content Area
        Expanded(
          child: HomeScreen(
            backendAvailable: _isBackendConnected,
            backendService: widget.backendService,
          ),
        ),

        // Log Panel
        const LogPanel(),
      ],
    );
  }
}
