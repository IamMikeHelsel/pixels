"""
Thumbnail generation service for Pixels photo manager
"""

import os
import logging
from typing import Optional
import hashlib
import errno
from PIL import Image, UnidentifiedImageError
from src.core.feature_flags import get_feature_flags

logger = logging.getLogger(__name__)

class ThumbnailService:
    """
    Service for generating and managing thumbnails
    """
    
    def __init__(self, thumbnail_dir: Optional[str] = None, test_mode: bool = False):
        """
        Initialize the thumbnail service
        
        Args:
            thumbnail_dir: Directory to store thumbnails (default: ./thumbnails)
            test_mode: If True, don't require files to exist (for testing)
        """
        # Handle in-memory database case
        if thumbnail_dir == ':memory:':
            thumbnail_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "thumbnails")
        
        self.thumbnail_dir = thumbnail_dir or os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "thumbnails")
        self.test_mode = test_mode
        self.thumbnail_sizes = {
            "sm": (128, 128),
            "md": (256, 256),
            "lg": (512, 512)
        }
        self.thumbnail_size = self.thumbnail_sizes["md"]  # Default size
        
        # Create thumbnail directory if it doesn't exist
        try:
            os.makedirs(self.thumbnail_dir, exist_ok=True)
        except OSError as e:
            # Handle rare race condition or permission issues
            if e.errno != errno.EEXIST:
                logger.error(f"Failed to create thumbnail directory: {e}")
                # Fall back to a temp directory if possible
                import tempfile
                self.thumbnail_dir = tempfile.gettempdir()
                logger.info(f"Using temporary directory for thumbnails: {self.thumbnail_dir}")
        
        # Get feature flags
        self.feature_flags = get_feature_flags()
    
    def generate_thumbnail(self, image_path: str, size: str = None) -> Optional[str]:
        """
        Generate a thumbnail for an image
        
        Args:
            image_path: Path to the image
            size: Size of the thumbnail ("sm", "md", "lg")
            
        Returns:
            str: Path to the generated thumbnail, or None if generation failed
        """
        if not self.test_mode and not os.path.exists(image_path):
            logger.error(f"Image does not exist: {image_path}")
            return None
        
        try:
            # Set thumbnail size based on the size parameter
            thumbnail_size = self.thumbnail_sizes.get(size, self.thumbnail_size)
            
            # Generate a unique filename based on the image path and size
            image_hash = hashlib.md5(image_path.encode()).hexdigest()
            size_suffix = f"_{size}" if size else ""
            thumbnail_filename = f"{image_hash}{size_suffix}.jpg"
            thumbnail_path = os.path.join(self.thumbnail_dir, thumbnail_filename)
            
            # For test mode, just return the path without generating
            if self.test_mode:
                # Create an empty file to simulate thumbnail creation
                try:
                    open(thumbnail_path, 'a').close()
                except OSError as e:
                    if e.errno == errno.EEXIST:
                        # File already exists, that's fine
                        pass
                    else:
                        # Re-raise other errors
                        raise
                return thumbnail_path
            
            # Check if thumbnail already exists
            if os.path.exists(thumbnail_path):
                logger.debug(f"Thumbnail already exists: {thumbnail_path}")
                return thumbnail_path
            
            # Open the image
            with Image.open(image_path) as img:
                # Use optimized thumbnail generation if enabled
                if self.feature_flags.is_enabled("optimized_thumbnail_generation"):
                    # This uses PIL's thumbnail method which preserves aspect ratio
                    img.thumbnail(thumbnail_size)
                    thumbnail = img
                else:
                    # Simple resize
                    thumbnail = img.resize(thumbnail_size)
                
                # Save the thumbnail - make sure parent directory exists
                try:
                    # Save the thumbnail
                    thumbnail.save(thumbnail_path, "JPEG", quality=85, optimize=True)
                except OSError as e:
                    if e.errno == errno.EEXIST:
                        logger.debug(f"Thumbnail was created by another process: {thumbnail_path}")
                        return thumbnail_path
                    else:
                        # Re-raise other errors
                        raise
            
            logger.debug(f"Generated thumbnail: {thumbnail_path}")
            return thumbnail_path
            
        except UnidentifiedImageError:
            logger.error(f"Cannot identify image file: {image_path}")
            return None
        except Exception as e:
            logger.error(f"Error generating thumbnail for {image_path}: {e}")
            return None
    
    def get_cached_thumbnail(self, image_path: str, size: str = None) -> Optional[str]:
        """
        Get the path to a cached thumbnail if it exists
        
        Args:
            image_path: Path to the original image
            size: Size of the thumbnail ("sm", "md", "lg")
            
        Returns:
            str: Path to the cached thumbnail or None if it doesn't exist
        """
        image_hash = hashlib.md5(image_path.encode()).hexdigest()
        size_suffix = f"_{size}" if size else ""
        thumbnail_filename = f"{image_hash}{size_suffix}.jpg"
        thumbnail_path = os.path.join(self.thumbnail_dir, thumbnail_filename)
        
        if os.path.exists(thumbnail_path):
            return thumbnail_path
        
        return None
    
    def get_thumbnail_path(self, image_path: str) -> str:
        """
        Get the path where a thumbnail would be stored, without generating it
        
        Args:
            image_path: Path to the image
            
        Returns:
            str: Path where the thumbnail would be stored
        """
        image_hash = hashlib.md5(image_path.encode()).hexdigest()
        thumbnail_filename = f"{image_hash}.jpg"
        return os.path.join(self.thumbnail_dir, thumbnail_filename)
    
    def clear_thumbnails(self) -> int:
        """
        Clear all generated thumbnails
        
        Returns:
            int: Number of files removed
        """
        count = 0
        for filename in os.listdir(self.thumbnail_dir):
            file_path = os.path.join(self.thumbnail_dir, filename)
            if os.path.isfile(file_path):
                os.remove(file_path)
                count += 1
        logger.info(f"Cleared {count} thumbnails")
        return count
