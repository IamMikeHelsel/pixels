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

  // Run the app - the AppLifecycleManager will handle backend startup
  runApp(PixelsApp(backendService: backendService));
}

class PixelsApp extends StatelessWidget {
  final BackendService backendService;

  const PixelsApp({
    super.key,
    required this.backendService,
  });

  @override
  Widget build(BuildContext context) {
    return AppLifecycleManager(
      backendService: backendService,
      child: StreamBuilder<bool>(
        stream: backendService.statusStream,
        initialData: false,
        builder: (context, snapshot) {
          final backendAvailable = snapshot.data ?? false;

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
