"""
Library Indexing Service for the Pixels photo manager application.

This module coordinates the Scanner and Metadata Extractor components
to populate the database with photos and their metadata.
"""

import hashlib
import logging
import os
import time
from concurrent.futures import ThreadPoolExecutor
from typing import Dict, List, Tuple

# Import our other components
from .database import PhotoDatabase
from .metadata_extractor import MetadataExtractor
from .scanner import FileSystemScanner

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class LibraryIndexer:
    """
    Service to index photos into the library database.
    
    This class coordinates the scanner, metadata extractor, and database
    to create and maintain the photo library index.
    """

    def __init__(self, db_path: str = None, max_workers: int = 4):
        """
        Initialize the library indexer.
        
        Args:
            db_path: Path to the database file (optional)
            max_workers: Maximum number of worker threads for parallel processing
        """
        self.db = PhotoDatabase(db_path)
        self.scanner = FileSystemScanner()
        self.metadata_extractor = MetadataExtractor()
        self.max_workers = max_workers

    def index_folder(self, folder_path: str, recursive: bool = True, monitor: bool = False) -> Tuple[int, int, float]:
        """Index a folder with improved clarity and exception handling."""
        start_time = time.time()
        folders_added = 0
        photos_added = 0
        try:
            scan_results = self.scanner.scan_directory(folder_path, recursive=recursive)
            folder_id = self.db.add_folder(folder_path, name=os.path.basename(folder_path), parent_id=None, is_monitored=monitor)
            if folder_id is not None:
                folders_added += 1

            for dir_path, image_files in scan_results.items():
                if not image_files:
                    continue
                current_folder_record = self.db.get_folder_by_path(dir_path)
                current_folder_id = current_folder_record["id"] if current_folder_record else folder_id
                image_paths = [os.path.join(dir_path, fname) for fname in image_files]
                photos_added += self._process_images(image_paths, current_folder_id)
        except Exception as exc:
            logger.error(f"Indexing failed for {folder_path}: {exc}")
            return 0, 0, 0.0
        elapsed = time.time() - start_time
        logger.info(f"Indexed folder '{folder_path}' in {elapsed:.2f}s, added {folders_added} folder(s), {photos_added} photo(s).")
        return folders_added, photos_added, elapsed

    def refresh_index(self) -> Tuple[int, int, float]:
        """
        Refresh the entire index by scanning all monitored folders.
        
        Returns:
            Tuple of (folders_updated, photos_added, time_taken)
        """
        start_time = time.time()
        folders_updated = 0
        photos_added = 0

        # Get all monitored folders
        monitored_folders = self._get_monitored_folders()

        for folder_dict in monitored_folders:
            folder_path = folder_dict["path"]
            folder_id = folder_dict["id"]

            # Skip if folder no longer exists
            if not os.path.exists(folder_path):
                continue

            # Update folder scan date
            self.db.update_folder(folder_id, date_scanned="datetime('now')")
            folders_updated += 1

            # Get existing photos in this folder
            existing_photos = self.db.get_photos_by_folder(folder_id)
            existing_paths = {photo["file_path"] for photo in existing_photos}

            # Scan folder for current images
            scan_result = self.scanner.scan_directory(folder_path, recursive=False)

            for dir_path, image_files in scan_result.items():
                current_paths = [os.path.join(dir_path, filename) for filename in image_files]
                new_files = [path for path in current_paths if path not in existing_paths]

                # Add new files to the database
                if new_files:
                    added = self._process_images(new_files, folder_id)
                    photos_added += added

        elapsed_time = time.time() - start_time
        logger.info(
            f"Index refresh complete: {folders_updated} folders updated, {photos_added} new photos in {elapsed_time:.2f} seconds")

        return (folders_updated, photos_added, elapsed_time)

    def _process_images(self, image_paths: List[str], folder_id: int) -> int:
        """
        Process a list of images and add them to the database.
        
        Args:
            image_paths: List of image file paths
            folder_id: ID of the folder containing the images
        
        Returns:
            Number of photos successfully added
        """
        added = 0

        # Process in parallel using a thread pool
        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            # Create a function to process each image
            def process_image(image_path):
                # Check if photo already exists
                existing = self.db.get_photo_by_path(image_path)
                if existing:
                    logger.debug(f"Photo already exists in database: {image_path}")
                    return False

                try:
                    # Extract metadata
                    metadata = self.metadata_extractor.extract_metadata(image_path)

                    # Calculate file hash for deduplication (can be used in later phases)
                    file_hash = self._calculate_file_hash(image_path)
                    metadata["file_hash"] = file_hash

                    # Log metadata for debugging
                    logger.debug(f"Adding photo to database: {image_path}, metadata: {metadata}")

                    # Add to database
                    photo_id = self.db.add_photo(image_path, folder_id, **metadata)
                    return photo_id is not None
                except Exception as e:
                    logger.error(f"Error processing image {image_path}: {str(e)}")
                    return False

            # Submit all tasks and gather results
            results = list(executor.map(process_image, image_paths))
            added = sum(1 for result in results if result)

        return added

    def _get_monitored_folders(self) -> List[Dict]:
        """Get all folders marked for monitoring."""
        cursor = self.db.conn.cursor()
        cursor.execute('SELECT * FROM folders WHERE is_monitored = 1')
        return [dict(row) for row in cursor.fetchall()]

    def _calculate_file_hash(self, file_path: str, block_size: int = 65536) -> str:
        """
        Calculate SHA-256 hash of a file for deduplication purposes.
        
        Args:
            file_path: Path to the file
            block_size: Size of blocks to read
            
        Returns:
            Hexadecimal string representation of the hash
        """
        hasher = hashlib.sha256()
        with open(file_path, 'rb') as f:
            for block in iter(lambda: f.read(block_size), b''):
                hasher.update(block)
        return hasher.hexdigest()

    def identify_duplicates(self) -> List[Dict]:
        """
        Identify and group duplicate photos in the library.

        Returns:
            List of dictionaries where each dictionary represents a group of duplicate photos.
        """
        return self.db.find_duplicates()
