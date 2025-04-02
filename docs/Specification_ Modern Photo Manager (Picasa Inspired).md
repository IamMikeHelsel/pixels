# **Specification: Modern Photo Manager (Picasa Inspired)**

## **1\. Overview**

This document outlines the specifications for a modern desktop photo management application, drawing inspiration from the core features of Google Picasa while incorporating contemporary functionalities, including robust duplicate photo detection and removal. The target platform is desktop (Windows, macOS, Linux), with potential for future mobile companion apps (viewers).

## **2\. Goals**

* Provide an intuitive and efficient way to import, organize, view, edit, and share digital photos.  
* Offer powerful search and filtering capabilities.  
* Implement reliable duplicate photo detection and removal.  
* Ensure non-destructive editing workflows.  
* Maintain high performance, even with large photo libraries.  
* Offer a clean, modern user interface.

## **3\. Core Features (Picasa Parity)**

### **3.1. Photo Import & Library Management**

* **Automatic Scanning:** Scan specified local folders and network drives for new photos upon launch or on demand.  
* **Manual Import:** Import photos directly from cameras, memory cards, and other devices.  
* **Library Database:** Maintain a central database indexing all managed photos without moving or duplicating original files (unless explicitly requested).  
* **Folder Monitoring:** Continuously monitor selected folders for additions or removals.  
* **Supported Formats:** Support for common image formats (JPEG, PNG, GIF, TIFF, BMP) and popular RAW formats.

### **3.2. Organization**

* **Folder View:** Display photos based on their original folder structure on the disk.  
* **Albums (Virtual Collections):** Allow users to create albums containing photos from different folders without moving the original files.  
* **Tagging/Keywords:** Assign keywords or tags to photos for easy categorization and search. Support hierarchical tags.  
* **Star Ratings:** Apply star ratings (1-5) to photos.  
* **Favorites:** Mark photos as favorites.

### **3.3. Viewing & Browsing**

* **Thumbnail Grid:** Fast-loading thumbnail view with adjustable size.  
* **Single Photo View:** Full-screen or windowed view of individual photos.  
* **Zoom & Pan:** Smooth zooming and panning capabilities.  
* **Metadata Display:** Show EXIF, IPTC, and other metadata associated with photos.  
* **Slideshow Mode:** Create and view slideshows with customizable transitions, music (optional), and duration.

### **3.4. Basic Editing (Non-Destructive)**

* **One-Click Fixes:** Auto-contrast, auto-color correction.  
* **Manual Adjustments:** Brightness, contrast, saturation, highlights, shadows, temperature.  
* **Cropping:** Freeform, fixed aspect ratios (e.g., 16:9, 4:3, 1:1).  
* **Straightening:** Rotate image to correct tilted horizons.  
* **Red-Eye Removal:** Simple tool to correct red-eye.  
* **Basic Effects:** Sepia, Black & White, Sharpen, etc.  
* **History & Revert:** All edits should be non-destructive, storing changes in the database or sidecar files, allowing users to revert to the original at any time.

### **3.5. People Recognition**

* **Face Detection:** Automatically detect faces in photos.  
* **Face Tagging:** Allow users to name detected faces.  
* **People Albums:** Group photos based on tagged individuals. Suggest tags for unnamed faces based on previously tagged individuals.

### **3.6. Geolocation**

* **Geotagging:** Read existing GPS data from photo metadata. Allow users to manually add or edit location information (potentially via an integrated map interface).  
* **Map View:** Display photos on a map based on their geotags.

### **3.7. Search & Filtering**

* **Keyword Search:** Search by filename, tags, album names, folder names.  
* **Metadata Search:** Search by date taken, camera model, ISO, aperture, etc.  
* **People Search:** Search by tagged names.  
* **Location Search:** Search by place names associated with geotags.  
* **Combined Filtering:** Filter view by ratings, tags, date ranges, people, folders, etc.

### **3.8. Sharing & Exporting**

* **Email:** Option to email selected photos (resizing automatically).  
* **Export:** Export photos with options for resizing, format conversion, quality adjustment, and stripping metadata.  
* **Print:** Basic printing options with layout choices.

## **4\. Duplicate Detection & Deletion**

### **4.1. Detection Engine**

* **Scan Scope:** Ability to scan the entire library or specific folders/albums for duplicates.  
* **Detection Methods:**  
  * **Exact Match (Hash):** Identify identical files using checksum algorithms (e.g., MD5, SHA-256). This is fast and accurate for true duplicates.  
  * **Visual Similarity (Optional/Advanced):** Implement perceptual hashing (e.g., pHash, dHash) or more advanced image analysis techniques to identify visually similar photos (e.g., resized versions, slightly edited copies, burst shots). This requires more processing power.  
* **Threshold Adjustment (for Visual Similarity):** Allow users to adjust the sensitivity of visual similarity detection.

### **4.2. Review Interface**

