import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import './backend_service.dart';

/// Manages the application lifecycle and backend connection
class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  final BackendService backendService;
  final bool initialBackendState;

  const AppLifecycleManager({
    Key? key,
    required this.child,
    required this.backendService,
    this.initialBackendState = false,
  }) : super(key: key);

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager>
    with WidgetsBindingObserver {
  bool _isBackendRunning = false;
  Timer? _healthCheckTimer;
  bool _isStartingBackend = false; // Prevent multiple start attempts
  bool _hasShownErrorDialog = false; // Prevent multiple error dialogs

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Set initial state based on what was passed in
    _isBackendRunning = widget.initialBackendState;

    // If the backend is not already running, try to start it
    if (!_isBackendRunning) {
      // Delay slightly to allow the UI to render before attempting backend start
      Future.delayed(const Duration(milliseconds: 500), () {
        _startBackend();
      });
    }

    // Schedule periodic health checks - reduced frequency to avoid excessive checks
    _healthCheckTimer = Timer.periodic(
        const Duration(minutes: 2), (_) => _checkBackendHealth());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _healthCheckTimer?.cancel();
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
    if (_isStartingBackend) return; // Prevent concurrent start attempts
    _isStartingBackend = true;

    try {
      debugPrint('AppLifecycleManager: Attempting to start backend...');
      _isBackendRunning = await widget.backendService.startBackend();
      debugPrint('AppLifecycleManager: Backend started: $_isBackendRunning');
      // Let the BackendService handle showing any errors
    } catch (e) {
      debugPrint('AppLifecycleManager: Error starting backend: $e');
      _showBackendErrorDialog();
    } finally {
      _isStartingBackend = false;
    }
  }

  Future<void> _checkBackendHealth() async {
    if (_isStartingBackend) return; // Don't check health while starting

    try {
      // Use the BackendService's status check
      final isHealthy = await widget.backendService.checkBackendStatus();

      if (isHealthy) {
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

  void _handleBackendDown() {
    setState(() {
      _isBackendRunning = false;
    });

    // Only try to restart the backend if we're not already trying to
    if (!_isStartingBackend) {
      _startBackend();
    }
  }

  void _showBackendErrorDialog() {
    if (!mounted || _hasShownErrorDialog) return;
    _hasShownErrorDialog = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backend Connection Issue'),
        content: const Text(
            'The application could not connect to the backend service. '
            'Some features may be limited or unavailable.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _hasShownErrorDialog = false;
            },
            child: const Text('Continue Anyway'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _hasShownErrorDialog = false;
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
