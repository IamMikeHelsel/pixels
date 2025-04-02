import 'package:flutter/material.dart';
import '../services/backend_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final BackendService _backendService = BackendService();
  final TextEditingController _serverUrlController = TextEditingController();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
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
    );
  }

  Widget _buildBackendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Backend Connection',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Connection status
        ListTile(
          leading: Icon(
            _isBackendConnected ? Icons.cloud_done : Icons.cloud_off,
            color: _isBackendConnected ? Colors.green : Colors.red,
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
              : IconButton(
                  icon: const Icon(Icons.refresh),
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
          child: TextField(
            controller: _serverUrlController,
            decoration: InputDecoration(
              labelText: 'Server URL',
              hintText: 'http://localhost:5000/api',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.save),
                onPressed: () {
                  // Save the server URL
                  _backendService.baseUrl = _serverUrlController.text;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Server URL updated')),
                  );
                  _checkBackendConnection();
                },
              ),
            ),
          ),
        ),

        // Start/stop backend buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Backend'),
                onPressed: _isBackendConnected
                    ? null
                    : () async {
                        setState(() {
                          _isTestingConnection = true;
                        });
                        await _backendService.startBackend();
                        await _checkBackendConnection();
                        setState(() {
                          _isTestingConnection = false;
                        });
                      },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.stop),
                label: const Text('Stop Backend'),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
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
        const Text(
          'Appearance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Use dark theme throughout the app'),
          value: _isDarkMode,
          onChanged: (value) {
            setState(() {
              _isDarkMode = value;
            });
            // In a real app, this would update the app's theme
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Theme preference saved')),
            );
          },
        ),
        ListTile(
          title: const Text('Thumbnail Size'),
          subtitle: const Text('Medium'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Would open a dialog to select thumbnail size
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Thumbnail size settings coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLibrarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Library',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          title: const Text('Auto-import New Photos'),
          subtitle: const Text(
              'Automatically import photos added to monitored folders'),
          value: _autoImportEnabled,
          onChanged: (value) {
            setState(() {
              _autoImportEnabled = value;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value ? 'Auto-import enabled' : 'Auto-import disabled',
                ),
              ),
            );
          },
        ),
        ListTile(
          title: const Text('Manage Monitored Folders'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Would navigate to folder management screen
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Folder management coming soon')),
            );
          },
        ),
        ListTile(
          title: const Text('Re-index Library'),
          trailing: const Icon(Icons.refresh),
          onTap: () {
            // Would trigger a re-index operation
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Library re-indexing coming soon')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const ListTile(
          title: Text('Version'),
          subtitle: Text('Pixels v1.0.0'),
        ),
        ListTile(
          title: const Text('View Documentation'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () {
            // Would open documentation
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Documentation coming soon')),
            );
          },
        ),
        ListTile(
          title: const Text('Open Source Licenses'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Would show open source licenses
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Licenses info coming soon')),
            );
          },
        ),
      ],
    );
  }
}
