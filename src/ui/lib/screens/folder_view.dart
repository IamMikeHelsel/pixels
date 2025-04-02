import 'package:flutter/material.dart';
import '../models/folder.dart';
import '../models/photo.dart';
import '../services/backend_service.dart';
import 'photo_detail_view.dart';

class FolderView extends StatefulWidget {
  final Folder folder;
  
  const FolderView({
    super.key, 
    required this.folder,
  });

  @override
  State<FolderView> createState() => _FolderViewState();
}

class _FolderViewState extends State<FolderView> {
  final BackendService _backendService = BackendService();
  List<Photo> _photos = [];
  bool _isLoading = true;
  bool _isGridView = true;
  
  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }
  
  Future<void> _loadPhotos() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final photos = await _backendService.getPhotosByFolder(widget.folder.id);
      setState(() {
        _photos = photos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading photos: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder.name),
        actions: [
          // Toggle between grid and list view
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            tooltip: _isGridView ? 'List view' : 'Grid view',
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          // Sort options
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort photos',
            onSelected: (String value) {
              // Implement sorting
              // This would be implemented in a real application
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sorting by $value')),
              );
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'date',
                child: Text('Date taken'),
              ),
              const PopupMenuItem<String>(
                value: 'name',
                child: Text('Name'),
              ),
              const PopupMenuItem<String>(
                value: 'size',
                child: Text('File size'),
              ),
              const PopupMenuItem<String>(
                value: 'rating',
                child: Text('Rating'),
              ),
            ],
          ),
          // Filter options
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter photos',
            onPressed: () {
              // This would open a filter dialog in a real application
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filtering options coming soon')),
              );
            },
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _photos.isEmpty 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('No photos found in ${widget.folder.name}'),
                    ],
                  ),
                )
              : _isGridView 
                  ? _buildGridView() 
                  : _buildListView(),
    );
  }
  
  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1.0,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        return _buildPhotoGridItem(photo);
      },
    );
  }
  
  Widget _buildListView() {
    return ListView.builder(
      itemCount: _photos.length,
      itemBuilder: (context, index) {
        final photo = _photos[index];
        return _buildPhotoListItem(photo);
      },
    );
  }
  
  Widget _buildPhotoGridItem(Photo photo) {
    return GestureDetector(
      onTap: () => _openPhotoDetail(photo),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Photo thumbnail
          Card(
            clipBehavior: Clip.antiAlias,
            child: photo.thumbnailPath != null
                ? FadeInImage.assetNetwork(
                    placeholder: 'assets/placeholder.png',
                    image: photo.thumbnailPath!,
                    fit: BoxFit.cover,
                    imageErrorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.image, size: 48, color: Colors.grey),
                      );
                    },
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
                  ),
          ),
          
          // Favorite indicator
          if (photo.isFavorite)
            const Positioned(
              top: 4,
              right: 4,
              child: Icon(
                Icons.favorite,
                color: Colors.red,
                size: 18,
              ),
            ),
          
          // Rating indicator
          if (photo.rating > 0)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 14,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${photo.rating}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
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
  
  Widget _buildPhotoListItem(Photo photo) {
    return ListTile(
      leading: photo.thumbnailPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: 56,
                height: 56,
                child: FadeInImage.assetNetwork(
                  placeholder: 'assets/placeholder.png',
                  image: photo.thumbnailPath!,
                  fit: BoxFit.cover,
                  imageErrorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.image, size: 24, color: Colors.grey),
                    );
                  },
                ),
              ),
            )
          : Container(
              width: 56,
              height: 56,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.image, size: 24, color: Colors.grey),
              ),
            ),
      title: Text(photo.fileName),
      subtitle: Text(_formatDate(photo.dateTaken)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (photo.isFavorite)
            const Icon(Icons.favorite, color: Colors.red, size: 16),
          if (photo.isFavorite && photo.rating > 0)
            const SizedBox(width: 8),
          if (photo.rating > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 2),
                Text(
                  '${photo.rating}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
        ],
      ),
      onTap: () => _openPhotoDetail(photo),
    );
  }
  
  void _openPhotoDetail(Photo photo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PhotoDetailView(photoId: photo.id),
      ),
    );
  }
  
  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    return date.toLocal().toString().split(' ')[0];
  }
}