import 'package:fluent_ui/fluent_ui.dart';
import '../services/backend_service.dart';
import '../services/log_service.dart';
import 'folder_screen.dart';
import 'album_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'duplicate_detection_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool backendAvailable;
  final BackendService backendService;

  const HomeScreen({
    super.key,
    this.backendAvailable = false,
    required this.backendService,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late BackendService _backendService;
  bool _isBackendConnected = false;
  bool _isCheckingConnection = false;

  @override
  void initState() {
    super.initState();
    _backendService = widget.backendService;
    _isBackendConnected = widget.backendAvailable;

    // Listen to backend status changes
    _backendService.statusStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isBackendConnected = isConnected;
        });
      }
    });

    // Check connection at startup
    if (!_isBackendConnected) {
      Future.delayed(Duration.zero, _checkBackendConnection);
    }

    LogService().log('Home screen initialized', level: LogLevel.info);
  }

  Future<void> _checkBackendConnection() async {
    if (_isCheckingConnection) return;

    setState(() {
      _isCheckingConnection = true;
    });

    try {
      final isRunning = await _backendService.checkBackendStatus();
      if (mounted) {
        setState(() {
          _isBackendConnected = isRunning;
          _isCheckingConnection = false;
        });
      }

      if (!isRunning) {
        LogService().log('Backend not connected', level: LogLevel.warning);
        if (mounted) {
          _showBackendConnectionError();
        }
      } else {
        LogService().log('Connected to backend service');
      }
    } catch (e) {
      LogService().log('Error checking backend: $e', level: LogLevel.error);
      if (mounted) {
        setState(() {
          _isCheckingConnection = false;
        });
        _showBackendConnectionError();
      }
    }
  }

  void _showBackendConnectionError() {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Connection Error'),
        content: const Text(
            'Unable to connect to the photo manager backend service. Please make sure the backend server is running.'),
        actions: [
          Button(
            child: const Text('Retry'),
            onPressed: () {
              Navigator.of(context).pop();
              _checkBackendConnection();
            },
          ),
        ],
      ),
    );
  }

  void _showLoadingDialog(String message) {
    LogService().startProcess('backend_start', message);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ContentDialog(
        content: Row(
          children: [
            const ProgressRing(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // List of screens for the navigation
    final List<Widget> screens = [
      const FolderScreen(),
      const AlbumScreen(),
      const SearchScreen(),
      const SettingsScreen(),
      const DuplicateDetectionScreen(),
    ];

    return NavigationView(
      pane: NavigationPane(
        selected: _selectedIndex,
        onChanged: _onItemTapped,
        displayMode: PaneDisplayMode.compact,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.folder),
            title: const Text('Folders'),
            body: _isBackendConnected
                ? screens[0]
                : _buildConnectionErrorScreen(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.album),
            title: const Text('Albums'),
            body: _isBackendConnected
                ? screens[1]
                : _buildConnectionErrorScreen(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.search),
            title: const Text('Search'),
            body: _isBackendConnected
                ? screens[2]
                : _buildConnectionErrorScreen(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.settings),
            title: const Text('Settings'),
            body: _isBackendConnected
                ? screens[3]
                : _buildConnectionErrorScreen(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.copy),
            title: const Text('Duplicate Detection'),
            body: _isBackendConnected
                ? screens[4]
                : _buildConnectionErrorScreen(),
          ),
        ],
        footerItems: [
          PaneItemSeparator(),
          PaneItem(
            icon: Icon(
              _isBackendConnected
                  ? FluentIcons.plug_connected
                  : FluentIcons.plug_disconnected,
              color: _isBackendConnected ? Colors.green : Colors.red,
            ),
            title: Text(
              _isBackendConnected ? 'Connected' : 'Disconnected',
              style: TextStyle(
                color: _isBackendConnected ? Colors.green : Colors.red,
              ),
            ),
            body: const SizedBox.shrink(), // Empty body
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FluentIcons.error, size: 64, color: Colors.grey[100]),
          const SizedBox(height: 16),
          const Text(
            'Not connected to backend service',
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 24),
          Button(
            onPressed: _isCheckingConnection ? null : _checkBackendConnection,
            child: _isCheckingConnection
                ? const ProgressRing()
                : const Text('Retry Connection'),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _isCheckingConnection
                ? null
                : () async {
                    // Show loading indicator
                    _showLoadingDialog('Starting backend service...');

                    // Try to start backend
                    try {
                      final success = await _backendService.startBackend();

                      // Hide loading indicator if still mounted
                      if (mounted) {
                        Navigator.of(context).pop();
                        LogService().endProcess('backend_start',
                            finalStatus: 'Backend started successfully');

                        if (success) {
                          setState(() {
                            _isBackendConnected = true;
                          });
                        } else {
                          _showBackendConnectionError();
                        }
                      }
                    } catch (e) {
                      // Hide loading indicator if still mounted
                      if (mounted) {
                        Navigator.of(context).pop();
                        LogService().endProcess('backend_start',
                            finalStatus: 'Error starting backend: $e');
                        _showBackendConnectionError();
                      }
                    }
                  },
            child: const Text('Start Backend Service'),
          ),
        ],
      ),
    );
  }
}
