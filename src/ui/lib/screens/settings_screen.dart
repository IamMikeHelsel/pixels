import 'package:fluent_ui/fluent_ui.dart';
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
    return ScaffoldPage(
      padding: const EdgeInsets.all(16.0),
      content: ListView(
        children: [
          _buildBackendSection(context),
          const Divider(),
          _buildAppearanceSection(context),
          const Divider(),
          _buildLibrarySection(context),
          const Divider(),
          _buildAboutSection(context),
        ],
      ),
    );
  }

  Widget _buildBackendSection(BuildContext context) {
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
        ListTile(
          leading: Icon(
            _isBackendConnected
                ? FluentIcons.cloud_download
                : FluentIcons.error_circle,
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
                  child: ProgressRing(strokeWidth: 2),
                )
              : IconButton(
                  icon: const Icon(FluentIcons.refresh),
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
          child: TextBox(
            controller: _serverUrlController,
            placeholder: 'http://localhost:5000/api',
            header: 'Server URL',
            suffix: IconButton(
              icon: const Icon(FluentIcons.check_mark),
              onPressed: () {
                // Save the server URL
                _backendService.baseUrl = _serverUrlController.text;
                _showNotification(context, 'Server URL updated');
                _checkBackendConnection();
              },
            ),
          ),
        ),

        // Python Path
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextBox(
            controller: _pythonPathController,
            placeholder: 'C:\\Python311\\python.exe',
            header: 'Python Path',
            suffix: IconButton(
              icon: const Icon(FluentIcons.check_mark),
              onPressed: () {
                // Save the Python path
                _showNotification(context, 'Python path updated');
              },
            ),
          ),
        ),

        // Start/stop backend buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton(
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
                            _showNotification(
                                context, 'Backend started successfully');
                          } else {
                            _showNotification(
                                context, 'Failed to start backend');
                          }
                        } catch (e) {
                          _showNotification(
                              context, 'Error starting backend: $e');
                        } finally {
                          setState(() {
                            _isTestingConnection = false;
                          });
                        }
                      },
              ),
              const SizedBox(width: 16),
              Button(
                style: ButtonStyle(
                  backgroundColor: ButtonState.resolveWith(
                    (states) => states.isDisabled ? Colors.grey : Colors.red,
                  ),
                ),
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

  Widget _buildAppearanceSection(BuildContext context) {
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
        ListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Use dark theme throughout the app'),
          trailing: ToggleSwitch(
            checked: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
              // In a real app, this would update the app's theme
              _showNotification(context, 'Theme preference saved');
            },
          ),
        ),
        ListTile(
          title: const Text('Thumbnail Size'),
          subtitle: const Text('Medium'),
          trailing: const Icon(FluentIcons.chevron_right),
          onTap: () {
            // Would open a dialog to select thumbnail size
            _showNotification(context, 'Thumbnail size settings coming soon');
          },
        ),
      ],
    );
  }

  Widget _buildLibrarySection(BuildContext context) {
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
        ListTile(
          title: const Text('Auto-import New Photos'),
          subtitle: const Text(
              'Automatically import photos added to monitored folders'),
          trailing: ToggleSwitch(
            checked: _autoImportEnabled,
            onChanged: (value) {
              setState(() {
                _autoImportEnabled = value;
              });
              _showNotification(
                context,
                value ? 'Auto-import enabled' : 'Auto-import disabled',
              );
            },
          ),
        ),
        ListTile(
          title: const Text('Manage Monitored Folders'),
          trailing: const Icon(FluentIcons.chevron_right),
          onTap: () {
            // Would navigate to folder management screen
            _showNotification(context, 'Folder management coming soon');
          },
        ),
        ListTile(
          title: const Text('Re-index Library'),
          trailing: const Icon(FluentIcons.refresh),
          onTap: () {
            // Would trigger a re-index operation
            _showNotification(context, 'Library re-indexing coming soon');
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
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
        const ListTile(
          title: Text('Version'),
          subtitle: Text('Pixels v1.0.0'),
        ),
        ListTile(
          title: const Text('View Documentation'),
          trailing: const Icon(FluentIcons.open),
          onTap: () {
            // Would open documentation
            _showNotification(context, 'Documentation coming soon');
          },
        ),
        ListTile(
          title: const Text('Open Source Licenses'),
          trailing: const Icon(FluentIcons.chevron_right),
          onTap: () {
            // Would show open source licenses
            _showNotification(context, 'Licenses info coming soon');
          },
        ),
      ],
    );
  }

  void _showNotification(BuildContext context, String message) {
    displayInfoBar(
      context,
      builder: (context, close) {
        return InfoBar(
          title: Text(message),
          action: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: close,
          ),
        );
      },
    );
  }
}
