import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/main.dart';
import 'package:ui/services/backend_service.dart';

void main() {
  testWidgets('App uses Cupertino theme and components', (WidgetTester tester) async {
    // Build our app with a mock backend service
    final mockBackendService = BackendService();
    await tester.pumpWidget(PixelsApp(backendService: mockBackendService));
    
    // Verify that our app uses CupertinoApp
    expect(find.byType(CupertinoApp), findsOneWidget);
    
    // Check that we're not using MaterialApp
    expect(find.byType(CupertinoApp), findsOneWidget);
    
    // The app renders with the Cupertino theme
    final CupertinoApp app = tester.widget(find.byType(CupertinoApp));
    expect(app.theme, isNotNull);
    expect(app.theme!.primaryColor, CupertinoColors.systemBlue);
  });
}