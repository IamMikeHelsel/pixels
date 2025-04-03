import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material
    show Colors, FloatingActionButton, Material, InkWell, FilledButton;
import 'dart:async';
import '../models/photo.dart';
import '../services/backend_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final BackendService _backendService = BackendService();
  final TextEditingController _searchController = TextEditingController();
  List<Photo> _searchResults = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce logic to avoid excessive API calls
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchController.text.length >= 2) {
        _performSearch(_searchController.text);
      } else if (_searchController.text.isEmpty) {
        setState(() {
          _searchResults = [];
          _isLoading = false;
          _errorMessage = null;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
      _searchResults = [];
      _errorMessage = null;
    });

    try {
      final results = await _backendService.searchPhotos(
        searchQuery: query,
        // Add more search parameters if needed
      );

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });

      // Log search diagnostics
      print('Search query "$query" returned ${results.length} results');
    } catch (e) {
      print('Search error: $e');
      setState(() {
        _errorMessage = 'Search failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: Row(
          children: [
            Image.asset('assets/logo.png', width: 24, height: 24),
            const SizedBox(width: 8),
            const Text('Pixels - Search',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Improved search bar with more descriptive placeholder
            TextBox(
              controller: _searchController,
              placeholder: 'Search by title, date, location or keywords...',
              prefix: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(FluentIcons.search),
              ),
              suffix: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(FluentIcons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchResults = [];
                        });
                      },
                    )
                  : null,
              onSubmitted: (value) => _performSearch(value),
            ),

            const SizedBox(height: 16),

            // Show loading indicator when searching
            if (_isLoading)
              const Center(
                child: Column(
                  children: [
                    SizedBox(height: 32),
                    ProgressRing(),
                    SizedBox(height: 16),
                    Text('Searching...'),
                  ],
                ),
              ),

            // Rest of the widget remains similar
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(child: ProgressRing());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FluentIcons.error, size: 48, color: material.Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!),
            const SizedBox(height: 16),
            Button(
              onPressed: () => _performSearch(_searchController.text),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      if (_searchController.text.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(FluentIcons.search,
                  size: 64, color: material.Colors.grey[130]),
              const SizedBox(height: 16),
              Text(
                'Enter keywords to search for photos',
                style: TextStyle(
                  color: material.Colors.grey[100],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Try searching by date, location, people, or keywords',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        );
      } else {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                  FluentIcons
                      .search_and_apps, // Replace search_not_found with available icon
                  size: 64,
                  color: material.Colors.grey[130]),
              const SizedBox(height: 16),
              Text(
                'No photos found matching "${_searchController.text}"',
                style: TextStyle(
                  color: material.Colors.grey[100],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              material.FilledButton(
                child: const Text('Try different keywords'),
                onPressed: () {
                  _searchController.clear();
                  FocusScope.of(context).requestFocus(FocusNode());
                },
              ),
            ],
          ),
        );
      }
    }

    // Display results in a grid
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final photo = _searchResults[index];
        return _buildPhotoThumbnail(photo);
      },
    );
  }

  Widget _buildPhotoThumbnail(Photo photo) {
    // Use Material Card instead of Fluent Card to avoid conflict
    return material.Material(
      borderRadius: BorderRadius.circular(4.0),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail image
          Image.network(
            _backendService.getThumbnailUrl(photo.id),
            fit: BoxFit.cover,
            errorBuilder: (ctx, error, stackTrace) {
              return Container(
                color: material.Colors.grey,
                child: const Icon(
                  FluentIcons.picture, // Replace image_off with available icon
                  color: material.Colors.white,
                ),
              );
            },
            loadingBuilder: (ctx, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: material.Colors.grey[30],
                child: const Center(child: ProgressRing()),
              );
            },
          ),

          // Make the image clickable
          material.InkWell(
            onTap: () {
              // Display info about opening the photo
              displayInfoBar(
                context,
                builder: (context, close) {
                  return InfoBar(
                    title: Text('Opening photo: ${photo.fileName}'),
                    action: IconButton(
                      icon: const Icon(FluentIcons.clear),
                      onPressed: close,
                    ),
                  );
                },
              );

              // Here we would navigate to the photo details view
            },
          ),

          // Rating and favorite indicators
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              color: material.Colors.black.withOpacity(0.5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (photo.rating != null && photo.rating! > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        photo.rating!,
                        (index) => const Icon(
                          FluentIcons.favorite_star,
                          size: 16,
                          color: material.Colors.yellow,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (photo.isFavorite)
                    const Icon(
                      FluentIcons
                          .heart_fill, // Replace favorite_solid with heart_fill
                      size: 16,
                      color: material.Colors.red,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
