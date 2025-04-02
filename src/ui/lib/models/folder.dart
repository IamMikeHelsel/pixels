/// Model representing a folder in the Pixels application.
class Folder {
  final int id;
  final String path;
  final String name;
  final int? parentId;
  final int photoCount;
  final List<Folder> children;
  
  /// Constructor for the Folder class.
  Folder({
    required this.id,
    required this.path,
    required this.name,
    this.parentId,
    this.photoCount = 0,
    List<Folder>? children,
  }) : children = children ?? [];
  
  /// Create a Folder from a JSON map.
  factory Folder.fromJson(Map<String, dynamic> json) {
    List<Folder> childFolders = [];
    if (json['children'] != null) {
      childFolders = (json['children'] as List)
          .map((childJson) => Folder.fromJson(childJson))
          .toList();
    }
    
    return Folder(
      id: json['id'],
      path: json['path'],
      name: json['name'],
      parentId: json['parent_id'],
      photoCount: json['photo_count'] ?? 0,
      children: childFolders,
    );
  }
  
  /// Convert this Folder to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'parent_id': parentId,
      'photo_count': photoCount,
      'children': children.map((child) => child.toJson()).toList(),
    };
  }
}