import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../services/backend_service.dart';

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
}
