import 'package:fluent_ui/fluent_ui.dart';
import '../models/folder.dart';
import '../models/photo.dart';
import '../services/backend_service.dart';
import 'photo_edit_screen.dart';

class FolderPhotosScreen extends StatefulWidget {
  final Folder folder;

  const FolderPhotosScreen({super.key, required this.folder});

  @override
  _FolderPhotosScreenState createState() => _FolderPhotosScreenState();
}

class _FolderPhotosScreenState extends State<FolderPhotosScreen> {
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
        folderIds: [widget.folder.id],
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
        title: Text(widget.folder.name),
        commandBar: CommandBar(
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Refresh'),
              onPressed: _loadPhotos,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.back),
              label: const Text('Back'),
              onPressed: () => Navigator.pop(context),
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
            Icon(FluentIcons.photo, size: 64, color: Colors.grey[100]),
            const SizedBox(height: 16),
            Text(
              'No photos found in this folder',
              style: FluentTheme.of(context).typography.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Photos might still be indexing or this folder contains no images',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Button(
              onPressed: _loadPhotos,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        children: _photos.map((photo) => _buildPhotoThumbnail(photo)).toList(),
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
                  color: Colors.grey.withOpacity(0.3),
                  child: Center(
                    child: Icon(
                      FluentIcons.picture,
                      size: 32,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
              loadingBuilder: (ctx, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey.withOpacity(0.3),
                  child: const Center(child: ProgressRing(strokeWidth: 2)),
                );
              },
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                FluentPageRoute(
                  builder: (context) => PhotoEditScreen(photo: photo),
                ),
              );
            },
          ),
          if (photo.isFavorite)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  FluentIcons.favorite_star_fill,
                  size: 16,
                  color: Colors.yellow,
                ),
              ),
            ),
          if (photo.rating != null && photo.rating! > 0)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      FluentIcons.favorite_star_fill,
                      size: 12,
                      color: Colors.yellow,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${photo.rating}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
