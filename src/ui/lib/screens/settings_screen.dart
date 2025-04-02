import 'package:flutter/material.dart';
import '../services/backend_service.dart';

class SettingsScreen extends StatefulWidget {
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
        padding: EdgeInsets.all(16.0),
        children: [
          _buildBackendSection(),
          Divider(),
          _buildAppearanceSection(),
          Divider(),
          _buildLibrarySection(),
          Divider(),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildBackendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Backend Connection',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        
        // Connection status
        ListTile(
          leading: Icon(
            _isBackendConnected ? Icons.cloud_done : Icons.cloud_off,
            color: _isBackendConnected ? Colors.green : Colors.red,
          ),
          title: Text('Backend Status'),
          subtitle: Text(
            _isBackendConnected
                ? 'Connected to server'
                : 'Not connected',
          ),
          trailing: _isTestingConnection
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  icon: Icon(Icons.refresh),
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
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(Icons.save),
                onPressed: () {
                  // Save the server URL
                  _backendService.baseUrl = _serverUrlController.text;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Server URL updated')),
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
                icon: Icon(Icons.play_arrow),
                label: Text('Start Backend'),
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
                icon: Icon(Icons.stop),
                label: Text('Stop Backend'),
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
        Text(
          'Appearance',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        
        SwitchListTile(
          title: Text('Dark Mode'),
          subtitle: Text('Use dark theme throughout the app'),
          value: _isDarkMode,
          onChanged: (value) {
            setState(() {
              _isDarkMode = value;
            });
            // In a real app, this would update the app's theme
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Theme preference saved')),
            );
          },
        ),
        
        ListTile(
          title: Text('Thumbnail Size'),
          subtitle: Text('Medium'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Would open a dialog to select thumbnail size
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Thumbnail size settings coming soon')),
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
        Text(
          'Library',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        
        SwitchListTile(
          title: Text('Auto-import New Photos'),
          subtitle: Text('Automatically import photos added to monitored folders'),
          value: _autoImportEnabled,
          onChanged: (value) {
            setState(() {
              _autoImportEnabled = value;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value
                      ? 'Auto-import enabled'
                      : 'Auto-import disabled',
                ),
              ),
            );
          },
        ),
        
        ListTile(
          title: Text('Manage Monitored Folders'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Would navigate to folder management screen
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Folder management coming soon')),
            );
          },
        ),
        
        ListTile(
          title: Text('Re-index Library'),
          trailing: Icon(Icons.refresh),
          onTap: () {
            // Would trigger a re-index operation
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Library re-indexing coming soon')),
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
        Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        
        ListTile(
          title: Text('Version'),
          subtitle: Text('Pixels v1.0.0'),
        ),
        
        ListTile(
          title: Text('View Documentation'),
          trailing: Icon(Icons.open_in_new),
          onTap: () {
            // Would open documentation
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Documentation coming soon')),
            );
          },
        ),
        
        ListTile(
          title: Text('Open Source Licenses'),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Would show open source licenses
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Licenses info coming soon')),
            );
          },
        ),
      ],
    );
  }
}