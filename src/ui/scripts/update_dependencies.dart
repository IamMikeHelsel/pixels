import 'dart:io';

// A simple utility script to check backend compatibility and update
// Flutter dependencies as needed for integration with the Python backend.

void main() async {
  print('Checking Pixels integration and dependencies...');

  // Check if the Python backend is accessible
  try {
    // Check if Python is installed
    final pythonVersion = await Process.run('python', ['--version']);
    print('Python: ${pythonVersion.stdout.toString().trim()}');

    // Check if the required Python packages are installed
    final result = await Process.run('python', [
      '-c',
      'import fastapi, uvicorn; print("FastAPI and Uvicorn are installed")'
    ]);
    if (result.exitCode == 0) {
      print(result.stdout.toString().trim());
      print('✅ Backend dependencies are properly installed');
    } else {
      print('❌ Missing required Python packages. Please run:');
      print('   pip install -r requirements.txt');
    }
  } catch (e) {
    print('❌ Python check failed: $e');
    print('   Please ensure Python is installed and in your PATH');
  }

  // Check Flutter dependencies
  try {
    print('\nChecking Flutter dependencies...');

    const pubspecPath = 'pubspec.yaml';
    final pubspecFile = File(pubspecPath);
    if (!pubspecFile.existsSync()) {
      throw Exception('pubspec.yaml file not found');
    }

    final pubspecContent = await pubspecFile.readAsString();
    print('✅ pubspec.yaml found');

    // Check for required dependencies
    final requiredDeps = [
      'http',
      'shared_preferences',
      'path_provider',
      'intl',
    ];

    bool allDepsFound = true;
    for (var dep in requiredDeps) {
      if (!pubspecContent.contains('$dep:')) {
        print('❌ Missing dependency: $dep');
        allDepsFound = false;
      }
    }

    if (allDepsFound) {
      print('✅ All required Flutter dependencies are present');
    } else {
      print('Please add the missing dependencies to pubspec.yaml');
    }

    // Run Flutter pub get to ensure dependencies are installed
    print('\nUpdating Flutter dependencies...');
    final pubGet = await Process.run('flutter', ['pub', 'get']);
    if (pubGet.exitCode == 0) {
      print('✅ Flutter dependencies updated successfully');
    } else {
      print('❌ Error updating Flutter dependencies:');
      print(pubGet.stderr);
    }
  } catch (e) {
    print('❌ Flutter dependency check failed: $e');
  }

  print('\nIntegration check complete!');
}
