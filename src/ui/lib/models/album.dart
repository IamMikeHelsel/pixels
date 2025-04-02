class Album {
  final int id;
  final String name;
  final String? description;
  final DateTime dateCreated;
  final DateTime dateModified;
  final int photoCount;

  Album({
    required this.id,
    required this.name,
    this.description,
    required this.dateCreated,
    required this.dateModified,
    this.photoCount = 0,
  });

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      dateCreated: json['date_created'] != null
          ? DateTime.parse(json['date_created'])
          : DateTime.now(),
      dateModified: json['date_modified'] != null
          ? DateTime.parse(json['date_modified'])
          : DateTime.now(),
      photoCount: json['photo_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date_created': dateCreated.toIso8601String(),
      'date_modified': dateModified.toIso8601String(),
      'photo_count': photoCount,
    };
  }
}