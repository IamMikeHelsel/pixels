class Tag {
  final int id;
  final String name;
  final int? parentId;
  final int photoCount;
  final List<Tag>? children;

  Tag({
    required this.id,
    required this.name,
    this.parentId,
    this.photoCount = 0,
    this.children,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    List<Tag>? childTags;
    
    if (json['children'] != null) {
      childTags = (json['children'] as List)
          .map((childJson) => Tag.fromJson(childJson))
          .toList();
    }
    
    return Tag(
      id: json['id'],
      name: json['name'],
      parentId: json['parent_id'],
      photoCount: json['photo_count'] ?? 0,
      children: childTags,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'name': name,
      'photo_count': photoCount,
    };

    if (parentId != null) {
      data['parent_id'] = parentId;
    }

    if (children != null) {
      data['children'] = children!.map((child) => child.toJson()).toList();
    }

    return data;
  }
}