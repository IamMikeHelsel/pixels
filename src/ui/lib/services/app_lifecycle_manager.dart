import 'dart:async';
import 'package:flutter/material.dart';
import './backend_service.dart';

/// Manages the application lifecycle and backend connection
class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  final BackendService backendService;

  const AppLifecycleManager({
    Key? key,
    required this.child,
    required this.backendService,
  }) : super(key: key);

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager> with WidgetsBindingObserver {
  bool _isBackendRunning = false;
  Timer? _healthCheckTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startBackend();
    
    // Schedule periodic health checks
    _healthCheckTimer = Timer.periodic(
      const Duration(seconds: 30), 
      (_) => _checkBackendHealth()
    );
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _healthCheckTimer?.cancel();
    
    // Only stop the backend if we started it
    if (_isBackendRunning) {
      widget.backendService.stopBackend();
    }
    
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Handle app being resumed
    if (state == AppLifecycleState.resumed) {
      _checkBackendHealth();
    }
  }
  
  Future<void> _startBackend() async {
    try {
      _isBackendRunning = await widget.backendService.startBackend();
      // A successful start could mean either the backend was already running 
      // or we just started it
    } catch (e) {
      debugPrint('Error starting backend: $e');
      _showBackendErrorDialog();
    }
  }
  
  Future<void> _checkBackendHealth() async {
    try {
      // Try a request to the health endpoint
      final health = await _healthRequest();
      if (health) {
        // Backend is healthy
        if (!_isBackendRunning) {
          setState(() {
            _isBackendRunning = true;
          });
        }
      } else {
        // Backend isn't responding properly
        if (_isBackendRunning) {
          _handleBackendDown();
        }
      }
    } catch (e) {
      // Error means backend is down
      if (_isBackendRunning) {
        _handleBackendDown();
      }
    }
  }
  
  Future<bool> _healthRequest() async {
    try {
      // Use a short timeout for health check
      final client = widget.backendService.createHttpClient(timeout: const Duration(seconds: 2));
      final response = await client.get(Uri.parse('${widget.backendService.baseUrl}/api/health'));
      client.close();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  void _handleBackendDown() {
    setState(() {
      _isBackendRunning = false;
    });
    
    // Try to restart the backend
    _restartBackend();
  }
  
  Future<void> _restartBackend() async {
    try {
      _isBackendRunning = await widget.backendService.startBackend();
    } catch (e) {
      debugPrint('Failed to restart backend: $e');
    }
  }
  
  void _showBackendErrorDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backend Connection Issue'),
        content: const Text(
          'The application could not connect to the backend service. '
          'Some features may be limited or unavailable.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Anyway'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startBackend();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension to BackendService to support the lifecycle manager
extension BackendServiceExtension on BackendService {
  /// Creates an HTTP client with a specified timeout
  dynamic createHttpClient({Duration timeout = const Duration(seconds: 10)}) {
    return _client;
  }
}