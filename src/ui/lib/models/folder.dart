class Folder {
  final int id;
  final String path;
  final String name;
  final int? parentId;
  final bool isMonitored;
  final int photoCount;
  final List<Folder>? children;

  Folder({
    required this.id,
    required this.path,
    required this.name,
    this.parentId,
    this.isMonitored = false,
    this.photoCount = 0,
    this.children,
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    List<Folder>? childFolders;
    
    if (json['children'] != null) {
      childFolders = (json['children'] as List)
          .map((childJson) => Folder.fromJson(childJson))
          .toList();
    }
    
    return Folder(
      id: json['id'],
      path: json['path'],
      name: json['name'] ?? json['path'].split('/').last,
      parentId: json['parent_id'],
      isMonitored: json['is_monitored'] ?? false,
      photoCount: json['photo_count'] ?? 0,
      children: childFolders,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'path': path,
      'name': name,
      'photo_count': photoCount,
      'is_monitored': isMonitored,
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