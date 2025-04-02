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

/// Reference to the Tag class to avoid circular dependencies
class Tag {
  /// Unique identifier for the tag
  final int id;

  /// Name of the tag
  final String name;

  /// ID of the parent tag (if this is a child tag)
  final int? parentId;

  /// Number of photos with this tag
  final int? photoCount;

  /// Child tags of this tag
  final List<Tag>? children;

  /// Creates a new tag instance
  Tag({
    required this.id,
    required this.name,
    this.parentId,
    this.photoCount,
    this.children,
  });

  /// Creates a Tag object from a JSON map
  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'],
      name: json['name'],
      parentId: json['parent_id'],
      photoCount: json['photo_count'],
      children: json['children'] != null
          ? (json['children'] as List).map((c) => Tag.fromJson(c)).toList()
          : null,
    );
  }
}

/// Reference to the Album class to avoid circular dependencies
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

  /// Creates a new album instance
  Album({
    required this.id,
    required this.name,
    this.description,
    required this.dateCreated,
    required this.dateModified,
    this.photoCount,
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
    );
  }
}
