import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/screens/home_screen.dart';
import 'package:ui/services/backend_service.dart';

void main() {
  testWidgets('HomeScreen uses Cupertino components', (WidgetTester tester) async {
    // Build the HomeScreen with a mock backend service
    final mockBackendService = BackendService();
    await tester.pumpWidget(
      CupertinoApp(
        home: HomeScreen(
          backendAvailable: true,
          backendService: mockBackendService,
        ),
      ),
    );
    
    // Verify that our HomeScreen uses CupertinoTabScaffold
    expect(find.byType(CupertinoTabScaffold), findsOneWidget);
    
    // Verify that we have a CupertinoTabBar
    expect(find.byType(CupertinoTabBar), findsOneWidget);
    
    // Check that we have the expected tab items
    final CupertinoTabBar tabBar = tester.widget(find.byType(CupertinoTabBar));
    expect(tabBar.items.length, 4); // We should have 4 tabs
    
    // Verify that the tabs use CupertinoIcons
    expect(tabBar.items[0].icon, isA<Icon>());
    final Icon folderIcon = tabBar.items[0].icon as Icon;
    expect(folderIcon.icon, CupertinoIcons.folder);
  });
}