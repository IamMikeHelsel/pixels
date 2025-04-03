import 'package:flutter/material.dart';
import '../models/photo.dart';
import '../services/backend_service.dart';

class PhotoDetailView extends StatefulWidget {
  final int photoId;

  const PhotoDetailView({
    super.key,
    required this.photoId,
  });

  @override
  State<PhotoDetailView> createState() => _PhotoDetailViewState();
}

class _PhotoDetailViewState extends State<PhotoDetailView> {
  final BackendService _backendService = BackendService();
  Photo? _photo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final photo = await _backendService.getPhoto(widget.photoId);
      setState(() {
        _photo = photo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading photo: $e')),
        );
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_photo == null) return;

    final newFavoriteStatus = !_photo!.isFavorite;

    try {
      final success = await _backendService.updatePhotoFavorite(
          _photo!.id, newFavoriteStatus);

      if (success && mounted) {
        setState(() {
          _photo = _photo!.copyWith(isFavorite: newFavoriteStatus);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating favorite status: $e')),
        );
      }
    }
  }

  Future<void> _updateRating(int rating) async {
    if (_photo == null) return;

    try {
      final success =
          await _backendService.updatePhotoRating(_photo!.id, rating);

      if (success && mounted) {
        setState(() {
          _photo = _photo!.copyWith(rating: rating);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating rating: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            const Text('Pixels - Photo Details',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          if (_photo != null) ...[
            // Favorite toggle
            IconButton(
              icon: Icon(
                _photo!.isFavorite ? Icons.favorite : Icons.favorite_outline,
                color: _photo!.isFavorite ? Colors.red : null,
              ),
              onPressed: _toggleFavorite,
              tooltip: _photo!.isFavorite
                  ? 'Remove from favorites'
                  : 'Add to favorites',
            ),

            // Info button
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                _showPhotoInfo(context);
              },
              tooltip: 'Photo information',
            ),

            // More options
            PopupMenuButton<String>(
              onSelected: (String value) {
                // Handle menu selection
                switch (value) {
                  case 'edit':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Edit functionality coming soon')),
                    );
                    break;
                  case 'share':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Share functionality coming soon')),
                    );
                    break;
                  case 'delete':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Delete functionality coming soon')),
                    );
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Edit'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('Share'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _photo == null
              ? const Center(child: Text('Photo not found'))
              : Column(
                  children: [
                    // Photo Display Area
                    Expanded(
                      child: Center(
                        child: InteractiveViewer(
                          panEnabled: true,
                          boundaryMargin: const EdgeInsets.all(20),
                          minScale: 0.5,
                          maxScale: 4,
                          child: _photo!.thumbnailPath != null
                              ? Image.network(
                                  _photo!.thumbnailPath!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.broken_image,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text('Failed to load image'),
                                      ],
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text('No image available'),
                                      ],
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),

                    // Bottom controls
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, -1),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Star rating
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              return IconButton(
                                icon: Icon(
                                  index < _photo!.rating
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: index < _photo!.rating
                                      ? Colors.amber
                                      : null,
                                ),
                                onPressed: () => _updateRating(index + 1),
                              );
                            }),
                          ),

                          const SizedBox(height: 8),

                          // Quick info row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildInfoChip(
                                icon: Icons.calendar_today,
                                label: _formatDate(_photo!.dateTaken),
                              ),
                              _buildInfoChip(
                                icon: Icons.aspect_ratio,
                                label: '${_photo!.width} × ${_photo!.height}',
                              ),
                              _buildInfoChip(
                                icon: Icons.sd_storage,
                                label: _formatFileSize(_photo!.fileSize),
                              ),
                              _buildInfoChip(
                                icon: Icons.camera_alt,
                                label: _photo!.cameraModel ?? 'Unknown',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  void _showPhotoInfo(BuildContext context) {
    if (_photo == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Photo Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('File name', _photo!.fileName),
              _buildInfoRow('File path', _photo!.filePath),
              _buildInfoRow('Date taken', _formatDate(_photo!.dateTaken)),
              _buildInfoRow('Size', _formatFileSize(_photo!.fileSize)),
              _buildInfoRow(
                  'Dimensions', '${_photo!.width} × ${_photo!.height}'),
              _buildInfoRow('Camera make', _photo!.cameraMake ?? 'Unknown'),
              _buildInfoRow('Camera model', _photo!.cameraModel ?? 'Unknown'),
              _buildInfoRow('Rating', '${_photo!.rating}/5'),
              _buildInfoRow('Favorite', _photo!.isFavorite ? 'Yes' : 'No'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
