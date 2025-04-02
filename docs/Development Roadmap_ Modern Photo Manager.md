## **Development Roadmap: Modern Photo Manager (Picasa Inspired)**

This roadmap outlines the development phases for the photo manager, emphasizing component-based development and testability, aligning with the provided specification.

**Development Philosophy:**

* **Component-Based:** Develop features as distinct, reusable components (e.g., backend logic modules, UI widgets).  
* **Interface-Driven:** Define clear interfaces between components early. If using a separate UI framework (like Flutter) and backend (Python), define API contracts (e.g., using FastAPI or FFI). For monolithic apps, define clear Python module interfaces.  
* **Test-Centric:** Implement unit tests for isolated component logic, integration tests for component interactions (e.g., Scanner \-\> Database), and end-to-end tests for user workflows.

**Roadmap Phases:**

Phase 1: Foundation & Core Library Management  
Goal: Establish basic data storage and photo discovery.

1. **Database Schema & Access:**  
   * **Component:** SQLite schema definition (Python models/SQL scripts for photos, folders, metadata, albums, tags, ratings). Basic Data Access Layer (DAL) for CRUD.  
   * **Testing:** Unit tests for schema creation, DAL operations (create, read, update, delete).  
2. **File System Scanner:**  
   * **Component:** Python module to scan specified directories for image files (JPEG, PNG initially).  
   * **Testing:** Unit tests using mock file systems; test edge cases (empty folders, unsupported files).  
3. **Basic Metadata Extraction:**  
   * **Component:** Python module using libraries (e.g., Pillow, ExifRead) for essential metadata (Date Taken, Dimensions).  
   * **Testing:** Unit tests with diverse sample images.  
4. **Library Indexing Service:**  
   * **Component:** Python service coordinating Scanner and Metadata Extractor to populate the SQLite DB via the DAL. Handles initial scan and basic updates (detecting new files).  
   * **Testing:** Integration tests: Scan mock directory \-\> Verify DB state via DAL. Test re-scans.

Phase 2: Basic Viewing & Organization Backend  
Goal: Enable backend logic for browsing and organizing.

1. **Thumbnail Generation Service:**  
   * **Component:** Python function/service (Pillow/Pillow-SIMD) generating/caching thumbnails. Store cache info via DAL.  
   * **Testing:** Unit tests for thumbnail creation; performance tests.  
2. **Enhanced DAL / API Endpoints:**  
   * **Component:** Extend DAL (or create API endpoints if using client-server model) for querying photos by folder, retrieving details/thumbnails.  
   * **Testing:** Unit tests for new queries; integration tests verifying data retrieval based on Phase 1 indexing.  
3. **Album Management Backend:**  
   * **Component:** Backend logic (using DAL) for creating/deleting virtual albums and managing photo associations.  
   * **Testing:** Unit tests for album logic; integration tests verifying DB state after operations.  
4. **Tagging & Rating Backend:**  
   * **Component:** Backend logic (using DAL) for applying/removing tags and ratings.  
   * **Testing:** Unit tests for tag/rating functions; integration tests verifying DB updates.

Phase 3: Basic UI & Viewing Integration  
Goal: Provide a minimal visual interface.

1. **UI Framework Setup:**  
   * **Component:** Initialize UI project (e.g., Flutter, PyQt). Set up backend communication (API client or direct calls).  
   * **Testing:** Basic UI build test; test backend communication channel.  
2. **Folder/Thumbnail View UI:**  
   * **Component:** UI screen displaying folders/thumbnails fetched from the backend. Adjustable thumbnail size.  
   * **Testing:** UI tests (manual/automated); integration tests verifying UI displays data from backend correctly.  
3. **Single Photo View UI:**  
   * **Component:** UI screen displaying a single photo \+ basic metadata. Basic zoom/pan.  
   * **Testing:** UI tests for image loading, metadata display, zoom/pan.

Phase 4: Non-Destructive Editing Backend  
Goal: Implement core editing logic without modifying originals.

1. **Edit Storage Mechanism:**  
   * **Component:** Define and implement edit storage (DB parameters or sidecar files). Update DAL/Schema.  
   * **Testing:** Unit tests verifying edit parameter storage/retrieval.  
2. **Image Adjustment Logic:**  
   * **Component:** Python functions (Pillow/OpenCV) for adjustments (Crop, Straighten, Brightness, Contrast, etc.). Takes original path \+ parameters, returns adjusted image data *in memory*.  
   * **Testing:** Unit tests for each adjustment; visual verification.  
