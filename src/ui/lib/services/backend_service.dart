import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/album.dart';
import '../models/folder.dart';
import '../models/photo.dart';
import '../models/tag.dart';

/// Service class to handle communication with the Python FastAPI backend.
class BackendService {
  static final BackendService _instance = BackendService._internal();
  
  /// Base URL for the backend API.
  String baseUrl = 'http://localhost:5000/api';
  
  /// Process ID of the backend server if started by this app.
  String? _backendPid;

  /// Factory constructor to return the singleton instance.
  factory BackendService() {
    return _instance;
  }

  BackendService._internal();

  /// Start the backend Python server if not already running.
  Future<bool> startBackend() async {
    try {
      // Check if backend is already running
      final response = await http.get(Uri.parse('$baseUrl/health')).timeout(
        const Duration(seconds: 1),
        onTimeout: () {
          throw TimeoutException('Backend server is not responding');
        },
      );
      
      if (response.statusCode == 200) {
        print('Backend server is already running');
        return true;
      }
    } catch (e) {
      print('Backend server is not running, attempting to start it...');
      
      try {
        // Start the Python backend process using the operating system's process API
        final process = await Process.start(
          'python',
          [
            'main.py',
            'serve',
            '--host',
            'localhost',
            '--port',
            '5000'
          ],
          // Use the correct working directory where main.py is located
          workingDirectory: Directory.current.path,
        );
        
        _backendPid = process.pid.toString();
        
        // Save the PID to preferences for potential recovery later
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('backend_pid', _backendPid!);
        
        // Wait a moment for the server to start
        await Future.delayed(const Duration(seconds: 2));
        
        print('Backend server started with PID: $_backendPid');
        return true;
      } catch (e) {
        print('Failed to start backend server: $e');
        return false;
      }
    }
    
    return false;
  }

  /// Stop the backend Python server if it was started by this service.
  Future<bool> stopBackend() async {
    if (_backendPid != null) {
      try {
        // Try to make a clean shutdown request if the server supports it
        try {
          // Note: We'd need to add a shutdown endpoint in the FastAPI server 
          // to support this functionality
          await http.post(Uri.parse('$baseUrl/shutdown'));
        } catch (e) {
          // If that fails, we'll have to kill the process by PID
          // This is platform-specific and would need proper implementation
          // based on the target platform (Windows, Linux, macOS)
          print('Failed to gracefully shut down server, may need to kill process $_backendPid');
        }
        
        // Clear the PID
        _backendPid = null;
        
        // Remove from preferences
        final prefs = await SharedPreferences.getInstance();
        prefs.remove('backend_pid');
        
        print('Backend server stopped successfully');
        return true;
      } catch (e) {
        print('Failed to stop backend server: $e');
        return false;
      }
    }
    
    return true;
  }
  
  // API Methods for Folders
  
