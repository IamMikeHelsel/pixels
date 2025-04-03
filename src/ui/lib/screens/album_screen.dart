import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart'
    show
        GridView,
        SliverGridDelegateWithFixedCrossAxisCount,
        FloatingActionButton;
import '../models/album.dart';
import '../services/backend_service.dart';
import 'album_detail_screen.dart';

class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  _AlbumScreenState createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  final BackendService _backendService = BackendService();
  List<Album> _albums = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final albums = await _backendService.getAlbums();
      setState(() {
        _albums = albums;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load albums: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ScaffoldPage(
          content: _buildContent(),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            child: const Icon(FluentIcons.add),
            onPressed: () => _showCreateAlbumDialog(context),
          ),
        ),
      ],
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
              onPressed: _loadAlbums,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_albums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(FluentIcons.photo_collection,
                size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No albums found'),
            const SizedBox(height: 16),
            FilledButton(
              child: const Text('Create New Album'),
              onPressed: () => _showCreateAlbumDialog(context),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Button(
                onPressed: _loadAlbums,
                child: Row(
                  children: const [
                    Icon(FluentIcons.refresh),
                    SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _albums.length,
            itemBuilder: (context, index) {
              final album = _albums[index];
              return _buildAlbumCard(album, context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumCard(Album album, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to album detail screen
        Navigator.push(
          context,
          FluentPageRoute(
            builder: (context) => AlbumDetailScreen(album: album),
          ),
        );
      },
      child: Card(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[30],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Icon(
                    FluentIcons.photo_collection,
                    size: 48,
                    color: Colors.grey[100],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${album.photoCount} photos',
              style: TextStyle(
                color: Colors.grey[130],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateAlbumDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Create Album'),
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
              final description = descriptionController.text.trim();

              if (name.isEmpty) {
                return;
              }

              Navigator.of(context).pop();

              try {
                await _backendService.createAlbum(
                  name,
                  description: description,
                );

                // Refresh the albums list
                _loadAlbums();

                displayInfoBar(
                  context,
                  builder: (context, close) {
                    return InfoBar(
                      title: const Text('Album created successfully'),
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
                      title: Text('Failed to create album: $e'),
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
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
