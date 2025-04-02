import 'package:flutter/material.dart';

import '../models/folder.dart';
import '../services/backend_service.dart';

/// A widget that displays a folder browser with hierarchical navigation
class FolderBrowser extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return FutureBuilder<List<Folder>>(
      future: backendService.getFolders(hierarchy: true),
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
                      // Force the widget to rebuild and try loading again
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

        // Display the folders in a hierarchical list
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
    final isSelected = folder.id == selectedFolderId;
    final hasChildren = folder.children != null && folder.children!.isNotEmpty;

    // Build this folder's item
    final folderWidget = ListTile(
      leading: Icon(
        hasChildren ? Icons.folder : Icons.folder_outlined,
        color: isSelected ? Theme.of(context).primaryColor : Colors.amber,
      ),
      title: Text(folder.name),
      subtitle: Text(
        '${folder.photoCount} photos',
        style: const TextStyle(fontSize: 12),
      ),
      selected: isSelected,
      onTap: () => onFolderSelected(folder),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (folder.isMonitored)
            const Icon(Icons.sync, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            folder.photoCount.toString(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );

    // If there are no children, just return the folder widget
    if (!hasChildren) {
      return folderWidget;
    }

    // Otherwise, build a list of this folder and its children
    final children = <Widget>[folderWidget];

    // Recursively add child folders with increased indentation
    for (final childFolder in folder.children!) {
      children.add(
        Padding(
          padding: EdgeInsets.only(left: (level + 1) * 16.0),
          child: _buildFolderItem(context, childFolder, level: level + 1),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  void _showAddFolderDialog(BuildContext context) {
    // We'll use a text controller to get the folder path
    final pathController = TextEditingController();
    final nameController = TextEditingController();
    var isMonitored = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Folder'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pathController,
                    decoration: const InputDecoration(
                      labelText: 'Folder Path',
                      hintText: '/path/to/photos',
                    ),
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
                    if (pathController.text.isEmpty) return;

                    try {
                      final folderId = await backendService.addFolder(
                        pathController.text,
                        name: nameController.text.isNotEmpty
                            ? nameController.text
                            : null,
                        isMonitored: isMonitored,
                      );

                      if (context.mounted) {
                        Navigator.of(context).pop();

                        // Get the newly created folder and select it
                        final folders = await backendService.getFolders();
                        final newFolder =
                            folders.firstWhere((f) => f.id == folderId);
                        onFolderSelected(newFolder);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error adding folder: $e')),
                        );
                        Navigator.of(context).pop();
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
