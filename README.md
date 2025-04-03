# Pixels - Modern Photo Manager

## Overview

Pixels is a modern desktop photo management application inspired by Google Picasa, designed for photographers and casual users alike. It provides an intuitive way to import, organize, view, edit, and share digital photos across Windows, macOS, and Linux platforms.

## Current Status

Pixels is currently in active development. The backend API has been implemented with core functionality including folder management, photo indexing, album organization, tagging, and thumbnail generation. The Flutter UI interface is being developed to connect with this backend.

### What's Working Now

- RESTful API with FastAPI for all core functionality
- SQLite database for photo metadata
- Folder scanning and monitoring
- Photo metadata extraction
- Tagging and album organization
- Basic thumbnail generation
- Flutter service for backend communication

### Coming Soon

- Complete UI implementation
- Non-destructive editing features
- Duplicate detection
- Face recognition
- Geolocation features

## Features

### Library Management

- **Automatic Scanning**: Scan local folders and network drives for new photos
- **Manual Import**: Import directly from cameras, memory cards, and other devices
- **Non-destructive workflow**: Original files remain untouched unless explicitly requested
- **Folder Monitoring**: Continuous monitoring of selected folders for new photos
- **Wide Format Support**: JPEG, PNG, GIF, TIFF, BMP, and popular RAW formats

### Organization

- **Folder View**: Browse photos based on their original folder structure
- **Albums**: Create virtual collections without moving original files
- **Tagging/Keywords**: Assign and organize photos with hierarchical tags
- **Ratings & Favorites**: Apply star ratings and mark favorites

### Viewing & Browsing

- **Thumbnail Grid**: Fast-loading customizable thumbnail view
- **Full-screen Mode**: Optimized viewing experience
- **Zoom & Pan**: Smooth navigation within images
- **Metadata Display**: View EXIF, IPTC, and other photo information
- **Slideshow**: Customizable transitions and timing options

### Non-destructive Editing

- **One-click Fixes**: Auto-contrast, auto-color correction
- **Manual Adjustments**: Brightness, contrast, saturation, etc.
- **Cropping & Straightening**: Adjust composition with precision
- **Basic Effects**: Apply filters and transformations
- **History & Revert**: Track changes and restore originals at any time

### Advanced Features

- **Duplicate Detection**: Find and manage duplicate photos with powerful scanning tools
- **People Recognition**: Detect and tag faces in photos
- **Geolocation**: Map-based organization of your photos
- **Search & Filtering**: Find photos by keyword, metadata, people, locations, and more
- **Sharing & Export**: Email, export with customizable options, and print

## Architecture

Pixels follows a client-server architecture:

- **Backend**: Python FastAPI server handling core logic, database operations, and file system interaction
- **Database**: SQLite for metadata storage and organization
- **Frontend**: Flutter UI that communicates with the backend via REST API
- **Services**:
  - Library Indexer: Scans folders and extracts metadata
  - Album Manager: Handles virtual photo collections
  - Tag Manager: Manages hierarchical tag system
  - Thumbnail Service: Generates and serves photo thumbnails

## Technology Stack

- **Core Logic**: Python 3.13 with FastAPI
- **UI Framework**: Flutter (Dart)
- **Database**: SQLite
- **Image Processing**: Pillow/Pillow-SIMD, OpenCV
- **RAW Support**: LibRaw (coming soon)

## Installation

### Prerequisites

- Windows 10/11, macOS, or Linux
- [Python 3.13+](https://www.python.org/downloads/)
- [Flutter](https://flutter.dev/docs/get-started/install) (for development)

### Getting Started

```bash
# Clone the repository
git clone https://github.com/yourusername/pixels.git
cd pixels

# Install Python dependencies
pip install -r requirements.txt

# Start the backend API server
python main.py serve

# In another terminal, run the Flutter UI (from the src/ui directory)
cd src/ui
flutter run
```

## API Usage

The backend provides a comprehensive REST API:

```bash
# API documentation is available at
http://localhost:5000/docs

# Health check endpoint
curl http://localhost:5000/api/health

# Get all photos
curl http://localhost:5000/api/photos

# Search photos
curl "http://localhost:5000/api/photos/search?keyword=vacation&min_rating=3"
```

## Command Line Interface

Pixels also provides a CLI for common operations:

```bash
# Start the API server
python main.py serve --host localhost --port 5000

# Add a folder to the library (will scan and index photos)
python main.py add-folder /path/to/photos --name "Vacation 2025" --monitor

# Import photos without monitoring
python main.py import /path/to/photos

# Search for photos
python main.py search --keyword sunset --min-rating 4 --favorites
```

## Development Roadmap

The project development is organized into nine phases:

1. **Foundation & Core Library Management** ✅
   - Database schema and access layer
   - File system scanner
   - Metadata extraction
   - Library indexing

2. **Basic Viewing & Organization Backend** ✅
   - Thumbnail generation service
   - Enhanced data access layer
   - Album management backend
   - Tagging and rating systems

3. **Basic UI & Viewing Integration** 🔄
   - UI framework setup
   - Folder/thumbnail view implementation
   - Single photo view component

4. **Non-Destructive Editing Backend** ⏳
   - Edit storage mechanism
   - Image adjustment logic
   - Edit history and revert functionality

5. **Search & Filtering Backend** ✅
   - Keyword and metadata search
   - Combined filtering logic

6. **Duplicate Detection** ⏳
   - Exact hash calculation and matching
   - Duplicate identification and grouping
   - Duplicate management operations

7. **UI Integration** 🔄
   - Editing UI components
   - Search and filter interface
   - Organization UI elements
   - Duplicate review interface

8. **Advanced Features & Modern Enhancements** ⏳
   - RAW file support
   - People recognition
   - Geolocation features
   - Visual similarity detection
   - UI/UX polish
   - Basic video support

9. **Final Testing, Packaging & Release** ⏳
   - End-to-end testing
   - Accessibility review
   - Installer creation
   - Documentation

Legend: ✅ Complete | 🔄 In Progress | ⏳ Planned

## Contributing

We welcome contributions to the Pixels project! See [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to get involved.

### Development Environment

For developers who want to contribute:

1. Fork the repository
2. Set up your development environment with Python 3.13+ and Flutter
3. Install development dependencies: `pip install -r requirements-dev.txt`
4. Run tests: `pytest`
5. Submit pull requests for review

## License

This project is licensed under the [MIT License](LICENSE).
