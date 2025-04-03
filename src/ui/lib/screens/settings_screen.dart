import 'package:flutter/material.dart' show CircularProgressIndicator, Divider;
import 'package:flutter/cupertino.dart';
import '../services/backend_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackendService _backendService = BackendService();
  final TextEditingController _serverUrlController = TextEditingController();
  final TextEditingController _pythonPathController = TextEditingController();
  bool _isDarkMode = false;
  bool _autoImportEnabled = false;
  bool _isBackendConnected = false;
  bool _isTestingConnection = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBackendConnection();
  }

  void _loadSettings() {
    // In a real app, these would be loaded from shared preferences
    _serverUrlController.text = _backendService.baseUrl;

    // We would load the saved Python path here if we had it stored
    // For now, leave it empty to let the user fill it in if needed

    // Example settings with default values
    setState(() {
      _isDarkMode = false;
      _autoImportEnabled = false;
    });
  }

  Future<void> _checkBackendConnection() async {
    try {
      // Simple health check
      await _backendService.getFolders();
      setState(() {
        _isBackendConnected = true;
      });
    } catch (e) {
      setState(() {
        _isBackendConnected = false;
      });
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _pythonPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildBackendSection(),
            const Divider(),
            _buildAppearanceSection(),
            const Divider(),
            _buildLibrarySection(),
            const Divider(),
            _buildAboutSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            'Backend Connection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Connection status
        CupertinoListTile(
          leading: Icon(
            _isBackendConnected
                ? CupertinoIcons.cloud_download
                : CupertinoIcons.exclamationmark_circle,
            color: _isBackendConnected
                ? CupertinoColors.systemGreen
                : CupertinoColors.systemRed,
          ),
          title: const Text('Backend Status'),
          subtitle: Text(
            _isBackendConnected ? 'Connected to server' : 'Not connected',
          ),
          trailing: _isTestingConnection
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Icon(CupertinoIcons.refresh),
                  onPressed: () async {
                    setState(() {
                      _isTestingConnection = true;
                    });
                    await _checkBackendConnection();
                    setState(() {
                      _isTestingConnection = false;
                    });
                  },
                ),
        ),

        // Server URL
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: CupertinoTextField(
            controller: _serverUrlController,
            placeholder: 'http://localhost:5000/api',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text('Server URL:'),
            ),
            suffix: CupertinoButton(
              padding: const EdgeInsets.only(right: 8.0),
              child: const Icon(CupertinoIcons.checkmark_circle),
              onPressed: () {
                // Save the server URL
                _backendService.baseUrl = _serverUrlController.text;
                _showNotification('Server URL updated');
                _checkBackendConnection();
              },
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CupertinoColors.systemGrey4),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          ),
        ),

        // Python Path
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: CupertinoTextField(
            controller: _pythonPathController,
            placeholder: '/usr/bin/python3',
            prefix: const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text('Python Path:'),
            ),
            suffix: CupertinoButton(
              padding: const EdgeInsets.only(right: 8.0),
              child: const Icon(CupertinoIcons.checkmark_circle),
              onPressed: () {
                // Save the Python path
                _showNotification('Python path updated');
              },
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CupertinoColors.systemGrey4),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          ),
        ),

        // Start/stop backend buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              CupertinoButton.filled(
                child: const Text('Start Backend'),
                onPressed: _isBackendConnected
                    ? null
                    : () async {
                        setState(() {
                          _isTestingConnection = true;
                        });

                        try {
                          // Use the manually entered Python path if provided
                          final pythonPath =
                              _pythonPathController.text.trim().isNotEmpty
                                  ? _pythonPathController.text.trim()
                                  : null;

                          await _backendService.startBackend(
                              pythonPath: pythonPath);
                          await _checkBackendConnection();

                          if (_isBackendConnected) {
                            _showNotification('Backend started successfully');
                          } else {
                            _showNotification('Failed to start backend');
                          }
                        } catch (e) {
                          _showNotification('Error starting backend: $e');
                        } finally {
                          setState(() {
                            _isTestingConnection = false;
                          });
                        }
                      },
              ),
              CupertinoButton(
                color: CupertinoColors.systemRed,
                child: const Text('Stop Backend'),
                onPressed: !_isBackendConnected
                    ? null
                    : () async {
                        setState(() {
                          _isTestingConnection = true;
                        });
                        await _backendService.stopBackend();
                        await _checkBackendConnection();
                        setState(() {
                          _isTestingConnection = false;
                        });
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            'Appearance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        CupertinoListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Use dark theme throughout the app'),
          trailing: CupertinoSwitch(
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
              // In a real app, this would update the app's theme
              _showNotification('Theme preference saved');
            },
          ),
        ),
        CupertinoListTile(
          title: const Text('Thumbnail Size'),
          subtitle: const Text('Medium'),
          trailing: const CupertinoListTileChevron(),
          onTap: () {
            // Would open a dialog to select thumbnail size
            _showNotification('Thumbnail size settings coming soon');
          },
        ),
      ],
    );
  }

  Widget _buildLibrarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            'Library',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        CupertinoListTile(
          title: const Text('Auto-import New Photos'),
          subtitle: const Text(
              'Automatically import photos added to monitored folders'),
          trailing: CupertinoSwitch(
            value: _autoImportEnabled,
            onChanged: (value) {
              setState(() {
                _autoImportEnabled = value;
              });
              _showNotification(
                value ? 'Auto-import enabled' : 'Auto-import disabled',
              );
            },
          ),
        ),
        CupertinoListTile(
          title: const Text('Manage Monitored Folders'),
          trailing: const CupertinoListTileChevron(),
          onTap: () {
            // Would navigate to folder management screen
            _showNotification('Folder management coming soon');
          },
        ),
        CupertinoListTile(
          title: const Text('Re-index Library'),
          trailing: const Icon(CupertinoIcons.refresh),
          onTap: () {
            // Would trigger a re-index operation
            _showNotification('Library re-indexing coming soon');
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            'About',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const CupertinoListTile(
          title: Text('Version'),
          subtitle: Text('Pixels v1.0.0'),
        ),
        CupertinoListTile(
          title: const Text('View Documentation'),
          trailing: const Icon(CupertinoIcons.arrow_up_right_square),
          onTap: () {
            // Would open documentation
            _showNotification('Documentation coming soon');
          },
        ),
        CupertinoListTile(
          title: const Text('Open Source Licenses'),
          trailing: const CupertinoListTileChevron(),
          onTap: () {
            // Would show open source licenses
            _showNotification('Licenses info coming soon');
          },
        ),
      ],
    );
  }

  void _showNotification(String message) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        message: Text(message),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
