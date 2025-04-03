import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/backend_service.dart';
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

  // Initialize backend service
  final backendService = BackendService();
  bool backendStarted = false;

  try {
    // Try to start the backend, but don't prevent the app from launching if it fails
    backendStarted = await backendService.startBackend();
    print('Backend service started successfully: $backendStarted');
  } catch (e) {
    // Log the error but continue with the app
    print('Error starting backend service: $e');
    print('The app will continue in limited functionality mode.');
  }

  // Run the app
  runApp(PixelsApp(
    backendAvailable: backendStarted,
    backendService: backendService,
  ));
}

class PixelsApp extends StatelessWidget {
  final bool backendAvailable;
  final BackendService backendService;

  const PixelsApp({
    super.key,
    this.backendAvailable = false,
    required this.backendService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pixels',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Use the newer Material 3 design system
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Use the newer Material 3 design system
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // Follow system theme
      home: HomeScreen(
        backendAvailable: backendAvailable,
        backendService: backendService,
      ),
    );
  }
}
