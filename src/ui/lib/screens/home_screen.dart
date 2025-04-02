import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import 'folder_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BackendService _backendService = BackendService();
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pixels Photo Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search functionality coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Implement settings screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar navigation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _isSidebarCollapsed ? 60 : 240,
            child: Card(
              margin: const EdgeInsets.all(8.0),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  // Sidebar header with collapse button
                  Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (!_isSidebarCollapsed) 
                          const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('Library', 
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        IconButton(
                          icon: Icon(
                            _isSidebarCollapsed 
                              ? Icons.chevron_right 
                              : Icons.chevron_left
                          ),
                          onPressed: () {
                            setState(() {
                              _isSidebarCollapsed = !_isSidebarCollapsed;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Navigation items
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildNavItem(0, Icons.folder, 'Folders'),
                        _buildNavItem(1, Icons.photo_album, 'Albums'),
                        _buildNavItem(2, Icons.star, 'Favorites'),
                        _buildNavItem(3, Icons.label, 'Tags'),
                        _buildNavItem(4, Icons.people, 'People'),
                        const Divider(),
                        _buildNavItem(5, Icons.find_duplicate, 'Find Duplicates'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Main content area
          Expanded(
            child: _buildContentArea(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement add functionality (import photos, create album, etc.)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Import functionality coming soon')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected 
          ? Theme.of(context).colorScheme.primary 
          : null,
      ),
      title: _isSidebarCollapsed 
        ? null 
        : Text(
            title,
            style: TextStyle(
              color: isSelected 
                ? Theme.of(context).colorScheme.primary 
                : null,
              fontWeight: isSelected 
                ? FontWeight.bold 
                : null,
            ),
          ),
      selected: isSelected,
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }
  
  Widget _buildContentArea() {
    // Return different content based on selected navigation item
    switch (_selectedIndex) {
      case 0: // Folders
        return const FolderView();
      case 1: // Albums
        return const Center(child: Text('Albums View - Coming Soon'));
      case 2: // Favorites
        return const Center(child: Text('Favorites View - Coming Soon'));
      case 3: // Tags
        return const Center(child: Text('Tags View - Coming Soon'));
      case 4: // People
        return const Center(child: Text('People View - Coming Soon'));
      case 5: // Find Duplicates
        return const Center(child: Text('Duplicate Detection - Coming Soon'));
      default:
        return const Center(child: Text('Select an option from the sidebar'));
    }
  }
}