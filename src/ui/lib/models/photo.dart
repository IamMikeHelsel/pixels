import 'album.dart';
import 'tag.dart';

/// Model class representing a photo in the Pixels application
class Photo {
  /// Unique identifier for the photo
  final int id;

  /// Name of the photo file
  final String fileName;

  /// Full path to the photo file
  final String filePath;

  /// The ID of the folder containing this photo
  final int folderId;

  /// Size of the photo file in bytes
  final int? fileSize;

  /// Width of the photo in pixels
  final int? width;

  /// Height of the photo in pixels
  final int? height;

  /// Date and time when the photo was taken
  final DateTime? dateTaken;

  /// Make of the camera used to take the photo
  final String? cameraMake;

  /// Model of the camera used to take the photo
  final String? cameraModel;

  /// User-assigned rating of the photo (1-5)
  final int? rating;

  /// Whether the photo is marked as a favorite
  final bool isFavorite;

  /// Path to the photo thumbnail
  final String? thumbnailPath;

  /// List of tags applied to the photo
  final List<Tag>? tags;

  /// List of albums containing the photo
  final List<Album>? albums;

  /// Creates a new photo instance
  Photo({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.folderId,
    this.fileSize,
    this.width,
    this.height,
    this.dateTaken,
    this.cameraMake,
    this.cameraModel,
    this.rating,
    this.isFavorite = false,
    this.thumbnailPath,
    this.tags,
    this.albums,
  });

  /// Creates a Photo object from a JSON map
  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      fileName: json['file_name'],
      filePath: json['file_path'],
      folderId: json['folder_id'],
      fileSize: json['file_size'],
      width: json['width'],
      height: json['height'],
      dateTaken: json['date_taken'] != null
          ? DateTime.parse(json['date_taken'])
          : null,
      cameraMake: json['camera_make'],
      cameraModel: json['camera_model'],
      rating: json['rating'],
      isFavorite: json['is_favorite'] == 1 || json['is_favorite'] == true,
      thumbnailPath: json['thumbnail_path'],
      tags: json['tags'] != null
          ? (json['tags'] as List).map((t) => Tag.fromJson(t)).toList()
          : null,
      albums: json['albums'] != null
          ? (json['albums'] as List).map((a) => Album.fromJson(a)).toList()
          : null,
    );
  }

  /// Converts this Photo object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_path': filePath,
      'folder_id': folderId,
      'file_size': fileSize,
      'width': width,
      'height': height,
      'date_taken': dateTaken?.toIso8601String(),
      'camera_make': cameraMake,
      'camera_model': cameraModel,
      'rating': rating,
      'is_favorite': isFavorite ? 1 : 0,
      'thumbnail_path': thumbnailPath,
      'tags': tags?.map((t) => t.toJson()).toList(),
      'albums': albums?.map((a) => a.toJson()).toList(),
    };
  }

  /// Creates a copy of this Photo with the given fields replaced
  Photo copyWith({
    int? id,
    String? fileName,
    String? filePath,
    int? folderId,
    int? fileSize,
    int? width,
    int? height,
    DateTime? dateTaken,
    String? cameraMake,
    String? cameraModel,
    int? rating,
    bool? isFavorite,
    String? thumbnailPath,
    List<Tag>? tags,
    List<Album>? albums,
  }) {
    return Photo(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      folderId: folderId ?? this.folderId,
      fileSize: fileSize ?? this.fileSize,
      width: width ?? this.width,
      height: height ?? this.height,
      dateTaken: dateTaken ?? this.dateTaken,
      cameraMake: cameraMake ?? this.cameraMake,
      cameraModel: cameraModel ?? this.cameraModel,
      rating: rating ?? this.rating,
      isFavorite: isFavorite ?? this.isFavorite,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      tags: tags ?? this.tags,
      albums: albums ?? this.albums,
    );
  }
}
