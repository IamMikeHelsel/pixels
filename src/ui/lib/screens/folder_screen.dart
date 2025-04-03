import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show RefreshIndicator;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/folder.dart';
import '../services/backend_service.dart';
import '../widgets/folder_browser.dart';

class FolderScreen extends StatefulWidget {
  const FolderScreen({super.key});

  @override
  _FolderScreenState createState() => _FolderScreenState();
}

class _FolderScreenState extends State<FolderScreen> {
  final BackendService _backendService = BackendService();
  List<Folder> _folders = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final folders = await _backendService.getFolders();
      setState(() {
        _folders = folders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load folders: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: ProgressRing());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            Button(
              onPressed: _loadFolders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_folders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FluentIcons.folder, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No folders found'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _showAddFolderDialog(context),
              child: const Text('Add Folder'),
            ),
            const SizedBox(height: 8),
            Button(
              onPressed: () => _showScanOptionsDialog(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(FluentIcons.search),
                  SizedBox(width: 8),
                  Text('Scan for Photos'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _folders.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Button(
              onPressed: _loadFolders,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(FluentIcons.refresh),
                  SizedBox(width: 8),
                  Text('Refresh Folders'),
                ],
              ),
            ),
          );
        }

        final folder = _folders[index - 1];
        return _buildFolderListItem(folder, context);
      },
    );
  }

  Widget _buildFolderListItem(Folder folder, BuildContext context) {
    return ListTile(
      leading: const Icon(FluentIcons.folder),
      title: Text(folder.name),
      subtitle: Text('${folder.photoCount} photos'),
      trailing: const Icon(FluentIcons.chevron_right, size: 16),
      onTap: () {
        final currentContext = context;

        Future.microtask(() {
          if (mounted) {
            displayInfoBar(
              currentContext,
              builder: (context, close) {
                return InfoBar(
                  title: Text('Opening folder: ${folder.name}'),
                  action: IconButton(
                    icon: const Icon(FluentIcons.clear),
                    onPressed: close,
                  ),
                );
              },
            );
          }
        });
      },
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showScanOptionsDialog(context),
      child: const Icon(FluentIcons.add_photo),
    );
  }

  void _showAddFolderDialog(BuildContext context) {
    final TextEditingController pathController = TextEditingController();
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Add Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextBox(
              controller: pathController,
              placeholder: 'C:/Users/username/Pictures',
              header: 'Folder Path',
            ),
            const SizedBox(height: 8),
            TextBox(
              controller: nameController,
              placeholder: 'My Pictures',
              header: 'Display Name (Optional)',
            ),
          ],
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final path = pathController.text.trim();
              final name = nameController.text.trim();

              if (path.isEmpty) {
                return;
              }

              Navigator.of(context).pop();

              try {
                await _backendService.addFolder(
                  path,
                  name: name.isNotEmpty ? name : null,
                  isMonitored: true,
                );

                _loadFolders();

                if (mounted) {
                  displayInfoBar(
                    context,
                    builder: (context, close) {
                      return InfoBar(
                        title: const Text('Folder added successfully'),
                        severity: InfoBarSeverity.success,
                        action: IconButton(
                          icon: const Icon(FluentIcons.clear),
                          onPressed: close,
                        ),
                      );
                    },
                  );
                }
              } catch (e) {
                if (mounted) {
                  displayInfoBar(
                    context,
                    builder: (context, close) {
                      return InfoBar(
                        title: Text('Failed to add folder: $e'),
                        severity: InfoBarSeverity.error,
                        action: IconButton(
                          icon: const Icon(FluentIcons.clear),
                          onPressed: close,
                        ),
                      );
                    },
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showScanOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ContentDialog(
          title: const Text('Scan for Photos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(FluentIcons.photo_collection),
                title: const Text('Common Photo Locations'),
                subtitle: const Text('Pictures, Downloads, DCIM, etc.'),
                onTap: () {
                  Navigator.pop(context);
                  _scanCommonPhotoLocations();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(FluentIcons.device_run),
                title: const Text('Entire System'),
                subtitle:
                    const Text('Scan all accessible drives (may take time)'),
                onTap: () {
                  Navigator.pop(context);
                  _scanEntireSystem();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(FluentIcons.folder_open),
                title: const Text('Select Folders'),
                subtitle: const Text('Choose specific folders to scan'),
                onTap: () {
                  Navigator.pop(context);
                  _selectFoldersToScan();
                },
              ),
            ],
          ),
          actions: [
            Button(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _scanCommonPhotoLocations() async {
    _showScanProgressDialog('Scanning common photo locations...');

    final List<String> commonDirectories = _getCommonPhotoDirectories();

    try {
      for (final directory in commonDirectories) {
        if (Directory(directory).existsSync()) {
          try {
            await _backendService.addFolder(
              directory,
              name: path.basename(directory),
              isMonitored: true,
            );
          } catch (e) {
            print('Error adding folder $directory: $e');
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        _loadFolders();

        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Common photo locations scanned'),
              severity: InfoBarSeverity.success,
              action: IconButton(
                icon: const Icon(FluentIcons.clear),
                onPressed: close,
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();

        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: Text('Error scanning photo locations: $e'),
              severity: InfoBarSeverity.error,
              action: IconButton(
                icon: const Icon(FluentIcons.clear),
                onPressed: close,
              ),
            );
          },
        );
      }
    }
  }

  List<String> _getCommonPhotoDirectories() {
    final List<String> directories = [];

    final String? homeDir =
        Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];

    if (homeDir != null) {
      if (Platform.isWindows) {
        directories.add(path.join(homeDir, 'Pictures'));
        directories.add(path.join(homeDir, 'Downloads'));
        directories.add(path.join(homeDir, 'OneDrive', 'Pictures'));
        directories.add(path.join(homeDir, 'Documents', 'My Pictures'));
      } else if (Platform.isMacOS) {
        directories.add(path.join(homeDir, 'Pictures'));
        directories.add(path.join(homeDir, 'Downloads'));
        directories.add(path.join(homeDir, 'Photos Library.photoslibrary'));
      } else if (Platform.isLinux) {
        directories.add(path.join(homeDir, 'Pictures'));
        directories.add(path.join(homeDir, 'Downloads'));
        directories.add(path.join(homeDir, 'Photos'));
      }
    }

    return directories;
  }

  Future<void> _scanEntireSystem() async {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Warning'),
        content: const Text(
          'Scanning your entire system may take a long time and consume '
          'significant system resources. Do you want to continue?',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performFullSystemScan();
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _performFullSystemScan() async {
    _showScanProgressDialog('Scanning system drives...');

    try {
      final List<String> rootDirs = _getRootDirectories();

      for (final dir in rootDirs) {
        if (Directory(dir).existsSync()) {
          try {
            await _backendService.addFolder(
              dir,
              name: 'Drive ${path.basename(dir)}',
              isMonitored: true,
            );
          } catch (e) {
            print('Error adding directory $dir: $e');
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        _loadFolders();

        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('System scan completed'),
              severity: InfoBarSeverity.success,
              action: IconButton(
                icon: const Icon(FluentIcons.clear),
                onPressed: close,
              ),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();

        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: Text('Error scanning system: $e'),
              severity: InfoBarSeverity.error,
              action: IconButton(
                icon: const Icon(FluentIcons.clear),
                onPressed: close,
              ),
            );
          },
        );
      }
    }
  }

  List<String> _getRootDirectories() {
    final List<String> directories = [];

    if (Platform.isWindows) {
      for (var letter in 'CDEFGHIJKLMNOPQRSTUVWXYZ'.split('')) {
        final drive = '$letter:\\';
        if (Directory(drive).existsSync()) {
          directories.add(drive);
        }
      }
    } else {
      directories.add('/');
    }

    return directories;
  }

  Future<void> _selectFoldersToScan() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select a folder to scan for photos',
    );

    if (selectedDirectory != null) {
      _showScanProgressDialog('Adding selected folder...');

      try {
        await _backendService.addFolder(
          selectedDirectory,
          name: path.basename(selectedDirectory),
          isMonitored: true,
        );

        if (mounted) {
          Navigator.of(context).pop();
          _loadFolders();

          displayInfoBar(
            context,
            builder: (context, close) {
              return InfoBar(
                title:
                    Text('Folder added: ${path.basename(selectedDirectory)}'),
                severity: InfoBarSeverity.success,
                action: IconButton(
                  icon: const Icon(FluentIcons.clear),
                  onPressed: close,
                ),
              );
            },
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();

          displayInfoBar(
            context,
            builder: (context, close) {
              return InfoBar(
                title: Text('Error adding folder: $e'),
                severity: InfoBarSeverity.error,
                action: IconButton(
                  icon: const Icon(FluentIcons.clear),
                  onPressed: close,
                ),
              );
            },
          );
        }
      }
    }
  }

  void _showScanProgressDialog(String message) {
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
}
