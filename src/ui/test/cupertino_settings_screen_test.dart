import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui/screens/settings_screen.dart';

void main() {
  testWidgets('SettingsScreen uses Cupertino components', (WidgetTester tester) async {
    // Build the SettingsScreen
    await tester.pumpWidget(
      const CupertinoApp(
        home: SettingsScreen(),
      ),
    );
    
    // Verify that our SettingsScreen uses CupertinoPageScaffold
    expect(find.byType(CupertinoPageScaffold), findsOneWidget);
    
    // Check for Cupertino specific components
    expect(find.byType(CupertinoListTile), findsWidgets);
    expect(find.byType(CupertinoSwitch), findsWidgets);
    expect(find.byType(CupertinoTextField), findsOneWidget);
    expect(find.byType(CupertinoButton), findsWidgets);
    
    // Verify icons are using CupertinoIcons
    expect(find.byIcon(CupertinoIcons.cloud_download), findsOneWidget);
    expect(find.byIcon(CupertinoIcons.refresh), findsAtLeastNWidgets(1));
  });
}