import 'package:flutter/material.dart' hide CupertinoThemeData;
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
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

  // Initialize backend service
  final backendService = BackendService();

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

          return CupertinoApp(
            title: 'Pixels',
            debugShowCheckedModeBanner: false,
            theme: const CupertinoThemeData(
              primaryColor: CupertinoColors.systemBlue,
              brightness: Brightness.light,
              scaffoldBackgroundColor: CupertinoColors.systemBackground,
              textTheme: CupertinoTextThemeData(
                primaryColor: CupertinoColors.systemBlue,
              ),
            ),
            home: HomeScreen(
              backendAvailable: backendAvailable,
              backendService: backendService,
            ),
            localizationsDelegates: const [
              DefaultMaterialLocalizations.delegate,
              DefaultCupertinoLocalizations.delegate,
              DefaultWidgetsLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }
}
