import 'dart:convert';
import 'dart:io';
import 'dart:async'; // Added missing import for StreamController

import 'package:flutter/foundation.dart';
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
  String _baseUrl;

  /// Client for making HTTP requests
  final http.Client _client = http.Client();

  /// Process for the backend server
  Process? _serverProcess;

  /// Flag indicating whether the backend was started by this service
  bool _startedByService = false;

  /// Stream controller for backend status updates
  final _statusController = StreamController<bool>.broadcast();

  /// Stream of backend status updates (true = running, false = not running)
  Stream<bool> get statusStream => _statusController.stream;

  /// Gets the base URL for the API
  String get baseUrl => _baseUrl;

  /// Sets the base URL for the API
  set baseUrl(String value) {
    _baseUrl = value;
  }

  /// Creates a new instance of the BackendService
  ///
  /// [baseUrl] defaults to localhost on port 5000
  BackendService({
    String baseUrl = 'http://localhost:5000',
  }) : _baseUrl = baseUrl;

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
      final response = await _client.get(
        Uri.parse('$baseUrl/api/health'),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        // Backend is already running
        debugPrint('Backend is already running at $baseUrl');
        _statusController.add(true);
        return true;
      }
    } catch (e) {
      // Backend is not running, we need to start it
      debugPrint('Backend is not running. Attempting to start it...');
    }

    try {
      pythonPath ??= await _findPythonPath();
      if (pythonPath == null) {
        throw Exception('Could not find Python executable');
      }
      debugPrint('Using Python at: $pythonPath');

      backendPath ??= await _findBackendPath();
      if (backendPath == null) {
        throw Exception('Could not find Pixels backend (main.py)');
      }
      debugPrint('Found backend at: $backendPath');

      // Extract port from baseUrl
      final uri = Uri.parse(baseUrl);
      final port = uri.port;

      // Always use 0.0.0.0 as the host when starting the backend
      // This will make the backend listen on all network interfaces
      const host = '0.0.0.0';
      debugPrint('Starting backend server at $host:$port...');

      _serverProcess = await Process.start(
        pythonPath,
        [
          backendPath,
          'serve', // Command to start the server
          '--host', host, // Host parameter - using 0.0.0.0 instead of localhost
          '--port', port.toString(), // Port parameter
        ],
        mode: ProcessStartMode.detached,
      );

      _serverProcess!.stdout.transform(utf8.decoder).listen((data) {
        debugPrint('Backend stdout: $data');
      });

      _serverProcess!.stderr.transform(utf8.decoder).listen((data) {
        debugPrint('Backend stderr: $data');
      });

      _startedByService = true;

      // Wait for the server to start with more frequent checks initially
      debugPrint('Waiting for backend to become available...');
      for (int i = 0; i < 20; i++) {
        // First few attempts, check more frequently
        await Future.delayed(i < 5
            ? const Duration(milliseconds: 500)
            : const Duration(seconds: 1));

        try {
          final response = await _client
              .get(Uri.parse('$baseUrl/api/health'))
              .timeout(const Duration(seconds: 2));
          if (response.statusCode == 200) {
            debugPrint('Backend started successfully!');
            _statusController.add(true);
            return true;
          }
        } catch (e) {
          // Server not ready yet
          if (i % 5 == 0 || i < 5) {
            // Only log periodically to avoid spam
            debugPrint('Waiting for backend... (${i + 1}/20)');
          }
        }
      }

      _statusController.add(false);
      throw Exception('Failed to start backend server after 20 attempts');
    } catch (e) {
      debugPrint('Error starting backend server: $e');
      _statusController.add(false);
      throw Exception('Error starting backend server: $e');
    }
  }

  /// Stops the backend server if it was started by this service
  Future<void> stopBackend() async {
    if (_serverProcess != null && _startedByService) {
      // Try to send a shutdown request to the API first for graceful shutdown
      try {
        await _client
            .post(Uri.parse('$baseUrl/api/shutdown'))
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('Error sending shutdown request: $e');
        // Continue to kill the process
      }

      _serverProcess!.kill();
      _serverProcess = null;
      _startedByService = false;
      _statusController.add(false);
      debugPrint('Backend server stopped');
    }
  }

  /// Gets the current backend status
  Future<bool> checkBackendStatus() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 2));
      final isRunning = response.statusCode == 200;
      _statusController.add(isRunning);
      return isRunning;
    } catch (e) {
      _statusController.add(false);
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _statusController.close();
  }

  /// Finds the Python executable path
  Future<String?> _findPythonPath() async {
    final List<String> potentialPythonPaths = [];

    // First try to find Python using process_run shell commands
    try {
      final shell = Shell();
      final result = await shell.run('where python');
      final foundPaths = result.first.stdout.toString().trim().split('\n');
      potentialPythonPaths.addAll(foundPaths.where((p) => p.isNotEmpty));
    } catch (e) {
      try {
        final shell = Shell();
        final result = await shell.run('which python3');
        final pythonPath = result.first.stdout.toString().trim();
        if (pythonPath.isNotEmpty) {
          potentialPythonPaths.add(pythonPath);
        }
      } catch (e) {
        debugPrint('Unable to find python using shell commands: $e');
      }
    }

    // Add common installation paths
    if (Platform.isWindows) {
      potentialPythonPaths.addAll([
        'C:\\Python39\\python.exe',
        'C:\\Python38\\python.exe',
        'C:\\Python310\\python.exe',
        'C:\\Python311\\python.exe',
        'C:\\Python312\\python.exe',
        'C:\\Program Files\\Python39\\python.exe',
        'C:\\Program Files\\Python38\\python.exe',
        'C:\\Program Files\\Python310\\python.exe',
        'C:\\Program Files\\Python311\\python.exe',
        'C:\\Program Files\\Python312\\python.exe',
      ]);
    } else {
      potentialPythonPaths.addAll([
        '/usr/bin/python3',
        '/usr/local/bin/python3',
        '/opt/homebrew/bin/python3',
      ]);
    }

    // Try each path and return the first one that exists
    for (final pythonPath in potentialPythonPaths) {
      final pythonFile = File(pythonPath);
      if (await pythonFile.exists()) {
        debugPrint('Found Python at: $pythonPath');
        return pythonPath;
      }
    }

    return null;
  }

  /// Finds the path to the main.py backend file
  Future<String?> _findBackendPath() async {
    debugPrint('Looking for main.py backend file...');

    // First check if we're in a standard path relative to the Flutter app structure
    final String currentDir = Directory.current.path;
    debugPrint('Current directory: $currentDir');

    // Compute absolute paths based on the current directory and standard project structure
    final List<String> potentialAbsolutePaths = [];

    // Try to find the project root based on common patterns
    try {
      // If we're in the Flutter app directory, go up to find project root
      if (currentDir.contains('src${Platform.pathSeparator}ui')) {
        // From src/ui to project root (where main.py likely is)
        String projectRoot = currentDir;
        while (path.basename(projectRoot) != 'ui') {
          projectRoot = path.dirname(projectRoot);
        }
        projectRoot = path.dirname(
            path.dirname(projectRoot)); // Go up two levels from ui directory

        potentialAbsolutePaths.add(path.join(projectRoot, 'main.py'));
        debugPrint('Added potential path: ${potentialAbsolutePaths.last}');
      }
    } catch (e) {
      debugPrint('Error computing project root path: $e');
    }

    // Check specific root paths based on known project structure
    try {
      // Hard-coded paths if running from known project structure
      if (Platform.isWindows) {
        potentialAbsolutePaths.addAll([
          path.join('c:', 'src', 'pixels', 'pixels', 'main.py'),
          path.join('c:', 'src', 'pixels', 'main.py'),
        ]);
      } else {
        // For macOS/Linux
        final homeDir = Platform.environment['HOME'];
        if (homeDir != null) {
          potentialAbsolutePaths.addAll([
            path.join(homeDir, 'src', 'pixels', 'pixels', 'main.py'),
            path.join(homeDir, 'src', 'pixels', 'main.py'),
          ]);
        }
      }
    } catch (e) {
      debugPrint('Error adding specific project paths: $e');
    }

    // Check relative paths from the current directory
    final potentialRelativePaths = [
      'main.py',
      '${Platform.pathSeparator}main.py',
      '..${Platform.pathSeparator}main.py',
      '..${Platform.pathSeparator}..${Platform.pathSeparator}main.py',
      '..${Platform.pathSeparator}..${Platform.pathSeparator}..${Platform.pathSeparator}main.py',
      '..${Platform.pathSeparator}..${Platform.pathSeparator}..${Platform.pathSeparator}..${Platform.pathSeparator}main.py',
    ];

    // Try absolute paths first
    for (final potentialPath in potentialAbsolutePaths) {
      final file = File(potentialPath);
      if (await file.exists()) {
        debugPrint('Found main.py at: $potentialPath');
        return potentialPath;
      }
    }

    // Then try relative paths
    for (final potentialPath in potentialRelativePaths) {
      final file = File(potentialPath);
      if (await file.exists()) {
        final absolutePath = file.absolute.path;
        debugPrint('Found main.py at: $absolutePath');
        return absolutePath;
      }
      debugPrint('Not found at: ${file.absolute.path}');
    }

    debugPrint('Failed to find main.py backend file');
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
        Uri.parse('$baseUrl/api/photos').replace(queryParameters: queryParams);
    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => Photo.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load photos: ${response.statusCode}');
    }
  }

  /// Searches photos using the given query
  Future<List<Photo>> searchPhotos({
    required String query,
    int? limit,
    int? offset,
  }) async {
    final queryParams = <String, String>{
      'query': query,
    };

    if (limit != null) queryParams['limit'] = limit.toString();
    if (offset != null) queryParams['offset'] = offset.toString();

    final uri = Uri.parse('$baseUrl/api/photos/search')
        .replace(queryParameters: queryParams);

    final response = await _client.get(uri);

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      return jsonData.map((json) => Photo.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search photos: ${response.statusCode}');
    }
  }

  /// Gets the URL for a photo thumbnail
  String getThumbnailUrl(int photoId, {bool large = false}) {
    final size = large ? 'lg' : 'sm';
    return '$baseUrl/api/thumbnails/$photoId/$size';
  }

  /// Gets a specific photo by ID
  Future<Photo> getPhoto(int photoId) async {
    final response =
        await _client.get(Uri.parse('$baseUrl/api/photos/$photoId'));

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
        Uri.parse('$baseUrl/api/folders').replace(queryParameters: queryParams);
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
      Uri.parse('$baseUrl/api/folders'),
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
    final response = await _client.get(Uri.parse('$baseUrl/api/albums'));

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
      Uri.parse('$baseUrl/api/albums'),
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
        Uri.parse('$baseUrl/api/tags').replace(queryParameters: queryParams);
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
      Uri.parse('$baseUrl/api/tags'),
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
      Uri.parse('$baseUrl/api/albums/$albumId/photos'),
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
      Uri.parse('$baseUrl/api/photos/$photoId/tags'),
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
      Uri.parse('$baseUrl/api/photos/$photoId'),
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
      uri = Uri.parse('$baseUrl/api/folders/$folderId/scan');
    } else {
      uri = Uri.parse('$baseUrl/api/folders/scan');
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
    final response = await _client.get(Uri.parse('$baseUrl/api/stats'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get stats: ${response.statusCode}');
    }
  }
}
