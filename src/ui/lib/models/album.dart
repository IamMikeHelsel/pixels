/// Model representing an album in the Pixels application.
class Album {
  final int id;
  final String name;
  final String? description;
  final DateTime? dateCreated;
  final DateTime? dateModified;
  final int photoCount;
  
  /// Constructor for the Album class.
  Album({
    required this.id,
    required this.name,
    this.description,
    this.dateCreated,
    this.dateModified,
    this.photoCount = 0,
  });
  
  /// Create an Album from a JSON map.
  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      dateCreated: json['date_created'] != null 
        ? DateTime.parse(json['date_created']) 
        : null,
      dateModified: json['date_modified'] != null 
        ? DateTime.parse(json['date_modified']) 
        : null,
      photoCount: json['photo_count'] ?? 0,
    );
  }
  
  /// Convert this Album to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'date_created': dateCreated?.toIso8601String(),
      'date_modified': dateModified?.toIso8601String(),
      'photo_count': photoCount,
    };
  }
}