3. **Edit History & Revert Logic:**  
   * **Component:** Backend logic (using DAL) to track/retrieve edit history and revert changes.  
   * **Testing:** Unit tests for applying/reverting edits; integration tests ensuring original is preserved.

Phase 5: Search & Filtering Backend  
Goal: Implement robust search capabilities.

1. **Keyword & Metadata Search:**  
   * **Component:** Enhance DAL/API for searching by filename, tags, metadata fields. Utilize DB indexing (SQLite FTS).  
   * **Testing:** Unit tests for search queries; integration tests verifying results against known DB content.  
2. **Combined Filtering Logic:**  
   * **Component:** Backend logic to combine multiple filters (ratings, tags, dates, folders).  
   * **Testing:** Integration tests applying combined filters and verifying results.

Phase 6: Duplicate Detection (Exact Matches)  
Goal: Find and manage identical file duplicates.

1. **Exact Hash Calculation:**  
   * **Component:** Python module (hashlib) to calculate/store file hashes via DAL.  
   * **Testing:** Unit tests for hashing; integration test ensuring hashes are stored during indexing.  
2. **Duplicate Identification Logic:**  
   * **Component:** Backend service querying DAL for duplicate hashes and grouping photos.  
   * **Testing:** Integration tests with known duplicates, verifying correct grouping.  
3. **Duplicate Deletion Backend:**  
   * **Component:** Backend logic for deletion options (internal trash, system trash, permanent delete) interacting with the file system and DAL.  
   * **Testing:** Unit tests for deletion methods (mock file system); integration tests verifying file operations and DB updates.

Phase 7: UI Integration (Editing, Search, Duplicates, Org)  
Goal: Connect backend features to a functional UI.

1. **Editing UI:**  
   * **Component:** UI controls for edits, preview generation (calling backend), saving/reverting.  
   * **Testing:** UI tests; end-to-end tests (UI edit \-\> Backend processing \-\> Verify result).  
2. **Search & Filter UI:**  
   * **Component:** UI elements (search bar, filter panel) triggering backend queries and displaying results.  
   * **Testing:** UI tests; end-to-end tests (UI input \-\> Backend query \-\> Verify UI display).  
3. **Organization UI:**  
   * **Component:** UI for managing albums, tags, ratings.  
   * **Testing:** UI tests; end-to-end tests verifying UI actions update backend state.  
4. **Duplicate Review UI:**  
   * **Component:** UI for side-by-side duplicate comparison, selection, and triggering deletion actions.  
   * **Testing:** UI tests; end-to-end tests (Scan \-\> Review \-\> Delete \-\> Verify backend action).

Phase 8: Advanced Features & Modern Enhancements  
Goal: Add features beyond core parity and refine.

1. **RAW File Support:**  
   * **Component:** Integrate RAW library (e.g., LibRaw). Update relevant backend components (Scanner, Metadata, Thumbnailer, Viewer logic).  
   * **Testing:** Test with various RAW formats; ensure editing compatibility.  
2. **People Recognition Backend:**  
   * **Component:** Integrate face detection/recognition library. Implement tagging/grouping logic via DAL.  
   * **Testing:** Unit tests for detection; integration tests for tagging/grouping.  
3. **Geolocation Backend:**  
   * **Component:** Extend metadata extraction for GPS. Add DB fields/DAL support. Implement manual tagging logic. Add location query support.  
   * **Testing:** Test with geotagged images, manual tagging, location queries.  
4. **Visual Similarity Duplicates (Optional):**  
   * **Component:** Implement perceptual hashing (pHash/dHash). Add comparison logic.  
   * **Testing:** Test with visually similar images; tune threshold.  
5. **UI/UX Polish & Performance:**  
   * **Component:** Implement dark mode, refine UI according to platform conventions. Profile and optimize bottlenecks.  
   * **Testing:** UI/UX reviews, performance profiling.  
6. **Video File Support (Basic):**  
   * **Component:** Extend backend (Scanner, Indexer, Thumbnailer) and UI for basic video handling.  
   * **Testing:** Test with common video formats.

Phase 9: Final Testing, Packaging & Release  
Goal: Prepare for deployment.

1. **End-to-End Testing:** Comprehensive workflow testing on all target platforms (Windows, macOS, Linux). Focus on stability, resource usage, data integrity.  
2. **Accessibility Review:** Ensure compliance with WCAG or platform guidelines.  
3. **Packaging:** Create installers/packages.  
4. **Documentation:** User guides.

This component-focused roadmap allows for incremental development and testing, ensuring each piece works correctly before integrating it into the larger system.