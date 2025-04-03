import 'package:flutter/material.dart'; // No need to hide CupertinoThemeData anymore
import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart'
    hide Colors; // Hide Colors from fluent_ui to avoid conflict
import 'dart:io';
import 'services/backend_service.dart';
import 'services/app_lifecycle_manager.dart';
import 'screens/home_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Try to find a specific Python path based on common installations
  String? pythonPath;
  if (Platform.isWindows) {
    // Check if Python is installed in common Windows locations
    final potentialPaths = [
      'C:\\Python39\\python.exe',
      'C:\\Python310\\python.exe',
      'C:\\Python311\\python.exe',
      'C:\\Python312\\python.exe',
      'C:\\Program Files\\Python39\\python.exe',
      'C:\\Program Files\\Python310\\python.exe',
      'C:\\Program Files\\Python311\\python.exe',
      'C:\\Program Files\\Python312\\python.exe',
      // Microsoft Store Python
      '${Platform.environment['LOCALAPPDATA']}\\Microsoft\\WindowsApps\\python.exe',
      '${Platform.environment['LOCALAPPDATA']}\\Microsoft\\WindowsApps\\python3.exe',
    ];

    for (final path in potentialPaths) {
      if (await File(path).exists()) {
        pythonPath = path;
        debugPrint('Found Python at: $pythonPath');
        break;
      }
    }
  }

  // Initialize backend service with the Python path
  final backendService = BackendService(pythonPath: pythonPath);

  // Attempt to start the backend immediately
  bool backendStarted = false;
  try {
    backendStarted = await backendService.startBackend();
    debugPrint('Backend startup attempt result: $backendStarted');
  } catch (e) {
    debugPrint('Error during initial backend startup: $e');
    // Continue with app launch even if backend fails to start
  }

  // Run the app - the AppLifecycleManager will handle ongoing backend management
  runApp(PixelsApp(
    backendService: backendService,
    initialBackendState: backendStarted,
  ));
}

class PixelsApp extends StatelessWidget {
  final BackendService backendService;
  final bool initialBackendState;

  const PixelsApp({
    super.key,
    required this.backendService,
    this.initialBackendState = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppLifecycleManager(
      backendService: backendService,
      initialBackendState: initialBackendState,
      child: StreamBuilder<bool>(
        stream: backendService.statusStream,
        initialData: initialBackendState,
        builder: (context, snapshot) {
          final backendAvailable = snapshot.data ?? initialBackendState;

          return FluentApp(
            title: 'Pixels',
            debugShowCheckedModeBanner: false,
            theme: FluentThemeData(
              accentColor: AccentColor('normal', const {
                'darkest': Color(0xFF003E92),
                'darker': Color(0xFF0E62CB),
                'dark': Color(0xFF0078D4),
                'normal': Color(0xFF0086F0),
                'light': Color(0xFF1AA1FF),
                'lighter': Color(0xFF50B6FF),
                'lightest': Color(0xFF88CCFF),
              }),
              brightness: Brightness.light,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              navigationPaneTheme: const NavigationPaneThemeData(
                backgroundColor: Colors.white,
              ),
            ),
            darkTheme: FluentThemeData(
              accentColor: AccentColor('normal', const {
                'darkest': Color(0xFF003E92),
                'darker': Color(0xFF0E62CB),
                'dark': Color(0xFF0078D4),
                'normal': Color(0xFF0086F0),
                'light': Color(0xFF1AA1FF),
                'lighter': Color(0xFF50B6FF),
                'lightest': Color(0xFF88CCFF),
              }),
              brightness: Brightness.dark,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              navigationPaneTheme: NavigationPaneThemeData(
                backgroundColor: Colors.grey[180],
              ),
            ),
            home: HomeScreen(
              backendAvailable: backendAvailable,
              backendService: backendService,
            ),
          );
        },
      ),
    );
  }
}
