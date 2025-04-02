"""
Scanner module for the Pixels photo manager
"""

import os
from datetime import datetime
import mimetypes
import logging
from typing import Dict, List, Any, Optional

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
            Dict with keys 'directories' and 'files', containing lists of found items
        """
        if not os.path.exists(path):
            logger.error(f"Path does not exist: {path}")
            return {'directories': [], 'files': []}
        
        if not os.path.isdir(path):
            logger.error(f"Path is not a directory: {path}")
            return {'directories': [], 'files': []}
        
        result = {
            'directories': [],
            'files': []
        }
        
        try:
            for item in os.scandir(path):
                if item.is_dir():
                    dir_info = {
                        'name': item.name,
                        'path': item.path,
                        'timestamp': datetime.fromtimestamp(item.stat().st_mtime).isoformat()
                    }
                    result['directories'].append(dir_info)
                    
                    # Recursively scan subdirectories if requested
                    if recursive:
                        sub_result = self.scan_directory(item.path, recursive)
                        result['directories'].extend(sub_result['directories'])
                        result['files'].extend(sub_result['files'])
                elif item.is_file():
                    # Check if this is an image file
                    _, ext = os.path.splitext(item.name.lower())
                    mime_type, _ = mimetypes.guess_type(item.name)
                    is_image = ext in self.image_extensions or (mime_type and mime_type.startswith('image/'))
                    
                    file_info = {
                        'name': item.name,
                        'path': item.path,
                        'size': item.stat().st_size,
                        'extension': ext,
                        'timestamp': datetime.fromtimestamp(item.stat().st_mtime).isoformat(),
                        'is_image': is_image
                    }
                    result['files'].append(file_info)
        except Exception as e:
            logger.error(f"Error scanning directory {path}: {e}")
        
        return result
        
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
        
    def scan_directories(self, paths: List[str], recursive: bool = False) -> Dict[str, Any]:
        """
        Scan multiple directories
        
        Args:
            paths: List of paths to scan
            recursive: Whether to scan subdirectories recursively
            
        Returns:
            Combined scan results dictionary
        """
        combined_result = {
            'directories': [],
            'files': []
        }
        
        for path in paths:
            result = self.scan_directory(path, recursive)
            combined_result['directories'].extend(result['directories'])
            combined_result['files'].extend(result['files'])
            
        return combined_result


def get_scan_summary(scan_result: Dict[str, Any]) -> str:
    """
    Generate a human-readable summary of scan results
    
    Args:
        scan_result: Result from FileSystemScanner.scan_directory
        
    Returns:
        str: Summary of scan results
    """
    directories = scan_result.get('directories', [])
    files = scan_result.get('files', [])
    images = [f for f in files if f.get('is_image', False)]
    
    total_size = sum(f.get('size', 0) for f in files)
    
    summary = [
        f"Found {len(directories)} directories",
        f"Found {len(files)} files, including {len(images)} image files",
        f"Total file size: {format_size(total_size)}",
    ]
    
    # Add file extension breakdown
    if files:
        ext_count = {}
        for file in files:
            ext = file.get('extension', '').lower()
            ext_count[ext] = ext_count.get(ext, 0) + 1
        
        summary.append("\nFile types:")
        for ext, count in sorted(ext_count.items(), key=lambda x: x[1], reverse=True):
            if ext:
                summary.append(f"  {ext}: {count} files")
    
    return "\n".join(summary)


def format_size(size_bytes: int) -> str:
    """
    Format size in bytes to human-readable string
    
    Args:
        size_bytes: Size in bytes
        
    Returns:
        str: Formatted size string (e.g., '1.23 MB')
    """
    if size_bytes < 1024:
        return f"{size_bytes} bytes"
    elif size_bytes < 1024 * 1024:
        return f"{size_bytes / 1024:.2f} KB"
    elif size_bytes < 1024 * 1024 * 1024:
        return f"{size_bytes / (1024 * 1024):.2f} MB"
    else:
        return f"{size_bytes / (1024 * 1024 * 1024):.2f} GB"
