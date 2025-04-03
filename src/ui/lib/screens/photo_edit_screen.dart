import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' as material;
import '../models/photo.dart';
import '../services/backend_service.dart';

class PhotoEditScreen extends StatefulWidget {
  final Photo photo;

  const PhotoEditScreen({super.key, required this.photo});

  @override
  _PhotoEditScreenState createState() => _PhotoEditScreenState();
}

class _PhotoEditScreenState extends State<PhotoEditScreen> {
  final BackendService _backendService = BackendService();
  final bool _isLoading = false;
  bool _hasChanges = false;

  // Editing parameters
  double _brightness = 0.0;
  double _contrast = 0.0;
  double _saturation = 0.0;
  double _temperature = 0.0;
  double _shadows = 0.0;
  double _highlights = 0.0;
  double _rotation = 0.0;

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/logo.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 8),
            const Text('Pixels - Edit Photo',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: CommandBar(
          overflowBehavior: CommandBarOverflowBehavior.wrap,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.save),
              label: const Text('Save'),
              onPressed: _hasChanges ? _saveChanges : null,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.reset),
              label: const Text('Reset'),
              onPressed: _hasChanges ? _resetChanges : null,
            ),
            CommandBarButton(
              icon: const Icon(FluentIcons.back),
              label: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      content: ScaffoldPage(
        content: Row(
          children: [
            // Photo Preview Area
            Expanded(
              flex: 3,
              child: _buildPhotoPreview(),
            ),
            // Editing Controls Sidebar
            Expanded(
              flex: 1,
              child: _buildEditingControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPreview() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // The photo itself
            Image.network(
              _backendService.getThumbnailUrl(widget.photo.id, large: true),
              fit: BoxFit.contain,
              loadingBuilder: (ctx, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: ProgressRing());
              },
              errorBuilder: (ctx, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        FluentIcons.error,
                        size: 48,
                        color: material.Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load image: $error',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Overlay when loading
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: ProgressRing(),
                ),
              ),
            // Message explaining this is a placeholder
            Positioned(
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black.withOpacity(0.7),
                child: const Text(
                  'Non-destructive editing coming soon',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditingControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          Text(
            'Adjust',
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 16),

          // Brightness control
          _buildSliderControl(
            label: 'Brightness',
            value: _brightness,
            min: -100,
            max: 100,
            onChanged: (value) {
              setState(() {
                _brightness = value;
                _hasChanges = true;
              });
            },
          ),

          // Contrast control
          _buildSliderControl(
            label: 'Contrast',
            value: _contrast,
            min: -100,
            max: 100,
            onChanged: (value) {
              setState(() {
                _contrast = value;
                _hasChanges = true;
              });
            },
          ),

          // Saturation control
          _buildSliderControl(
            label: 'Saturation',
            value: _saturation,
            min: -100,
            max: 100,
            onChanged: (value) {
              setState(() {
                _saturation = value;
                _hasChanges = true;
              });
            },
          ),

          // Temperature control
          _buildSliderControl(
            label: 'Temperature',
            value: _temperature,
            min: -100,
            max: 100,
            onChanged: (value) {
              setState(() {
                _temperature = value;
                _hasChanges = true;
              });
            },
          ),

          // Shadows control
          _buildSliderControl(
            label: 'Shadows',
            value: _shadows,
            min: -100,
            max: 100,
            onChanged: (value) {
              setState(() {
                _shadows = value;
                _hasChanges = true;
              });
            },
          ),

          // Highlights control
          _buildSliderControl(
            label: 'Highlights',
            value: _highlights,
            min: -100,
            max: 100,
            onChanged: (value) {
              setState(() {
                _highlights = value;
                _hasChanges = true;
              });
            },
          ),

          const SizedBox(height: 24),

          Text(
            'Crop & Rotate',
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 16),

          // Rotation control
          _buildSliderControl(
            label: 'Rotation',
            value: _rotation,
            min: -45,
            max: 45,
            onChanged: (value) {
              setState(() {
                _rotation = value;
                _hasChanges = true;
              });
            },
          ),

          const SizedBox(height: 16),

          // Aspect ratio buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAspectRatioButton('Original'),
              _buildAspectRatioButton('1:1'),
              _buildAspectRatioButton('4:3'),
              _buildAspectRatioButton('16:9'),
            ],
          ),

          const SizedBox(height: 24),

          // One-click fixes
          Text(
            'Auto Fixes',
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Button(
                onPressed: () => _showComingSoonDialog('Auto Enhance'),
                child: const Text('Auto Enhance'),
              ),
              Button(
                onPressed: () => _showComingSoonDialog('Auto Color'),
                child: const Text('Auto Color'),
              ),
              Button(
                onPressed: () => _showComingSoonDialog('Auto Contrast'),
                child: const Text('Auto Contrast'),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Effects
          Text(
            'Effects',
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 16),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildEffectButton('B&W'),
              _buildEffectButton('Sepia'),
              _buildEffectButton('Vintage'),
              _buildEffectButton('Dramatic'),
              _buildEffectButton('Sharpen'),
              _buildEffectButton('Blur'),
              _buildEffectButton('Vignette'),
            ],
          ),

          const SizedBox(height: 32),

          const InfoBar(
            title: Text('Coming Soon'),
            content: Text(
                'Non-destructive editing features are under development and will be available in a future update.'),
            severity: InfoBarSeverity.info,
            isLong: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderControl({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(value.toStringAsFixed(0)),
          ],
        ),
        const SizedBox(height: 4),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAspectRatioButton(String label) {
    return Button(
      onPressed: () => _showComingSoonDialog('Aspect Ratio: $label'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(label),
      ),
    );
  }

  Widget _buildEffectButton(String label) {
    return Button(
      onPressed: () => _showComingSoonDialog('Effect: $label'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(label),
      ),
    );
  }

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Coming Soon'),
        content: Text(
            'The "$feature" feature will be available in a future update.'),
        actions: [
          Button(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _saveChanges() {
    // For now, show a coming soon dialog
    _showComingSoonDialog('Save Edits');
  }

  void _resetChanges() {
    setState(() {
      _brightness = 0.0;
      _contrast = 0.0;
      _saturation = 0.0;
      _temperature = 0.0;
      _shadows = 0.0;
      _highlights = 0.0;
      _rotation = 0.0;
      _hasChanges = false;
    });
  }
}
