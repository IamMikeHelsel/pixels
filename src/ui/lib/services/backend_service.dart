import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:process_run/process_run.dart';

import '../models/album.dart';
import '../models/folder.dart';
import '../models/photo.dart';
import '../models/tag.dart';

/// Service for communicating with the Pixels Python backend API
class BackendService {
  /// Base URL of the backend API
  final String baseUrl;

  /// Client for making HTTP requests
  final http.Client _client = http.Client();

  /// Process for the backend server
  Process? _serverProcess;

  /// Flag indicating whether the backend was started by this service
  bool _startedByService = false;

  /// Creates a new instance of the BackendService
  ///
  /// [baseUrl] defaults to localhost on port 8000
  BackendService({
    this.baseUrl = 'http://localhost:8000',
  });

  /// Starts the backend server if it's not already running
  ///
  /// [pythonPath] is the path to the Python executable
  /// [backendPath] is the path to the main.py file
  Future<bool> startBackend({
    String? pythonPath,
    String? backendPath,
  }) async {
    // Check if the backend is already running
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      if (response.statusCode == 200) {
        // Backend is already running
        return true;
      }
    } catch (e) {
      // Backend is not running, we need to start it
    }

    pythonPath ??= await _findPythonPath();
    if (pythonPath == null) {
      throw Exception('Could not find Python executable');
    }

    backendPath ??= await _findBackendPath();
    if (backendPath == null) {
      throw Exception('Could not find Pixels backend (main.py)');
    }