* **Grouped Results:** Display potential duplicates side-by-side in groups.  
* **Metadata Comparison:** Clearly show key metadata (filename, date, resolution, size, location) for each photo in a duplicate group to aid comparison.  
* **Selection Assistance:** Automatically suggest which photos to keep (e.g., highest resolution, oldest/newest date, file size) based on user-configurable rules. Provide options for manual selection.  
* **Bulk Actions:** Allow users to apply actions (keep, delete) to multiple groups simultaneously.

### **4.3. Deletion Options**

* **Move to Application Trash:** Move selected duplicates to a dedicated trash area within the application, allowing for recovery.  
* **Move to System Trash:** Move selected duplicates to the operating system's trash/recycle bin.  
* **Permanent Deletion:** Option for immediate, permanent deletion (with clear warnings).

## **5\. Modern Enhancements**

* **UI/UX:** Clean, modern, intuitive user interface following platform conventions (Windows, macOS, Linux). Dark mode support.  
* **Performance:** Optimized for speed, especially library scanning, thumbnail generation, and search, even with libraries containing hundreds of thousands of photos. Utilize multi-core processing where applicable.  
* **Cloud Integration (Optional):** Offer optional integration with cloud storage providers (e.g., Google Drive, Dropbox, OneDrive) for backup or syncing library metadata/albums (not necessarily full photo sync unless explicitly designed).  
* **RAW Engine:** Use a robust, up-to-date RAW processing engine (e.g., LibRaw) for high-quality rendering of various RAW formats.  
* **Video File Support:** Basic support for viewing and organizing common video file formats (e.g., MP4, MOV, AVI), including thumbnail generation. Advanced video editing is out of scope.  
* **Accessibility:** Adherence to accessibility guidelines (WCAG).

## **6\. Non-Functional Requirements**

* **Platform:** Windows 10/11, macOS (latest two versions), popular Linux distributions (e.g., Ubuntu LTS).  
* **Stability:** High degree of stability and crash resistance.  
* **Resource Usage:** Efficient use of CPU, memory, and disk I/O.  
* **Data Integrity:** Ensure the integrity of the photo library database and prevent accidental loss of original photos or metadata.

## **7\. Future Considerations**

* Mobile companion app (iOS/Android) for viewing and remote management.  
* Advanced editing features (layers, more sophisticated filters).  
* AI-powered features (e.g., automatic tagging based on image content, smart albums).  
* Plugin architecture for extensibility.

## **8\. Technology and Tooling Considerations**

This section outlines potential technologies considered during specification. The final implementation choices may vary based on detailed design and prototyping.

1. Core Logic Language: Python 3.13  
   * Rationale: A mature, cross-platform language with a rich ecosystem ideal for backend tasks, file manipulation, and integrating specialized libraries. Its readability facilitates maintenance.  
   * Libraries: Leverage powerful libraries like Pillow (or Pillow-SIMD for performance) and OpenCV for image processing, NumPy for potential numerical operations (like in visual similarity algorithms), and standard libraries for file system interaction and hashing.  
   * Considerations: While excellent for I/O and orchestration, CPU-intensive tasks (e.g., complex image analysis for visual similarity) might require C/C++ extensions or highly optimized libraries for optimal performance.  
2. API Framework: FastAPI (Conditional)  
   * Rationale: A modern, high-performance Python web framework excellent for building APIs, featuring automatic data validation and interactive documentation (Swagger UI, ReDoc).  
   * Use Case: Primarily relevant if adopting a local client-server architecture where the UI (e.g., Flutter) communicates with a separate Python backend process via HTTP requests.  
   * Alternative: For a monolithic desktop application architecture, direct Python function/method calls between modules are simpler, faster, and avoid the overhead of a web server and network communication. FastAPI would be unnecessary in that common desktop scenario.  
3. UI Framework: Flutter (using Dart)  
   * Rationale: Enables building high-performance, natively compiled applications for mobile, web, and desktop (Windows, macOS, Linux) from a single codebase (Dart). Offers a modern, reactive UI toolkit (Material Design, Cupertino) and excellent rendering performance via the Skia graphics engine.  
   * Considerations: Requires development in Dart, separate from the Python backend. Communication between the Flutter UI and Python logic needs a defined interface, typically a local API (potentially served by FastAPI) or Foreign Function Interface (FFI) calls, adding complexity compared to an all-Python stack. Alternatives like Flet (Python wrapper for Flutter) or PyQt/PySide (mature Python bindings for Qt) exist for Python-centric UI development.  
4. Database: SQLite  
   * Rationale: A lightweight, serverless, self-contained, transactional SQL database engine. Stores the entire database as a single file on disk, making it extremely simple to deploy and manage for a desktop application. Ideal for single-user scenarios and managing metadata like tags, albums, ratings, and file paths.  
   * Considerations: Performance can degrade under high write concurrency, but this is rarely an issue for a typical single-user desktop application. For extremely large libraries or potential future multi-user/web scenarios, a client-server database (like PostgreSQL) might be considered, potentially accessed via an ORM like SQLAlchemy for abstraction. SQLite is often sufficient and simpler for this application type.