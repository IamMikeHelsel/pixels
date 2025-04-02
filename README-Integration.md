# Pixels Photo Manager Integration Guide

This document describes how to run and use the integrated Pixels Photo Manager with the FastAPI backend and Flutter UI.

## System Architecture

The Pixels Photo Manager consists of two main components:

1. **Python Backend**: A FastAPI-based server that provides REST API endpoints to access and manage your photo library.
2. **Flutter Frontend**: A cross-platform UI that communicates with the backend server to display your photos and provide user interaction.

## Prerequisites

Before running the integrated system, ensure you have the following installed:

- **Python 3.8+** with pip
- **Flutter 3.0+** with Dart 2.19+
- Dependencies for both the backend and frontend

## Setup Instructions

### 1. Install Backend Dependencies

From the project root directory, install the required Python packages:

```bash
pip install -r requirements.txt
```

### 2. Install Frontend Dependencies

Navigate to the UI directory and install Flutter dependencies:

```bash
cd src/ui
flutter pub get
```

Alternatively, run the dependency check script:

```bash
cd src/ui
dart scripts/update_dependencies.dart
```

## Running the Integrated System

### Method 1: Start Components Separately

1. **Start the Backend Server**:

   From the project root directory:

   ```bash
   python main.py serve --host localhost --port 5000
   ```

   This will start the FastAPI server at `http://localhost:5000`.

2. **Start the Flutter UI**:

   Navigate to the UI directory and run:

   ```bash
   cd src/ui
   flutter run -d <device>
   ```

   Where `<device>` is your target device (chrome, windows, macos, etc.)

### Method 2: Let the Flutter App Start the Backend

The Flutter app has built-in capability to start the backend server if it's not already running:

1. Launch the Flutter app
2. If the backend isn't detected, click the "Start Backend Service" button
3. The app will automatically connect to the running service

## API Documentation

Once the backend server is running, you can access the automatic API documentation at:

- **Swagger UI**: http://localhost:5000/docs
- **ReDoc**: http://localhost:5000/redoc

## Key Features of the Integration

- **Automatic Backend Management**: The Flutter app can start/stop the Python backend if needed
- **Status Monitoring**: The app maintains connection status and provides feedback
- **Graceful Fallback**: If the backend is unavailable, the app falls back to mock data
- **Cross-Platform Support**: Works on Windows, macOS, Linux, and mobile platforms

## Folder Structure

- `src/core/api.py` - FastAPI backend server implementation
- `src/ui/lib/services/backend_service.dart` - Flutter service to communicate with backend
- `src/ui/lib/screens/` - Flutter UI screens
- `src/ui/lib/models/` - Data models shared between UI and backend

## Troubleshooting

1. **Backend Connection Issues**
   - Verify the server is running with `http://localhost:5000/api/health`
   - Check console output for error messages
   - Ensure proper network permissions if running on mobile devices

2. **Flutter App Issues**
   - Run `flutter doctor` to verify your Flutter installation
   - Ensure all dependencies are installed with `flutter pub get`
   - Check the app logs for error messages

3. **Data Not Updating**
   - Restart the backend server to ensure changes are reflected
   - Use the app's refresh functionality to reload data

## Next Steps for Development

1. **Authentication Layer**: Add user authentication to secure the API
2. **WebSocket Support**: Implement real-time updates for changes in the photo library
3. **Mobile-Optimized UI**: Enhance UI for better mobile experience
4. **Advanced Search Features**: Implement face recognition and other AI-based search features