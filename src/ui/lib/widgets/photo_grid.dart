import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/photo.dart';
import '../services/backend_service.dart';

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
        child: Text('No photos found'),
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
              // Photo thumbnail
              CachedNetworkImage(
                imageUrl: backendService.getThumbnailUrl(photo.id),
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.grey,
                  ),
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
