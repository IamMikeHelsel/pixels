import 'package:flutter/material.dart';
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
    return Scaffold(
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
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
            const Icon(Icons.folder_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No folders found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showAddFolderDialog(context),
              child: const Text('Add Folder'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Scan for Photos'),
              onPressed: () => _showScanOptionsDialog(context),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFolders,
      child: ListView.builder(
        itemCount: _folders.length,
        itemBuilder: (context, index) {
          final folder = _folders[index];
          return _buildFolderListItem(folder, context);
        },
      ),
    );
  }

  Widget _buildFolderListItem(Folder folder, BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.folder),
      title: Text(folder.name),
      subtitle: Text('${folder.photoCount} photos'),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // Navigate to folder photos screen
        // This would be implemented in a real app
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening folder: ${folder.name}')),
        );
      },
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showScanOptionsDialog(context),
      icon: const Icon(Icons.add_photo_alternate),
      label: const Text('Scan Photos'),
      tooltip: 'Scan for photos on your system',
    );
  }

  void _showAddFolderDialog(BuildContext context) {
    final TextEditingController pathController = TextEditingController();
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Folder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pathController,
              decoration: const InputDecoration(
                labelText: 'Folder Path',
                hintText: 'C:/Users/username/Pictures',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name (Optional)',
                hintText: 'My Pictures',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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

                // Refresh the folders list
                _loadFolders();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Folder added successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to add folder: $e')),
                );
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
        return AlertDialog(
          title: const Text('Scan for Photos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Common Photo Locations'),
                subtitle: const Text('Pictures, Downloads, DCIM, etc.'),
                onTap: () {
                  Navigator.pop(context);
                  _scanCommonPhotoLocations();
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.computer),
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
                leading: const Icon(Icons.folder_open),
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
            TextButton(
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Common photo locations scanned')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning photo locations: $e')),
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
      builder: (context) => AlertDialog(
        title: const Text('Warning'),
        content: const Text(
          'Scanning your entire system may take a long time and consume '
          'significant system resources. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('System scan completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning system: $e')),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Folder added: ${path.basename(selectedDirectory)}')),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding folder: $e')),
          );
        }
      }
    }
  }

  void _showScanProgressDialog(String message) {
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
}
