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
  await backendService.startBackend();

  // Run the app
  runApp(PixelsApp());
}

class PixelsApp extends StatelessWidget {
  const PixelsApp({super.key});

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
      home: HomeScreen(),
    );
  }
}
