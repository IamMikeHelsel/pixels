/// Model class representing a folder in the Pixels application
class Folder {
  /// Unique identifier for the folder
  final int id;

  /// Filesystem path to the folder
  final String path;

  /// Display name of the folder
  final String name;

  /// ID of the parent folder, if any
  final int? parentId;

  /// Whether this folder is being monitored for changes
  final bool isMonitored;

  /// Number of photos in this folder
  final int photoCount;

  /// Child folders of this folder
  final List<Folder>? children;

  /// Creates a new folder instance
  Folder({
    required this.id,
    required this.path,
    required this.name,
    this.parentId,
    required this.isMonitored,
    this.photoCount = 0,
    this.children,
  });

  /// Creates a Folder object from a JSON map
  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'],
      path: json['path'],
      name: json['name'],
      parentId: json['parent_id'],
      isMonitored: json['is_monitored'] == 1 || json['is_monitored'] == true,
      photoCount: json['photo_count'] ?? 0,
      children: json['children'] != null
          ? (json['children'] as List).map((c) => Folder.fromJson(c)).toList()
          : null,
    );
  }

  /// Converts this Folder object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'parent_id': parentId,
      'is_monitored': isMonitored ? 1 : 0,
      'photo_count': photoCount,
      // Children are not included in the JSON serialization to avoid circular references
    };
  }
}
