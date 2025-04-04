import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:io' show Directory;

import '../models/folder.dart';
import '../services/backend_service.dart';

/// A widget that displays a folder browser with hierarchical navigation
class FolderBrowser extends StatefulWidget {
  /// Service for interacting with the backend API
  final BackendService backendService;

  /// Function called when a folder is selected
  final Function(Folder folder) onFolderSelected;

  /// Currently selected folder ID
  final int? selectedFolderId;

  /// Creates a new folder browser widget
  const FolderBrowser({
    super.key,
    required this.backendService,
    required this.onFolderSelected,
    this.selectedFolderId,
  });

  @override
  State<FolderBrowser> createState() => _FolderBrowserState();
}

class _FolderBrowserState extends State<FolderBrowser> {
  final Set<int> _expandedFolderIds = {};

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Folder>>(
      future: widget.backendService.getFolders(hierarchy: true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading folders: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_outlined,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No folders found. Add a folder to get started.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _showAddFolderDialog(context);
                    },
                    child: const Text('Add Folder'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            return _buildFolderItem(context, snapshot.data![index]);
          },
        );
      },
    );
  }

  Widget _buildFolderItem(BuildContext context, Folder folder,
      {int level = 0}) {
    final isSelected = folder.id == widget.selectedFolderId;
    final hasChildren = folder.children != null && folder.children!.isNotEmpty;
    final isExpanded = _expandedFolderIds.contains(folder.id);

    final folderWidget = Card(
      elevation: isSelected ? 2 : 0,
      margin: EdgeInsets.only(
        left: level * 16.0,
        top: 2,
        bottom: 2,
        right: 4,
      ),
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        dense: level > 0,
        leading: Icon(
          hasChildren
              ? (isExpanded ? Icons.folder_open : Icons.folder)
              : Icons.folder_outlined,
          color: isSelected ? Theme.of(context).primaryColor : Colors.amber,
        ),
        title: Text(
          folder.name,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          '${folder.photoCount} photos',
          style: const TextStyle(fontSize: 12),
        ),
        selected: isSelected,
        onTap: () => widget.onFolderSelected(folder),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (folder.isMonitored)
              Tooltip(
                message: 'This folder is being monitored for changes',
                child: const Icon(Icons.sync, size: 16, color: Colors.green),
              ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                folder.photoCount.toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            if (hasChildren) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedFolderIds.remove(folder.id);
                    } else {
                      _expandedFolderIds.add(folder.id);
                    }
                  });
                },
                child: Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (!hasChildren || !isExpanded) {
      return folderWidget;
    }

    final children = <Widget>[folderWidget];

    for (final childFolder in folder.children!) {
      children.add(_buildFolderItem(context, childFolder, level: level + 1));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  void _showAddFolderDialog(BuildContext context) {
    final pathController = TextEditingController();
    final nameController = TextEditingController();
    var isMonitored = false;
    String? pathError;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void validatePath() {
              final path = pathController.text;
              if (path.isEmpty) {
                setState(() => pathError = 'Folder path is required');
              } else {
                final directory = Directory(path);
                if (!directory.existsSync()) {
                  setState(() => pathError = 'Directory does not exist');
                } else {
                  setState(() => pathError = null);
                }
              }
            }

            return AlertDialog(
              title: const Text('Add Folder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: pathController,
                          decoration: InputDecoration(
                            labelText: 'Folder Path',
                            hintText: '/path/to/photos',
                            errorText: pathError,
                          ),
                          onChanged: (_) {
                            if (pathError != null) validatePath();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.folder_open),
                        tooltip: 'Browse for folder',
                        onPressed: () async {
                          try {
                            String? selectedDirectory =
                                await FilePicker.platform.getDirectoryPath();
                            if (selectedDirectory != null) {
                              // Validate directory is accessible
                              final directory = Directory(selectedDirectory);
                              if (!await directory.exists()) {
                                if (!mounted) return;
                                displayInfoBar(
                                  context,
                                  builder: (context, close) {
                                    return InfoBar(
                                      title: const Text('Invalid directory'),
                                      content: const Text(
                                          'The selected directory does not exist or is not accessible.'),
                                      severity: InfoBarSeverity.error,
                                      action: IconButton(
                                        icon: const Icon(FluentIcons.clear),
                                        onPressed: close,
                                      ),
                                    );
                                  },
                                );
                                return;
                              }

                              if (!mounted) return;
                              setState(() {
                                pathController.text = selectedDirectory;
                                if (nameController.text.isEmpty) {
                                  nameController.text =
                                      path.basename(selectedDirectory);
                                }
                                pathError = null;
                              });
                            }
                          } catch (e) {
                            if (!mounted) return;
                            displayInfoBar(
                              context,
                              builder: (context, close) {
                                return InfoBar(
                                  title: Text('Error selecting directory: $e'),
                                  severity: InfoBarSeverity.error,
                                  action: IconButton(
                                    icon: const Icon(FluentIcons.clear),
                                    onPressed: close,
                                  ),
                                );
                              },
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name (Optional)',
                      hintText: 'My Photos',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Monitor for changes'),
                    subtitle: const Text('Automatically detect new photos'),
                    value: isMonitored,
                    onChanged: (value) {
                      setState(() => isMonitored = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    validatePath();
                    if (pathError != null) return;

                    try {
                      final folderId = await widget.backendService.addFolder(
                        pathController.text,
                        name: nameController.text.isNotEmpty
                            ? nameController.text
                            : null,
                        isMonitored: isMonitored,
                      );

                      if (context.mounted) {
                        Navigator.of(context).pop();

                        final folders =
                            await widget.backendService.getFolders();
                        final newFolder =
                            folders.firstWhere((f) => f.id == folderId);
                        widget.onFolderSelected(newFolder);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error adding folder: $e'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                            action: SnackBarAction(
                              label: 'DISMISS',
                              textColor: Colors.white,
                              onPressed: () {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                              },
                            ),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
