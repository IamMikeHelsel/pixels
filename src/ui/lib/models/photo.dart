import 'dart:convert';

class Photo {
  final int id;
  final String fileName;
  final String filePath;
  final String? thumbnailPath;
  final int? width;
  final int? height;
  final DateTime? dateTaken;
  final int? fileSize;
  final String? cameraMake;
  final String? cameraModel;
  final int? rating;
  final bool isFavorite;
  final List<dynamic>? tags;
  final List<dynamic>? albums;

  Photo({
    required this.id,
    required this.fileName,
    required this.filePath,
    this.thumbnailPath,
    this.width,
    this.height,
    this.dateTaken,
    this.fileSize,
    this.cameraMake,
    this.cameraModel,
    this.rating,
    this.isFavorite = false,
    this.tags,
    this.albums,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      fileName: json['file_name'],
      filePath: json['file_path'],
      thumbnailPath: json['thumbnail_path'],
      width: json['width'],
      height: json['height'],
      dateTaken: json['date_taken'] != null
          ? DateTime.parse(json['date_taken'])
          : null,
      fileSize: json['file_size'],
      cameraMake: json['camera_make'],
      cameraModel: json['camera_model'],
      rating: json['rating'],
      isFavorite: json['is_favorite'] == true || json['is_favorite'] == 1,
      tags: json['tags'],
      albums: json['albums'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_path': filePath,
      'thumbnail_path': thumbnailPath,
      'width': width,
      'height': height,
      'date_taken': dateTaken?.toIso8601String(),
      'file_size': fileSize,
      'camera_make': cameraMake,
      'camera_model': cameraModel,
      'rating': rating,
      'is_favorite': isFavorite,
      'tags': tags,
      'albums': albums,
    };
  }
}