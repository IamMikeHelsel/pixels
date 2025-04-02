"""
File System Scanner module for the Pixels photo manager application.

This module provides functionality to scan directories for image files.
"""

import logging
import os
import pathlib
import time
from typing import Dict, List

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class FileSystemScanner:
    """Scanner for finding image files in the file system."""

    # Supported file extensions for images
    SUPPORTED_EXTENSIONS = {
        '.jpg', '.jpeg', '.png', '.gif', '.tiff', '.tif', '.bmp',
        # RAW formats will be added in a future phase
    }

    def __init__(self):
        """Initialize the scanner."""
        pass

    def scan_directory(self, directory_path: str, recursive: bool = True) -> Dict[str, List[str]]:
        """
        Scan a directory for image files.
        
        Args:
            directory_path: The path to the directory to scan.
            recursive: Whether to scan subdirectories recursively.
        
        Returns:
            A dictionary with folder paths as keys and lists of image file paths as values.
        """
        if not os.path.exists(directory_path):
            logger.error(f"Directory does not exist: {directory_path}")
            return {}

        if not os.path.isdir(directory_path):
            logger.error(f"Path is not a directory: {directory_path}")
            return {}

        result = {}
        start_time = time.time()

        # Walk the directory tree
        for root, dirs, files in os.walk(directory_path):
            image_files = []

            for file in files:
                file_path = os.path.join(root, file)
                if self._is_supported_image(file_path):
                    image_files.append(file_path)

            if image_files:
                result[root] = image_files

            # If not recursive, don't process subdirectories
            if not recursive:
                break

        scan_time = time.time() - start_time
        logger.info(
            f"Scan completed in {scan_time:.2f} seconds, found {self._count_total_images(result)} images in {len(result)} folders")

        return result

    def scan_directories(self, directory_paths: List[str], recursive: bool = True) -> Dict[str, List[str]]:
        """
        Scan multiple directories for image files.
        
        Args:
            directory_paths: List of directory paths to scan.
            recursive: Whether to scan subdirectories recursively.
        
        Returns:
            A dictionary with folder paths as keys and lists of image file paths as values.
        """
        result = {}

        for directory in directory_paths:
            scan_result = self.scan_directory(directory, recursive)
            result.update(scan_result)

        return result

    def _is_supported_image(self, file_path: str) -> bool:
        """Check if the file is a supported image type."""
        return pathlib.Path(file_path).suffix.lower() in self.SUPPORTED_EXTENSIONS

    def _count_total_images(self, scan_result: Dict[str, List[str]]) -> int:
        """Count the total number of images found in the scan result."""
        return sum(len(files) for files in scan_result.values())


# Helper function to get a formatted summary of scan results
def get_scan_summary(scan_result: Dict[str, List[str]]) -> str:
    """
    Generate a human-readable summary of scan results.
    
    Args:
        scan_result: The dictionary returned by scan_directory or scan_directories.
    
    Returns:
        A formatted string summarizing the scan results.
    """
    total_folders = len(scan_result)
    total_images = sum(len(files) for files in scan_result.values())

    summary = f"Scan found {total_images} images in {total_folders} folders\n\n"

    for folder, images in scan_result.items():
        summary += f"{folder}: {len(images)} images\n"

    return summary
