import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import 'folder_screen.dart';
import 'album_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final BackendService _backendService = BackendService();
  bool _isBackendConnected = false;

  @override
  void initState() {
    super.initState();
    _checkBackendConnection();
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Connection Error'),
        content: const Text(
            'Unable to connect to the photo manager backend service. '
            'Please make sure the backend server is running.'),
        actions: [
          TextButton(
            child: const Text('Retry'),
            onPressed: () {
              Navigator.of(context).pop();
              _checkBackendConnection();
            },
          ),
          TextButton(
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
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
    // List of screens for the bottom navigation
    final List<Widget> screens = [
      FolderScreen(),
      AlbumScreen(),
      SearchScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pixels'),
        actions: [
          // Backend connection status indicator
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _isBackendConnected
                ? const Icon(Icons.cloud_done, color: Colors.green)
                : const Icon(Icons.cloud_off, color: Colors.red),
          ),
        ],
      ),
      body: _isBackendConnected
          ? screens[_selectedIndex]
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Not connected to backend service',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _checkBackendConnection,
                    child: const Text('Retry Connection'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
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
                    child: const Text('Start Backend Service'),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: 'Folders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_album),
            label: 'Albums',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
