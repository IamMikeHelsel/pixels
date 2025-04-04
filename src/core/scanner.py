"""
Scanner module for the Pixels photo manager
"""

import logging
import mimetypes
import os
from typing import Dict, List, Any

logger = logging.getLogger(__name__)


class FileSystemScanner:
    """
    Scanner for the file system to find images and directories
    """

    def __init__(self):
        """Initialize the scanner with image file extensions"""
        self.image_extensions = {
            '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.tiff', '.webp'
        }
        # Initialize mimetypes
        if not mimetypes.inited:
            mimetypes.init()

    def scan_directory(self, path: str, recursive: bool = False) -> Dict[str, Any]:
        """
        Scan a directory for images and subdirectories
        
        Args:
            path: Path to the directory
            recursive: Whether to scan subdirectories recursively
            
        Returns:
            Dictionary containing scan results
        """
        if not os.path.exists(path) or not os.path.isdir(path):
            logger.error(f"Path does not exist or is not a directory: {path}")
            return {}

        try:
            dir_path = os.path.abspath(path)
            result = {}

            for item in os.scandir(dir_path):
                if item.is_file():
                    # Check if this is an image file
                    _, ext = os.path.splitext(item.name.lower())
                    mime_type, _ = mimetypes.guess_type(item.name)
                    is_image = ext in self.image_extensions or (mime_type and mime_type.startswith('image/'))

                    if is_image:
                        if dir_path not in result:
                            result[dir_path] = []
                        result[dir_path].append(item.name)

                elif item.is_dir() and recursive:
                    sub_result = self.scan_directory(item.path, recursive)
                    result.update(sub_result)

            return result

        except Exception as e:
            logger.error(f"Error scanning directory {path}: {e}")
            return {}

    def is_supported_image(self, filename: str) -> bool:
        """
        Check if a file is a supported image by its extension
        
        Args:
            filename: Name of the file
            
        Returns:
            True if the file is a supported image, False otherwise
        """
        _, ext = os.path.splitext(filename.lower())
        mime_type, _ = mimetypes.guess_type(filename)
        return ext in self.image_extensions or (mime_type and mime_type.startswith('image/'))

    # Alias for internal method to maintain compatibility with tests
    _is_supported_image = is_supported_image

    def scan_directories(self, paths: List[str], recursive: bool = False) -> Dict[str, List[str]]:
        """
        Scan multiple directories
        
        Args:
            paths: List of paths to scan
            recursive: Whether to scan subdirectories recursively
            
        Returns:
            Dictionary mapping directory paths to lists of found files
        """
        result = {}
        for path in paths:
            dir_result = self.scan_directory(path, recursive)
            for dir_path, files in dir_result.items():
                if dir_path not in result:
                    result[dir_path] = []
                result[dir_path].extend(files)
        return result


def get_scan_summary(scan_result: Dict[str, Any]) -> str:
    """
    Generate a human-readable summary of scan results
    
    Args:
        scan_result: Result from FileSystemScanner.scan_directory
        
    Returns:
        str: Summary of scan results
    """
    total_images = 0
    folder_details = []

    for folder, files in scan_result.items():
        # Get the folder name while preserving full path in output
        folder_details.append(f"{folder}: {len(files)} images")
        total_images += len(files)

    total_folders = len(scan_result)
    summary = [f"{total_images} images in {total_folders} folders"]
    summary.extend(folder_details)

    return "\n".join(summary)
