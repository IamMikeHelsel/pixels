import 'package:fluent_ui/fluent_ui.dart';
import '../services/backend_service.dart';

class DuplicateDetectionScreen extends StatefulWidget {
  const DuplicateDetectionScreen({Key? key}) : super(key: key);

  @override
  _DuplicateDetectionScreenState createState() =>
      _DuplicateDetectionScreenState();
}

class _DuplicateDetectionScreenState extends State<DuplicateDetectionScreen> {
  final BackendService _backendService = BackendService();
  bool _isScanning = false;
  bool _hasResults = false;
  final List<DuplicateGroup> _duplicateGroups = [];

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: const PageHeader(
        title: Text('Duplicate Detection'),
      ),
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isScanning) {
      return _buildScanningView();
    }

    if (_hasResults) {
      return _buildResultsView();
    }

    return _buildInitialView();
  }

  Widget _buildInitialView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            FluentIcons.merge_duplicate,
            size: 64,
            color: Colors.grey[130],
          ),
          const SizedBox(height: 24),
          Text(
            'Find Duplicate Photos',
            style: FluentTheme.of(context).typography.title,
          ),
          const SizedBox(height: 16),
          Text(
            'Scan your photo library to find and manage duplicate photos.',
            style: FluentTheme.of(context).typography.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton(
                onPressed: _startExactDuplicateScan,
                child: const Text('Find Exact Duplicates'),
              ),
              const SizedBox(width: 16),
              Button(
                onPressed: _startSimilarPhotoScan,
                child: const Text('Find Similar Photos'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Note: Exact duplicates are based on file hash. Similar photos detection uses visual analysis.',
            style: FluentTheme.of(context).typography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildScanningView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const ProgressRing(),
          const SizedBox(height: 32),
          Text(
            'Scanning for duplicates...',
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 16),
          const Text(
              'This may take several minutes depending on your library size.'),
        ],
      ),
    );
  }

  Widget _buildResultsView() {
    if (_duplicateGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FluentIcons.check_mark,
              size: 64,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              'No duplicates found',
              style: FluentTheme.of(context).typography.title,
            ),
            const SizedBox(height: 16),
            const Text(
                'Your photo library does not contain any duplicate photos.'),
            const SizedBox(height: 24),
            Button(
              onPressed: _resetScan,
              child: const Text('Back'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                'Found ${_duplicateGroups.length} groups of duplicate photos',
                style: FluentTheme.of(context).typography.subtitle,
              ),
              const Spacer(),
              Button(
                onPressed: _resetScan,
                child: const Text('New Scan'),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: _duplicateGroups.length,
            itemBuilder: (context, index) {
              return _buildDuplicateGroupItem(_duplicateGroups[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDuplicateGroupItem(DuplicateGroup group) {
    // Placeholder widget for duplicate group item
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${group.photos.length} duplicate photos',
            style: FluentTheme.of(context).typography.subtitle,
          ),
          const SizedBox(height: 8),
          Text('Hash: ${group.fileHash}'),
          const SizedBox(height: 16),
          const Text('This feature will be implemented in a future update.'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Button(
                onPressed: () {},
                child: const Text('Keep Best'),
              ),
              const SizedBox(width: 8),
              Button(
                onPressed: () {},
                child: const Text('Compare'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startExactDuplicateScan() {
    // Show a dialog explaining that this is a placeholder
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Feature Coming Soon'),
        content: const Text(
          'The duplicate detection feature is currently being developed and will be available in a future update.',
        ),
        actions: [
          Button(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // For demo purposes, simulate a scan with mock data
    // setState(() {
    //   _isScanning = true;
    // });
    //
    // Future.delayed(const Duration(seconds: 3), () {
    //   setState(() {
    //     _isScanning = false;
    //     _hasResults = true;
    //     _duplicateGroups.clear();
    //     // Add mock data here if needed for UI testing
    //   });
    // });
  }

  void _startSimilarPhotoScan() {
    showDialog(
      context: context,
      builder: (context) => ContentDialog(
        title: const Text('Advanced Feature Coming Soon'),
        content: const Text(
          'Similar photo detection is an advanced feature that will be implemented in a future version. This will use visual similarity algorithms to find photos that look alike but aren\'t exact duplicates.',
        ),
        actions: [
          Button(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetScan() {
    setState(() {
      _isScanning = false;
      _hasResults = false;
      _duplicateGroups.clear();
    });
  }
}

/// Model class representing a group of duplicate photos
class DuplicateGroup {
  final String fileHash;
  final List<DuplicatePhoto> photos;

  DuplicateGroup({
    required this.fileHash,
    required this.photos,
  });
}

/// Model class representing a photo in a duplicate group
class DuplicatePhoto {
  final int id;
  final String fileName;
  final String filePath;
  final DateTime? dateTaken;
  final int? width;
  final int? height;
  final int? fileSize;

  DuplicatePhoto({
    required this.id,
    required this.fileName,
    required this.filePath,
    this.dateTaken,
    this.width,
    this.height,
    this.fileSize,
  });
}
