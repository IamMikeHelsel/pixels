import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material
    show
        GridView,
        SliverGridDelegateWithFixedCrossAxisCount,
        FloatingActionButton,
        Material,
        InkWell,
        Colors;
import '../models/album.dart';
import '../models/photo.dart';
import '../services/backend_service.dart';
import 'photo_edit_screen.dart';

class AlbumDetailScreen extends StatefulWidget {
  final Album album;

  const AlbumDetailScreen({super.key, required this.album});

  @override
  _AlbumDetailScreenState createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends State<AlbumDetailScreen> {
  final BackendService _backendService = BackendService();
  List<Photo> _photos = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final photos = await _backendService.searchPhotos(
        albumId: widget.album.id,
        limit: 1000, // Increased limit to show more photos
      );
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load photos: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Text(widget.album.name),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Refresh'),
              onPressed: _loadPhotos,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.add),
              label: const Text('Add Photos'),
              onPressed: _showAddPhotosDialog,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.edit),
              label: const Text('Edit Album'),
              onPressed: () => _showEditAlbumDialog(context),
            ),
          ],
        ),
      ),
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
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
              onPressed: _loadPhotos,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FluentIcons.photo, size: 64, color: material.Colors.grey[100]),
            const SizedBox(height: 16),
            Text(
              'No photos in this album',
              style: FluentTheme.of(context).typography.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Add photos to this album to see them here',
              style: const TextStyle(fontSize: 12, color: material.Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _showAddPhotosDialog,
              child: const Text('Add Photos'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: material.GridView.builder(
        gridDelegate: const material.SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: _photos.length,
        itemBuilder: (context, index) {
          final photo = _photos[index];
          return _buildPhotoThumbnail(photo);
        },
      ),
    );
  }

  Widget _buildPhotoThumbnail(Photo photo) {
    return Card(
      padding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              _backendService.getThumbnailUrl(photo.id),
              fit: BoxFit.cover,
              errorBuilder: (ctx, error, stackTrace) {
                return Container(
                  color: material.Colors.grey[30],
                  child: Center(
                    child: Icon(
                      FluentIcons.picture,
                      size: 32,
                      color: material.Colors.grey[100],
                    ),
                  ),
                );
              },
              loadingBuilder: (ctx, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: material.Colors.grey[30],
                  child: const Center(child: ProgressRing(strokeWidth: 2)),
                );
              },
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Button(
              style: ButtonStyle(
                backgroundColor:
                    ButtonState.all(material.Colors.black.withOpacity(0.6)),
                padding: ButtonState.all(const EdgeInsets.all(4)),
                iconSize: ButtonState.all(12),
              ),
              onPressed: () => _removePhotoFromAlbum(photo),
              child: const Icon(
                FluentIcons.remove,
                color: material.Colors.white,
                size: 12,
              ),
            ),
          ),
          material.Material(
            color: material.Colors.transparent,
            child: material.InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  FluentPageRoute(
                    builder: (context) => PhotoEditScreen(photo: photo),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEditAlbumDialog(BuildContext context) {
    final TextEditingController nameController =
        TextEditingController(text: widget.album.name);
    final TextEditingController descriptionController =
        TextEditingController(text: widget.album.description);

    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Edit Album'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InfoLabel(
              label: 'Album Name',
              child: TextBox(
                controller: nameController,
                placeholder: 'My Vacation',
              ),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Description (Optional)',
              child: TextBox(
                controller: descriptionController,
                placeholder: 'Photos from my summer vacation',
                maxLines: 3,
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
              final name = nameController.text.trim();
              if (name.isEmpty) return;

              Navigator.of(context).pop();

              try {
                // TODO: Implement update album API call
                displayInfoBar(
                  context,
                  builder: (context, close) {
                    return InfoBar(
                      title: const Text('Album updated successfully'),
                      severity: InfoBarSeverity.success,
                      action: IconButton(
                        icon: const Icon(FluentIcons.clear),
                        onPressed: close,
                      ),
                    );
                  },
                );
              } catch (e) {
                displayInfoBar(
                  context,
                  builder: (context, close) {
                    return InfoBar(
                      title: Text('Failed to update album: $e'),
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
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddPhotosDialog() {
    // In a real app, this would show a photo picker
    // For now, just show a notification
    displayInfoBar(
      context,
      builder: (context, close) {
        return InfoBar(
          title: const Text('Photo selection not implemented yet'),
          content: const Text(
              'This functionality will be available in a future update.'),
          action: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: close,
          ),
        );
      },
    );
  }

  Future<void> _removePhotoFromAlbum(Photo photo) async {
    // Confirm removal
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Remove Photo from Album'),
        content: const Text(
            'Are you sure you want to remove this photo from the album? This won\'t delete the photo from your library.'),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ButtonStyle(
              backgroundColor: ButtonState.all(material.Colors.red),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      // TODO: Implement API call for removing photo from album

      // Update UI to remove the photo
      setState(() {
        _photos.removeWhere((p) => p.id == photo.id);
      });

      displayInfoBar(
        context,
        builder: (context, close) {
          return InfoBar(
            title: const Text('Photo removed from album'),
            severity: InfoBarSeverity.success,
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
          );
        },
      );
    } catch (e) {
      displayInfoBar(
        context,
        builder: (context, close) {
          return InfoBar(
            title: Text('Failed to remove photo: $e'),
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
