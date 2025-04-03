import 'package:flutter/material.dart' as material;
import 'package:fluent_ui/fluent_ui.dart';
import '../services/backend_service.dart';
import 'folder_screen.dart';
import 'album_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

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

    // Only check connection if not already confirmed available
    if (!_isBackendConnected) {
      // Add a short delay to allow the UI to build
      Future.delayed(Duration.zero, () {
        _checkBackendConnection();
      });
    }
  }

  Future<void> _checkBackendConnection() async {
    if (_isCheckingConnection) return;

    setState(() {
      _isCheckingConnection = true;
    });

    try {
      // First check the backend status
      final isRunning = await _backendService.checkBackendStatus();

      if (isRunning) {
        setState(() {
          _isBackendConnected = true;
          _isCheckingConnection = false;
        });
        return;
      }

      // If not running, try to connect to verify the backend
      await _backendService.getFolders();
      setState(() {
        _isBackendConnected = true;
      });
    } catch (e) {
      debugPrint('HomeScreen: Backend connection check failed: $e');
      setState(() {
        _isBackendConnected = false;
      });

      // Only show error dialog if we're still mounted
      if (mounted) {
        // Show error dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showBackendConnectionError();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingConnection = false;
        });
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
    ];

    return NavigationView(
      appBar: NavigationAppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/pixels.png',
              height: 24,
              width: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Pixels',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isCheckingConnection
                ? const ProgressRing(strokeWidth: 2.0)
                : _isBackendConnected
                    ? const Icon(FluentIcons.cloud_download,
                        color: material.Colors.green)
                    : const Icon(FluentIcons.error, color: material.Colors.red),
            const SizedBox(width: 10),
          ],
        ),
      ),
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

  @override
  void dispose() {
    // Consider stopping the backend when app closes
    // Note: This might not be desirable as other apps might use it
    // _backendService.stopBackend();
    super.dispose();
  }
}
