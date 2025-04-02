/// Model class representing an album in the Pixels application
class Album {
  /// Unique identifier for the album
  final int id;

  /// Name of the album
  final String name;

  /// Optional description of the album
  final String? description;

  /// Date when the album was created
  final DateTime dateCreated;

  /// Date when the album was last modified
  final DateTime dateModified;

  /// Number of photos in this album
  final int? photoCount;

  /// Cover photo ID for this album (if set)
  final int? coverPhotoId;

  /// Thumbnail path for the cover photo
  final String? coverThumbnailPath;

  /// Creates a new album instance
  Album({
    required this.id,
    required this.name,
    this.description,
    required this.dateCreated,
    required this.dateModified,
    this.photoCount,
    this.coverPhotoId,
    this.coverThumbnailPath,
  });

  /// Creates an Album object from a JSON map
  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      dateCreated: DateTime.parse(json['date_created']),
      dateModified: DateTime.parse(json['date_modified']),
      photoCount: json['photo_count'],
      coverPhotoId: json['cover_photo_id'],
      coverThumbnailPath: json['cover_thumbnail_path'],
    );
  }

  /// Converts this Album object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date_created': dateCreated.toIso8601String(),
      'date_modified': dateModified.toIso8601String(),
      'photo_count': photoCount,
      'cover_photo_id': coverPhotoId,
      'cover_thumbnail_path': coverThumbnailPath,
    };
  }
}