    try {
      // Start the server process
      _serverProcess = await Process.start(
        pythonPath,
        [backendPath],
        mode: ProcessStartMode.detached,
      );

      _startedByService = true;

      // Wait for the server to start
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(seconds: 1));
        try {
          final response = await http.get(Uri.parse('$baseUrl/health'));
          if (response.statusCode == 200) {
            return true;
          }
        } catch (e) {
          // Server not ready yet
        }
      }

      throw Exception('Failed to start backend server');
    } catch (e) {
      throw Exception('Error starting backend server: $e');
    }
  }

  /// Stops the backend server if it was started by this service
  Future<void> stopBackend() async {
    if (_serverProcess != null && _startedByService) {
      _serverProcess!.kill();
      _serverProcess = null;
      _startedByService = false;
    }
  }

  /// Finds the Python executable path
  Future<String?> _findPythonPath() async {
    try {
      final shell = Shell();
      final result = await shell.run('where python');
      final pythonPath =
          result.first.stdout.toString().trim().split('\n').first;
      return pythonPath;
    } catch (e) {
      try {
        final shell = Shell();
        final result = await shell.run('which python3');
        return result.first.stdout.toString().trim();
      } catch (e) {
        return null;
      }
    }
  }

  /// Finds the path to the main.py backend file
  Future<String?> _findBackendPath() async {
    // First check the current directory and parent directories
    final potentialPaths = [
      'main.py',
      '../main.py',
      '../../main.py',
      '../../../main.py',
      '../../../../main.py',
    ];

    for (final potentialPath in potentialPaths) {
      if (await File(potentialPath).exists()) {
        return potentialPath;
      }
    }

    return null;
  }

  /// Gets all photos in the library
  ///
  /// [limit] limits the number of photos returned
  /// [offset] skips the first [offset] photos
  /// [folderId] filters photos by folder ID
  /// [albumId] filters photos by album ID
  /// [tagId] filters photos by tag ID
  Future<List<Photo>> getPhotos({
    int? limit,
    int? offset,
    int? folderId,
    int? albumId,
    int? tagId,
    bool? favorites,
    String? searchQuery,
  }) async {
    final queryParams = <String, String>{};

    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();
    if (folderId != null) queryParams['folder_id'] = folderId.toString();
    if (albumId != null) queryParams['album_id'] = albumId.toString();
    if (tagId != null) queryParams['tag_id'] = tagId.toString();
    if (favorites != null) queryParams['favorites'] = favorites.toString();
    if (searchQuery != null) queryParams['search'] = searchQuery;

    final uri =
        Uri.parse('$baseUrl/photos').replace(queryParameters: queryParams);
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => Photo.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load photos: ${response.statusCode}');
    }
  }

  /// Gets a specific photo by ID
  Future<Photo> getPhoto(int photoId) async {
    final response = await _client.get(Uri.parse('$baseUrl/photos/$photoId'));

    if (response.statusCode == 200) {
      return Photo.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load photo: ${response.statusCode}');
    }
  }

  /// Gets all folders
  ///
  /// [hierarchy] if true, returns folders in a hierarchical structure
  Future<List<Folder>> getFolders({bool hierarchy = false}) async {
    final queryParams = <String, String>{};
    if (hierarchy) queryParams['hierarchy'] = 'true';

    final uri =
        Uri.parse('$baseUrl/folders').replace(queryParameters: queryParams);
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => Folder.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load folders: ${response.statusCode}');
    }
  }

  /// Adds a folder to the library
  Future<int> addFolder(
    String folderPath, {
    String? name,
    bool? isMonitored,
  }) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/folders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'path': folderPath,
        'name': name ?? path.basename(folderPath),
        'is_monitored': isMonitored ?? false,
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData['id'];
    } else {
      throw Exception('Failed to add folder: ${response.statusCode}');
    }
  }

  /// Gets all albums
  Future<List<Album>> getAlbums() async {
    final response = await _client.get(Uri.parse('$baseUrl/albums'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => Album.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load albums: ${response.statusCode}');
    }
  }

  /// Creates a new album
  Future<int> createAlbum(String name, {String? description}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/albums'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'description': description,
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData['id'];
    } else {
      throw Exception('Failed to create album: ${response.statusCode}');
    }
  }

  /// Gets all tags
  ///
  /// [hierarchy] if true, returns tags in a hierarchical structure
  Future<List<Tag>> getTags({bool hierarchy = false}) async {
    final queryParams = <String, String>{};
    if (hierarchy) queryParams['hierarchy'] = 'true';

    final uri =
        Uri.parse('$baseUrl/tags').replace(queryParameters: queryParams);
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => Tag.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tags: ${response.statusCode}');
    }
  }

  /// Creates a new tag
  Future<int> createTag(String name, {int? parentId}) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/tags'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'parent_id': parentId,
      }),
    );

    if (response.statusCode == 201) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return responseData['id'];
    } else {
      throw Exception('Failed to create tag: ${response.statusCode}');
    }
  }

  /// Adds a photo to an album
  Future<void> addPhotoToAlbum(int photoId, int albumId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/albums/$albumId/photos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'photo_id': photoId}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add photo to album: ${response.statusCode}');
    }
  }

  /// Adds a tag to a photo
  Future<void> addTagToPhoto(int photoId, int tagId) async {
    final response = await _client.post(
      Uri.parse('$baseUrl/photos/$photoId/tags'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'tag_id': tagId}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add tag to photo: ${response.statusCode}');
    }
  }

  /// Updates a photo's metadata
  Future<void> updatePhoto(
    int photoId, {
    int? rating,
    bool? isFavorite,
  }) async {
    final Map<String, dynamic> updateData = {};

    if (rating != null) updateData['rating'] = rating;
    if (isFavorite != null) updateData['is_favorite'] = isFavorite;

    if (updateData.isEmpty) return;

    final response = await _client.put(
      Uri.parse('$baseUrl/photos/$photoId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(updateData),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update photo: ${response.statusCode}');
    }
  }

  /// Scans folders for new photos
  ///
  /// [folderId] if provided, only scans the specified folder
  Future<Map<String, dynamic>> scanFolders({int? folderId}) async {
    final Uri uri;
    if (folderId != null) {
      uri = Uri.parse('$baseUrl/folders/$folderId/scan');
    } else {
      uri = Uri.parse('$baseUrl/folders/scan');
    }

    final response = await _client.post(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to scan folders: ${response.statusCode}');
    }
  }

  /// Gets stats about the photo library
  Future<Map<String, dynamic>> getStats() async {
    final response = await _client.get(Uri.parse('$baseUrl/stats'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get stats: ${response.statusCode}');
    }
  }
}
