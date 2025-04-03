import 'package:flutter/material.dart'; // Added for Material widgets
import 'package:flutter/cupertino.dart';
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
    // Removed redundant iOS-style popup
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Error'),
        content: const Text(
            'Unable to connect to the photo manager backend service. Please make sure the backend server is running.'),
        actions: [
          TextButton(
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
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        content: Row(
          children: [
            const CupertinoActivityIndicator(),
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
    // List of screens for the tab navigation
    final List<Widget> screens = [
      const FolderScreen(),
      const AlbumScreen(),
      const SearchScreen(),
      const SettingsScreen(),
    ];

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.folder),
            label: 'Folders',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.photo_on_rectangle),
            label: 'Albums',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        activeColor: CupertinoColors.activeBlue,
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) => CupertinoPageScaffold(
            navigationBar: CupertinoNavigationBar(
              middle: const Text('Pixels'),
              trailing: _isCheckingConnection
                  ? const CupertinoActivityIndicator()
                  : _isBackendConnected
                      ? const Icon(CupertinoIcons.cloud_download,
                          color: CupertinoColors.systemGreen)
                      : const Icon(CupertinoIcons.exclamationmark_circle,
                          color: CupertinoColors.systemRed),
            ),
            child: SafeArea(
              child: _isBackendConnected
                  ? screens[_selectedIndex]
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.exclamationmark_circle,
                              size: 64, color: CupertinoColors.systemGrey),
                          const SizedBox(height: 16),
                          const Text(
                            'Not connected to backend service',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 24),
                          CupertinoButton(
                            onPressed: _isCheckingConnection
                                ? null
                                : _checkBackendConnection,
                            child: _isCheckingConnection
                                ? const CupertinoActivityIndicator()
                                : const Text('Retry Connection'),
                          ),
                          const SizedBox(height: 8),
                          CupertinoButton.filled(
                            onPressed: _isCheckingConnection
                                ? null
                                : () async {
                                    // Show loading indicator
                                    _showLoadingDialog(
                                        'Starting backend service...');

                                    // Try to start backend
                                    try {
                                      final success =
                                          await _backendService.startBackend();

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
                    ),
            ),
          ),
        );
      },
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
