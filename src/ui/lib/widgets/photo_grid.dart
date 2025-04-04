import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/photo.dart';
import '../services/backend_service.dart';
import '../services/log_service.dart';

/// A widget that displays photos in a grid layout
class PhotoGrid extends StatelessWidget {
  /// The list of photos to display
  final List<Photo> photos;

  /// Service for interacting with the backend API
  final BackendService backendService;

  /// The number of columns in the grid
  final int crossAxisCount;

  /// The aspect ratio of each photo in the grid
  final double childAspectRatio;

  /// Callback when a photo is tapped
  final Function(Photo photo)? onPhotoTap;

  /// Callback when a photo is long-pressed
  final Function(Photo photo)? onPhotoLongPress;

  /// Whether to show the photo rating
  final bool showRating;

  /// Whether to show favorite indicators
  final bool showFavorite;

  /// Creates a new photo grid
  const PhotoGrid({
    super.key,
    required this.photos,
    required this.backendService,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.0,
    this.onPhotoTap,
    this.onPhotoLongPress,
    this.showRating = false,
    this.showFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No photos found', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];

        return GestureDetector(
          onTap: onPhotoTap != null ? () => onPhotoTap!(photo) : null,
          onLongPress:
              onPhotoLongPress != null ? () => onPhotoLongPress!(photo) : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo thumbnail with improved error handling
              Hero(
                tag: 'photo_${photo.id}',
                child: CachedNetworkImage(
                  imageUrl:
                      backendService.getThumbnailUrl(photo.id, large: true),
                  fit: BoxFit.cover,
                  memCacheWidth: 300, // Optimize memory usage
                  fadeInDuration: const Duration(milliseconds: 200),
                  maxWidthDiskCache: 800,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    LogService().log(
                      'Error loading thumbnail for photo ${photo.id}: $error',
                      level: LogLevel.error,
                    );
                    return Container(
                      color: Colors.grey[300],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.broken_image,
                            size: 32,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Failed to load',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[700]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Optional rating indicator at the bottom-left
              if (showRating && (photo.rating ?? 0) > 0)
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        photo.rating ?? 0,
                        (i) => const Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ),
                ),

              // Optional favorite indicator at the top-right
              if (showFavorite && photo.isFavorite)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 16,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
