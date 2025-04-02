/// Model representing a tag in the Pixels application.
class Tag {
  final int id;
  final String name;
  final int? parentId;
  final List<Tag> children;
  final int photoCount;
  
  /// Constructor for the Tag class.
  Tag({
    required this.id,
    required this.name,
    this.parentId,
    List<Tag>? children,
    this.photoCount = 0,
  }) : children = children ?? [];
  
  /// Create a Tag from a JSON map.
  factory Tag.fromJson(Map<String, dynamic> json) {
    List<Tag> childTags = [];
    if (json['children'] != null) {
      childTags = (json['children'] as List)
          .map((childJson) => Tag.fromJson(childJson))
          .toList();
    }
    
    return Tag(
      id: json['id'],
      name: json['name'],
      parentId: json['parent_id'],
      children: childTags,
      photoCount: json['photo_count'] ?? 0,
    );
  }
  
  /// Convert this Tag to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'children': children.map((child) => child.toJson()).toList(),
      'photo_count': photoCount,
    };
  }
}