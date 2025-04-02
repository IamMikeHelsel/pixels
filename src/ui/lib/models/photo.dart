/// Model representing a photo in the Pixels application.
class Photo {
  final int id;
  final String fileName;
  final String filePath;
  final String? thumbnailPath;
  final int? width;
  final int? height;
  final DateTime? dateTaken;
  final int? fileSize;
  final String? cameraMake;
  final String? cameraModel;
  final int rating;
  final bool isFavorite;
  
  /// Constructor for the Photo class.
  Photo({
    required this.id,
    required this.fileName,
    required this.filePath,
    this.thumbnailPath,
    this.width,
    this.height,
    this.dateTaken,
    this.fileSize,
    this.cameraMake,
    this.cameraModel,
    this.rating = 0,
    this.isFavorite = false,
  });
  
  /// Create a Photo from a JSON map.
  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'],
      fileName: json['file_name'],
      filePath: json['file_path'],
      thumbnailPath: json['thumbnail_path'],
      width: json['width'],
      height: json['height'],
      dateTaken: json['date_taken'] != null 
        ? DateTime.parse(json['date_taken']) 
        : null,
      fileSize: json['file_size'],
      cameraMake: json['camera_make'],
      cameraModel: json['camera_model'],
      rating: json['rating'] ?? 0,
      isFavorite: json['is_favorite'] == 1,
    );
  }
  
  /// Convert this Photo to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_path': filePath,
      'thumbnail_path': thumbnailPath,
      'width': width,
      'height': height,
      'date_taken': dateTaken?.toIso8601String(),
      'file_size': fileSize,
      'camera_make': cameraMake,
      'camera_model': cameraModel,
      'rating': rating,
      'is_favorite': isFavorite ? 1 : 0,
    };
  }
}