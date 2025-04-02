# Pixels - Modern Photo Manager

## Overview
Pixels is a modern desktop photo management application inspired by Google Picasa, designed for photographers and casual users alike. It provides an intuitive way to import, organize, view, edit, and share digital photos across Windows, macOS, and Linux platforms.

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

## Technology Stack
- **Core Logic**: Python 3.13
- **UI Framework**: Flutter (Dart)
- **Database**: SQLite
- **Image Processing**: Pillow/Pillow-SIMD, OpenCV
- **RAW Support**: LibRaw

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

# Install dependencies
pip install -r requirements.txt

# Run the application
python main.py
```

## Development Roadmap

The project development is organized into nine phases:

1. **Foundation & Core Library Management**
   - Database schema and access layer
   - File system scanner
   - Metadata extraction
   - Library indexing

2. **Basic Viewing & Organization Backend**
   - Thumbnail generation service
   - Enhanced data access layer
   - Album management backend
   - Tagging and rating systems

3. **Basic UI & Viewing Integration**
   - UI framework setup
   - Folder/thumbnail view implementation
   - Single photo view component

4. **Non-Destructive Editing Backend**
   - Edit storage mechanism
   - Image adjustment logic
   - Edit history and revert functionality

5. **Search & Filtering Backend**
   - Keyword and metadata search
   - Combined filtering logic

6. **Duplicate Detection**
   - Exact hash calculation and matching
   - Duplicate identification and grouping
   - Duplicate management operations

7. **UI Integration**
   - Editing UI components
   - Search and filter interface
   - Organization UI elements
   - Duplicate review interface

8. **Advanced Features & Modern Enhancements**
   - RAW file support
   - People recognition
   - Geolocation features
   - Visual similarity detection
   - UI/UX polish
   - Basic video support

9. **Final Testing, Packaging & Release**
   - End-to-end testing
   - Accessibility review
   - Installer creation
   - Documentation

## Contributing

We welcome contributions to the Pixels project! See [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to get involved.

# Running

## Install dependencies
pip install -r requirements.txt

### Scan a directory for images
python main.py scan /path/to/photos --recursive

### Index a directory into the library
python main.py index /path/to/photos --recursive --monitor

### Extract metadata from a single image
python main.py extract /path/to/photos/image.jpg

### Refresh the library index (updates monitored folders)
python main.py refresh

## License

This project is licensed under the [MIT License](LICENSE).