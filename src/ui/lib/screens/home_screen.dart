import 'package:flutter/material.dart' show CircularProgressIndicator;
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
  bool _isTestingConnection = false;

  @override
  void initState() {
    super.initState();
    _backendService = widget.backendService;
    _isBackendConnected = widget.backendAvailable;

    // Only check connection if not already confirmed available
    if (!_isBackendConnected) {
      _checkBackendConnection();
    }
  }

  Future<void> _checkBackendConnection() async {
    try {
      // Check if we can communicate with the backend
      await _backendService.getFolders();
      setState(() {
        _isBackendConnected = true;
      });
    } catch (e) {
      setState(() {
        _isBackendConnected = false;
      });

      // Show error dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showBackendConnectionError();
      });
    }
  }

  void _showBackendConnectionError() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Connection Error'),
        content: const Text(
            'Unable to connect to the photo manager backend service. '
            'Please make sure the backend server is running.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Retry'),
            onPressed: () {
              Navigator.of(context).pop();
              _checkBackendConnection();
            },
          ),
          CupertinoDialogAction(
            child: const Text('Start Backend'),
            onPressed: () async {
              Navigator.of(context).pop();

              // Show loading indicator
              _showLoadingDialog('Starting backend service...');

              // Try to start backend
              final success = await _backendService.startBackend();

              // Hide loading indicator
              Navigator.of(context).pop();

              if (success) {
                setState(() {
                  _isBackendConnected = true;
                });
              } else {
                _showBackendConnectionError();
              }
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
            const CircularProgressIndicator(),
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
              trailing: _isBackendConnected
                  ? const Icon(CupertinoIcons.cloud_download,
                      color: CupertinoColors.systemGreen)
                  : const Icon(CupertinoIcons.cloud_slash,
                      color: CupertinoColors.systemRed),
            ),
            child: SafeArea(
              child: _isBackendConnected
                  ? screens[_selectedIndex]
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.cloud_slash,
                              size: 64, color: CupertinoColors.systemGrey),
                          const SizedBox(height: 16),
                          const Text(
                            'Not connected to backend service',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 24),
                          CupertinoButton(
                            onPressed: _checkBackendConnection,
                            child: const Text('Retry Connection'),
                          ),
                          const SizedBox(height: 8),
                          CupertinoButton.filled(
                            onPressed: () async {
                              // Show loading indicator
                              _showLoadingDialog('Starting backend service...');

                              // Try to start backend
                              final success =
                                  await _backendService.startBackend();

                              // Hide loading indicator
                              Navigator.of(context).pop();

                              if (success) {
                                setState(() {
                                  _isBackendConnected = true;
                                });
                              } else {
                                _showBackendConnectionError();
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
