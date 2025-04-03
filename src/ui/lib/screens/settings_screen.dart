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
      header: PageHeader(
        title: const Text('Settings', style: TextStyle(fontSize: 24)),
      ),
      content: ListView(
        padding: const EdgeInsets.all(16),
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
        _buildSectionHeader('Backend Connection', context),

        // Connection status
        ListTile(
          leading: Icon(
            _isBackendConnected
                ? FluentIcons.cloud_download
                : FluentIcons.error,
            color: _isBackendConnected ? Colors.green : Colors.red,
          ),
          title: const Text('Backend Status', style: TextStyle(fontSize: 14)),
          subtitle: Text(
            _isBackendConnected ? 'Connected to server' : 'Not connected',
            style: const TextStyle(fontSize: 12),
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
        _buildSettingItem(
          'Server URL',
          TextBox(
            controller: _serverUrlController,
            style: const TextStyle(fontSize: 14),
            placeholder: 'http://localhost:5000/api',
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
          context,
        ),

        // Python Path
        _buildSettingItem(
          'Python Path',
          TextBox(
            controller: _pythonPathController,
            style: const TextStyle(fontSize: 14),
            placeholder: 'C:\\Python311\\python.exe',
            suffix: IconButton(
              icon: const Icon(FluentIcons.check_mark),
              onPressed: () {
                // Save the Python path
                _showNotification(context, 'Python path updated');
              },
            ),
          ),
          context,
        ),

        // Start/stop backend buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton(
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
                child:
                    const Text('Start Backend', style: TextStyle(fontSize: 14)),
              ),
              const SizedBox(width: 16),
              Button(
                style: ButtonStyle(
                  backgroundColor: ButtonState.resolveWith(
                    (states) => states.isDisabled ? Colors.grey : Colors.red,
                  ),
                ),
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
                child:
                    const Text('Stop Backend', style: TextStyle(fontSize: 14)),
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
        _buildSectionHeader('Appearance', context),
        ListTile(
          title: const Text('Dark Mode', style: TextStyle(fontSize: 14)),
          subtitle: const Text('Use dark theme throughout the app',
              style: TextStyle(fontSize: 12)),
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
        Button(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Thumbnail Size', style: TextStyle(fontSize: 14)),
                    Text(
                      'Medium',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(FluentIcons.chevron_right),
            ],
          ),
          onPressed: () {
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
        _buildSectionHeader('Library', context),
        ListTile(
          title: const Text('Auto-import New Photos',
              style: TextStyle(fontSize: 14)),
          subtitle: const Text(
              'Automatically import photos added to monitored folders',
              style: TextStyle(fontSize: 12)),
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
        Button(
          child: Row(
            children: [
              Expanded(
                child: const Text('Manage Monitored Folders',
                    style: TextStyle(fontSize: 14)),
              ),
              const Icon(FluentIcons.chevron_right),
            ],
          ),
          onPressed: () {
            // Would navigate to folder management screen
            _showNotification(context, 'Folder management coming soon');
          },
        ),
        Button(
          child: Row(
            children: [
              Expanded(
                child: const Text('Re-index Library',
                    style: TextStyle(fontSize: 14)),
              ),
              const Icon(FluentIcons.refresh),
            ],
          ),
          onPressed: () {
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
        _buildSectionHeader('About', context),
        const ListTile(
          title: Text('Version', style: TextStyle(fontSize: 14)),
          subtitle: Text('Pixels v1.0.0', style: TextStyle(fontSize: 12)),
        ),
        Button(
          child: Row(
            children: [
              Expanded(
                child: const Text('View Documentation',
                    style: TextStyle(fontSize: 14)),
              ),
              const Icon(FluentIcons.document),
            ],
          ),
          onPressed: () {
            // Would open documentation
            _showNotification(context, 'Documentation coming soon');
          },
        ),
        Button(
          child: Row(
            children: [
              Expanded(
                child: const Text('Open Source Licenses',
                    style: TextStyle(fontSize: 14)),
              ),
              const Icon(FluentIcons.chevron_right),
            ],
          ),
          onPressed: () {
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
          title: Text(message, style: const TextStyle(fontSize: 14)),
          action: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: close,
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingItem(String label, Widget control, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Expanded(
            flex: 3,
            child: control,
          ),
        ],
      ),
    );
  }
}
