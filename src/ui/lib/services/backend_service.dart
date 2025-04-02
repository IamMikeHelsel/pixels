import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/album.dart';
import '../models/folder.dart';
import '../models/photo.dart';
import '../models/tag.dart';

/// Service class to handle communication with the Python backend.
class BackendService {
  static final BackendService _instance = BackendService._internal();
  
  /// Base URL for the backend API.
  String baseUrl = 'http://localhost:5000/api';
  
  /// Process ID of the backend server.
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
        // For now, we'll just mock this functionality
        // In a real implementation, this would start the Python backend process
        // and store its PID for potential shutdown later
        
        // Mock successful startup
        await Future.delayed(const Duration(seconds: 1));
        _backendPid = '12345'; // Mock PID
        
        // Save the PID to preferences for potential recovery later
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('backend_pid', _backendPid!);
        
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
        // For now, we'll just mock this functionality
        // In a real implementation, this would stop the Python backend process
        
        // Mock successful shutdown
        await Future.delayed(const Duration(seconds: 1));
        
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
  
  // API Methods
  
  /// Get all folders in the library.
  Future<List<Folder>> getFolders() async {
    // In a real implementation, this would fetch data from the backend
    // For now, return mock data
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
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
  
  /// Get photos in a specific folder.
  Future<List<Photo>> getPhotosByFolder(int folderId) async {
    // In a real implementation, this would fetch data from the backend
    // For now, return mock data
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
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
          thumbnailPath: null, // No real thumbnails in our prototype
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
  
  /// Get a specific photo by ID.
  Future<Photo> getPhoto(int photoId) async {
    // In a real implementation, this would fetch data from the backend
    // For now, return mock data
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    return Photo(
      id: photoId,
      fileName: 'Photo_$photoId.jpg',
      filePath: 'path/to/photos/Photo_$photoId.jpg',
      thumbnailPath: null, // No real thumbnails in our prototype
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
  
  /// Get all albums in the library.
  Future<List<Album>> getAlbums() async {
    // In a real implementation, this would fetch data from the backend
    // For now, return mock data
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
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
  
  /// Get photos in a specific album.
  Future<List<Photo>> getPhotosByAlbum(int albumId) async {
    // In a real implementation, this would fetch data from the backend
    // For now, return mock data
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
    // Create mock photos based on album ID
    List<Photo> mockPhotos = [];
    final baseDate = DateTime(2023, 3, 1);
    
    for (int i = 1; i <= 15; i++) {
      final photoId = albumId * 100 + i;
      mockPhotos.add(
        Photo(
          id: photoId,
          fileName: 'Album_$albumId\_Photo_$i.jpg',
          filePath: 'path/to/photos/Album_$albumId/Photo_$i.jpg',
          thumbnailPath: null, // No real thumbnails in our prototype
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
  
  /// Get all tags in the library.
  Future<List<Tag>> getTags() async {
    // In a real implementation, this would fetch data from the backend
    // For now, return mock data
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    
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
  
  /// Get photos with a specific tag.
  Future<List<Photo>> getPhotosByTag(int tagId) async {
    // In a real implementation, this would fetch data from the backend
    // For now, we'll reuse the album photos mock for simplicity
    return getPhotosByAlbum(tagId);
  }
  
  /// Update a photo's rating.
  Future<bool> updatePhotoRating(int photoId, int rating) async {
    // In a real implementation, this would update the photo in the backend
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return true;
  }
  
  /// Update a photo's favorite status.
  Future<bool> updatePhotoFavorite(int photoId, bool isFavorite) async {
    // In a real implementation, this would update the photo in the backend
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
    return true;
  }
}