import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import '../services/log_service.dart';
import '../services/backend_service.dart';
import 'dart:io';

class TopMenuBar extends StatelessWidget {
  final BackendService backendService;

  const TopMenuBar({
    super.key,
    required this.backendService,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      color: FluentTheme.of(context).menuColor,
      child: Row(
        children: [
          _buildMenu(
            context,
            'File',
            [
              _MenuItem(
                'Open Folder...',
                FluentIcons.folder_open,
                () => _showOpenFolderDialog(context),
              ),
              _MenuItem(
                'Import Photos...',
                FluentIcons.photo_collection,
                () => _showImportDialog(context),
              ),
              _MenuItem(
                'Exit',
                FluentIcons.chrome_close,
                () => exit(0),
              ),
            ],
          ),
          _buildMenu(
            context,
            'Edit',
            [
              _MenuItem(
                'Select All',
                FluentIcons.select_all,
                () => LogService().log('Select All action'),
              ),
              _MenuItem(
                'Preferences',
                FluentIcons.settings,
                () => Navigator.of(context).pushNamed('/settings'),
              ),
            ],
          ),
          _buildMenu(
            context,
            'About',
            [
              _MenuItem(
                'About Pixels',
                FluentIcons.info,
                () => _showAboutDialog(context),
              ),
              _MenuItem(
                'Check for Updates',
                FluentIcons.download,
                () => LogService().log('Checking for updates...'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context, String title, List<_MenuItem> items) {
    return FlyoutTarget(
      child: GestureDetector(
        onTap: () {
          final List<Widget> menuItems = items.map((item) {
            return MenuFlyoutItem(
              text: Text(item.title),
              leading: Icon(item.icon, size: 16),
              onPressed: item.onPressed,
            );
          }).toList();

          // Add proper dividers
          for (int i = menuItems.length - 2; i >= 0; i--) {
            menuItems.insert(i + 1, const MenuFlyoutSeparator());
          }

          Flyout.showAt(
            context: context,
            builder: (context) {
              return MenuFlyout(items: menuItems);
            },
            target: (context) {
              return const Rect.fromLTWH(0, 30, 100, 0);
            },
            showMode: FlyoutShowMode.standard,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Center(child: Text(title)),
        ),
      ),
    );
  }

  void _showOpenFolderDialog(BuildContext context) {
    LogService().log('Opening folder dialog...');
    // Implementation would be added here
  }

  void _showImportDialog(BuildContext context) {
    LogService().log('Opening import dialog...');
    // Implementation would be added here
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('About Pixels'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pixels Photo Manager v1.0.0'),
            SizedBox(height: 8),
            Text('A modern photo management application'),
            SizedBox(height: 16),
            Text('© 2025 Pixels Team'),
          ],
        ),
        actions: [
          Button(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onPressed;

  _MenuItem(this.title, this.icon, this.onPressed);
}
