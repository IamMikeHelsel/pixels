/// Model class representing a tag in the Pixels application
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

  /// Converts this Tag object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'parent_id': parentId,
      'photo_count': photoCount,
      // Children are not included in the JSON serialization to avoid circular references
    };
  }
}
