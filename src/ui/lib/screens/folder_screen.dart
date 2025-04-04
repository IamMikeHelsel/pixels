import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart'
    show RefreshIndicator, FloatingActionButton;
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../models/folder.dart';
import '../services/backend_service.dart';
import '../services/log_service.dart';
import './folder_photos_screen.dart'; // Added missing import for FolderPhotosScreen

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

    LogService().startProcess('load_folders', 'Loading folders...');

    try {
      final folders = await _backendService.getFolders();
      setState(() {
        _folders = folders;
        _isLoading = false;
      });
      LogService().log('Loaded ${folders.length} folders');
      LogService().endProcess('load_folders',
          finalStatus: 'Loaded ${folders.length} folders');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load folders: $e';
        _isLoading = false;
      });
      LogService().log('Failed to load folders: $e', level: LogLevel.error);
      LogService().endProcess('load_folders', finalStatus: 'Failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ScaffoldPage(
          content: _buildBody(),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: () => _showScanOptionsDialog(context),
            child: const Icon(FluentIcons.add),
          ),
        ),
      ],
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
    return Card(
      key: ValueKey('folder_${folder.id}'),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              FluentPageRoute(
                builder: (context) => FolderPhotosScreen(folder: folder),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(FluentIcons.folder),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name,
                        semanticsLabel: 'Folder name: ${folder.name}',
                      ),
                      Text(
                        '${folder.photoCount} photos',
                        style: FluentTheme.of(context).typography.body,
                        semanticsLabel: '${folder.photoCount} photos in folder',
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'More options',
                  child: FlyoutTarget(
                    controller: FlyoutController(),
                    child: IconButton(
                      icon: const Icon(FluentIcons.more_vertical),
                      onPressed: () {
                        final controller = FlyoutController();
                        // Use the controller directly
                        final controller = controller;
                        controller.showFlyout(
                          builder: (context) {
                            return MenuFlyout(
                              items: [
                                MenuFlyoutItem(
                                  text: const Text('Scan for Photos'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _scanFolder(folder.id);
                                  },
                                ),
                                MenuFlyoutItem(
                                  text: const Text('Remove Folder'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _confirmRemoveFolder(folder);
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _scanFolder(int folderId) async {
    _showScanProgressDialog('Scanning folder...');
    LogService()
        .startProcess('scan_folder_$folderId', 'Scanning folder ID: $folderId');

    try {
      await _backendService.scanFolder(folderId);

      if (mounted) {
        Navigator.of(context).pop(); // close progress dialog
        LogService().endProcess('scan_folder_$folderId',
            finalStatus: 'Folder scan completed');

        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: const Text('Folder scan completed'),
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
        Navigator.of(context).pop(); // close progress dialog
        LogService().log('Error scanning folder: $e', level: LogLevel.error);
        LogService()
            .endProcess('scan_folder_$folderId', finalStatus: 'Failed: $e');

        displayInfoBar(
          context,
          builder: (context, close) {
            return InfoBar(
              title: Text('Error scanning folder: $e'),
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

  void _confirmRemoveFolder(Folder folder) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Remove Folder'),
        content: Text(
            'Are you sure you want to remove "${folder.name}" from the library?\n\n'
            'This will not delete photos from disk, but they will no longer appear in Pixels.'),
        actions: [
          Button(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: ButtonState.all(Colors.red),
            ),
            child: const Text('Remove'),
            onPressed: () async {
              Navigator.of(context).pop();
              await _removeFolder(folder.id);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _removeFolder(int folderId) async {
    try {
      _showProgressDialog('Removing folder...');
      await _backendService.removeFolder(folderId);
      Navigator.of(context).pop(); // close progress dialog
      _loadFolders(); // Refresh the list
    } catch (e) {
      Navigator.of(context).pop(); // close progress dialog
      _showErrorDialog('Failed to remove folder', e.toString());
    }
  }

  void _showProgressDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ContentDialog(
        title: const Text('Please Wait'),
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: ProgressRing(strokeWidth: 3),
            ),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  void _showResultDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          Button(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          Button(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
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
            InfoLabel(
              label: 'Folder Path',
              child: TextBox(
                controller: pathController,
                placeholder: 'C:/Users/username/Pictures',
              ),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Display Name (Optional)',
              child: TextBox(
                controller: nameController,
                placeholder: 'My Pictures',
              ),
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
              Button(
                style: ButtonStyle(
                  padding: ButtonState.all(const EdgeInsets.all(8.0)),
                  backgroundColor: ButtonState.all(Colors.transparent),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _scanCommonPhotoLocations();
                },
                child: Row(
                  children: [
                    const Icon(FluentIcons.photo_collection),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Common Photo Locations'),
                          Text(
                            'Pictures, Downloads, DCIM, etc.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Button(
                style: ButtonStyle(
                  padding: ButtonState.all(const EdgeInsets.all(8.0)),
                  backgroundColor: ButtonState.all(Colors.transparent),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _scanEntireSystem();
                },
                child: Row(
                  children: [
                    const Icon(FluentIcons.device_run),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Entire System'),
                          Text(
                            'Scan all accessible drives (may take time)',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Button(
                style: ButtonStyle(
                  padding: ButtonState.all(const EdgeInsets.all(8.0)),
                  backgroundColor: ButtonState.all(Colors.transparent),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  _selectFoldersToScan();
                },
                child: Row(
                  children: [
                    const Icon(FluentIcons.folder_open),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Select Folders'),
                          Text(
                            'Choose specific folders to scan',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
    LogService().startProcess(
        'scan_common_locations', 'Scanning common photo locations...');

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
            LogService().log('Error adding folder $directory: $e',
                level: LogLevel.error);
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        _loadFolders();
        LogService().endProcess('scan_common_locations',
            finalStatus: 'Completed scanning common locations');

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
        LogService()
            .log('Error scanning photo locations: $e', level: LogLevel.error);
        LogService()
            .endProcess('scan_common_locations', finalStatus: 'Failed: $e');

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
    LogService().startProcess('scan_system', 'Scanning system drives...');

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
            LogService()
                .log('Error adding directory $dir: $e', level: LogLevel.error);
          }
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        _loadFolders();
        LogService()
            .endProcess('scan_system', finalStatus: 'System scan completed');

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
        LogService().log('Error scanning system: $e', level: LogLevel.error);
        LogService().endProcess('scan_system', finalStatus: 'Failed: $e');

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
      LogService().startProcess(
          'select_folder', 'Adding selected folder: $selectedDirectory');

      try {
        await _backendService.addFolder(
          selectedDirectory,
          name: path.basename(selectedDirectory),
          isMonitored: true,
        );

        if (mounted) {
          Navigator.of(context).pop();
          _loadFolders();
          LogService().endProcess('select_folder',
              finalStatus: 'Folder added successfully');

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
          LogService().log('Error adding folder: $e', level: LogLevel.error);
          LogService().endProcess('select_folder', finalStatus: 'Failed: $e');

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