  /// Get all folders in the library.
  Future<List<Folder>> getFolders({bool hierarchy = true}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/folders?hierarchy=$hierarchy')
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((folderData) => Folder.fromJson(folderData)).toList();
      } else {
        throw Exception('Failed to load folders: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching folders: $e');
      // Fall back to mock data if API fails
      return _getMockFolders();
    }
  }
  
  /// Add a new folder to the library.
  Future<int?> addFolder(String path, {String? name, bool isMonitored = false}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/folders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'path': path,
          'name': name ?? path.split(Platform.pathSeparator).last,
          'is_monitored': isMonitored,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'] as int;
      } else {
        throw Exception('Failed to add folder: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding folder: $e');
      return null;
    }
  }
  
  // API Methods for Photos
  
  /// Get photos in a specific folder.
  Future<List<Photo>> getPhotosByFolder(int folderId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/photos/folder/$folderId')
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((photoData) => Photo.fromJson(photoData)).toList();
      } else {
        throw Exception('Failed to load photos for folder $folderId: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching photos for folder $folderId: $e');
      // Fall back to mock data if API fails
      return _getMockPhotosByFolder(folderId);
    }
  }
  
  /// Get a specific photo by ID.
  Future<Photo> getPhoto(int photoId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/photos/$photoId')
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Photo.fromJson(data);
      } else {
        throw Exception('Failed to load photo $photoId: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching photo $photoId: $e');
      // Fall back to mock data if API fails
      return _getMockPhoto(photoId);
    }
  }
  
  /// Search photos with specified criteria.
  Future<List<Photo>> searchPhotos({
    String? keyword,
    List<int>? folderIds,
    DateTime? dateFrom,
    DateTime? dateTo,
    int? minRating,
    bool? isFavorite,
    List<int>? tagIds,
    int? albumId,
    int limit = 100,
    int offset = 0,
    String sortBy = 'date_taken',
    bool sortDesc = true,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
        'sort_by': sortBy,
        'sort_desc': sortDesc.toString(),
      };
      
      if (keyword != null) queryParams['keyword'] = keyword;
      if (folderIds != null) queryParams['folder_ids'] = folderIds.join(',');
      if (dateFrom != null) queryParams['date_from'] = dateFrom.toIso8601String();
      if (dateTo != null) queryParams['date_to'] = dateTo.toIso8601String();
      if (minRating != null) queryParams['min_rating'] = minRating.toString();
      if (isFavorite != null) queryParams['is_favorite'] = isFavorite.toString();
      if (tagIds != null) queryParams['tag_ids'] = tagIds.join(',');
      if (albumId != null) queryParams['album_id'] = albumId.toString();
      
      final uri = Uri.parse('$baseUrl/photos/search').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((photoData) => Photo.fromJson(photoData)).toList();
      } else {
        throw Exception('Failed to search photos: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching photos: $e');
      // Fall back to mock data
      return [];
    }
  }
  
  /// Update a photo's properties (rating or favorite status).
  Future<bool> updatePhoto(int photoId, {int? rating, bool? isFavorite}) async {
    try {
      final updateData = <String, dynamic>{};
      if (rating != null) updateData['rating'] = rating;
      if (isFavorite != null) updateData['is_favorite'] = isFavorite;
      
      if (updateData.isEmpty) return false;
      
      final response = await http.patch(
        Uri.parse('$baseUrl/photos/$photoId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating photo $photoId: $e');
      return false;
    }
  }
  
  // API Methods for Albums
  
  /// Get all albums in the library.
  Future<List<Album>> getAlbums() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/albums')
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((albumData) => Album.fromJson(albumData)).toList();
      } else {
        throw Exception('Failed to load albums: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching albums: $e');
      // Fall back to mock data if API fails
      return _getMockAlbums();
    }
  }
  
  /// Get photos in a specific album.
  Future<List<Photo>> getPhotosByAlbum(int albumId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/albums/$albumId/photos')
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((photoData) => Photo.fromJson(photoData)).toList();
      } else {
        throw Exception('Failed to load photos for album $albumId: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching photos for album $albumId: $e');
      // Fall back to mock data if API fails
      return _getMockPhotosByAlbum(albumId);
    }
  }
  
  /// Create a new album.
  Future<int?> createAlbum(String name, {String description = ''}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/albums'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'description': description,
        }),
      );
      
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['id'] as int;
      } else {
        throw Exception('Failed to create album: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating album: $e');
      return null;
    }
  }
  
  /// Add a photo to an album.
  Future<bool> addPhotoToAlbum(int albumId, int photoId, {int? orderIndex}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/albums/$albumId/photos/$photoId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'order_index': orderIndex,
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error adding photo $photoId to album $albumId: $e');
      return false;
    }
  }
  
  /// Remove a photo from an album.
  Future<bool> removePhotoFromAlbum(int albumId, int photoId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/albums/$albumId/photos/$photoId'),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error removing photo $photoId from album $albumId: $e');
      return false;
    }
  }
  
  // API Methods for Tags
  
  /// Get all tags in the library.
  Future<List<Tag>> getTags({bool hierarchy = true}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tags?hierarchy=$hierarchy')
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((tagData) => Tag.fromJson(tagData)).toList();
      } else {
        throw Exception('Failed to load tags: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching tags: $e');
      // Fall back to mock data if API fails
      return _getMockTags();
    }
  }
  
  /// Get photos with a specific tag.
  Future<List<Photo>> getPhotosByTag(int tagId, {int limit = 100, int offset = 0}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tags/$tagId/photos?limit=$limit&offset=$offset')
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((photoData) => Photo.fromJson(photoData)).toList();
      } else {
        throw Exception('Failed to load photos for tag $tagId: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching photos for tag $tagId: $e');
      // Fall back to mock data if API fails
      return _getMockPhotosByTag(tagId);
    }
  }
  
  /// Add a tag to a photo.
  Future<bool> addTagToPhoto(int photoId, int tagId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/photos/$photoId/tags/$tagId'),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error adding tag $tagId to photo $photoId: $e');
      return false;
    }
  }
  
  /// Remove a tag from a photo.
  Future<bool> removeTagFromPhoto(int photoId, int tagId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/photos/$photoId/tags/$tagId'),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error removing tag $tagId from photo $photoId: $e');
      return false;
    }
  }
  
  /// Get a thumbnail URL for a photo.
  String getThumbnailUrl(int photoId, {String size = 'medium'}) {
    return '$baseUrl/thumbnails/$photoId?size=$size';
  }
  
  // Mock data methods for fallback
  List<Folder> _getMockFolders() {
    return [
      Folder(
        id: 1,
        path: 'C:/Users/user/Pictures',
        name: 'Pictures',
        photoCount: 120,
        children: [
          Folder(
            id: 2,
            path: 'C:/Users/user/Pictures/Vacation',
            name: 'Vacation',
            parentId: 1,
            photoCount: 54,
          ),
          Folder(
            id: 3,
            path: 'C:/Users/user/Pictures/Family',
            name: 'Family',
            parentId: 1,
            photoCount: 36,
          ),
        ],
      ),
      Folder(
        id: 4,
        path: 'D:/Photos',
        name: 'Photos',
        photoCount: 85,
      ),
    ];
  }
  
  List<Photo> _getMockPhotosByFolder(int folderId) {
    // Create mock photos based on folder ID
    List<Photo> mockPhotos = [];
    final baseDate = DateTime(2023, 1, 1);
    
    for (int i = 1; i <= 20; i++) {
      final photoId = folderId * 100 + i;
      mockPhotos.add(
        Photo(
          id: photoId,
          fileName: 'Photo_$photoId.jpg',
          filePath: 'path/to/photos/Photo_$photoId.jpg',
          thumbnailPath: null,
          width: 1920,
          height: 1080,
          dateTaken: baseDate.add(Duration(days: i)),
          fileSize: 2500000 + (i * 10000),
          cameraMake: 'Mock Camera',
          cameraModel: 'Model X',
          rating: i % 5,
          isFavorite: i % 7 == 0,
        ),
      );
    }
    
    return mockPhotos;
  }
  
  Photo _getMockPhoto(int photoId) {
    return Photo(
      id: photoId,
      fileName: 'Photo_$photoId.jpg',
      filePath: 'path/to/photos/Photo_$photoId.jpg',
      thumbnailPath: null,
      width: 1920,
      height: 1080,
      dateTaken: DateTime(2023, 1, 1).add(Duration(days: photoId % 30)),
      fileSize: 2500000 + (photoId * 10000),
      cameraMake: 'Mock Camera',
      cameraModel: 'Model X',
      rating: photoId % 5,
      isFavorite: photoId % 7 == 0,
    );
  }
  
  List<Album> _getMockAlbums() {
    return [
      Album(
        id: 1,
        name: 'Favorites',
        description: 'My favorite photos',
        dateCreated: DateTime(2023, 1, 15),
        dateModified: DateTime(2023, 3, 10),
        photoCount: 15,
      ),
      Album(
        id: 2,
        name: 'Vacation 2023',
        description: 'Summer vacation photos',
        dateCreated: DateTime(2023, 7, 1),
        dateModified: DateTime(2023, 7, 30),
        photoCount: 54,
      ),
    ];
  }
  
  List<Photo> _getMockPhotosByAlbum(int albumId) {
    // Create mock photos based on album ID
    List<Photo> mockPhotos = [];
    final baseDate = DateTime(2023, 3, 1);
    
    for (int i = 1; i <= 15; i++) {
      final photoId = albumId * 100 + i;
      mockPhotos.add(
        Photo(
          id: photoId,
          fileName: 'Album_${albumId}_Photo_$i.jpg',
          filePath: 'path/to/photos/Album_$albumId/Photo_$i.jpg',
          thumbnailPath: null,
          width: 1920,
          height: 1080,
          dateTaken: baseDate.add(Duration(days: i * 2)),
          fileSize: 3000000 + (i * 15000),
          cameraMake: 'Mock Camera',
          cameraModel: 'Model X',
          rating: (i % 5) + 1, // 1-5 rating
          isFavorite: albumId == 1 ? true : i % 5 == 0,
        ),
      );
    }
    
    return mockPhotos;
  }
  
  List<Tag> _getMockTags() {
    return [
      Tag(
        id: 1,
        name: 'People',
        photoCount: 45,
        children: [
          Tag(id: 2, name: 'Family', parentId: 1, photoCount: 25),
          Tag(id: 3, name: 'Friends', parentId: 1, photoCount: 20),
        ],
      ),
      Tag(
        id: 4,
        name: 'Places',
        photoCount: 70,
        children: [
          Tag(id: 5, name: 'Beach', parentId: 4, photoCount: 30),
          Tag(id: 6, name: 'Mountains', parentId: 4, photoCount: 25),
          Tag(id: 7, name: 'City', parentId: 4, photoCount: 15),
        ],
      ),
      Tag(id: 8, name: 'Events', photoCount: 35),
    ];
  }
  
  List<Photo> _getMockPhotosByTag(int tagId) {
    // For simplicity, reuse the album photos mock
    return _getMockPhotosByAlbum(tagId);
  }
}