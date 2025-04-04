"""
Album Management Service for the Pixels photo manager application.

This module provides higher-level functionality for managing albums and collections.
"""

import logging
from typing import Dict, List, Optional

# Import our core components
from .database import PhotoDatabase
from .thumbnail_service import ThumbnailService

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class AlbumManager:
    """Manager for album operations and functionality."""

    def __init__(self, db_path: str = None):
        """
        Initialize the album manager.
        
        Args:
            db_path: Path to the database file (optional)
        """
        self.db = PhotoDatabase(db_path)
        self.thumbnail_service = ThumbnailService(db_path)

    def create_album(self, name: str, description: str = "") -> Optional[Dict]:
        """
        Create a new album.
        
        Args:
            name: Name of the album
            description: Description of the album (optional)
            
        Returns:
            Dictionary with album information or None if creation failed
        """
        try:
            album_id = self.db.create_album(name, description)
            if album_id:
                return self.get_album(album_id)
            return None
        except Exception as e:
            logger.error(f"Error creating album: {str(e)}")
            return None

    def get_album(self, album_id: int) -> Optional[Dict]:
        """
        Get album details by ID.
        
        Args:
            album_id: ID of the album
            
        Returns:
            Dictionary with album information or None if not found
        """
        try:
            album = self.db.get_album(album_id)
            if album:
                # Add photo count
                album['photo_count'] = self._get_album_photo_count(album_id)
                return album
            return None
        except Exception as e:
            logger.error(f"Error retrieving album {album_id}: {str(e)}")
            return None

    def update_album(self, album_id: int, name: str = None, description: str = None) -> bool:
        """
        Update album properties.
        
        Args:
            album_id: ID of the album to update
            name: New album name (optional)
            description: New album description (optional)
            
        Returns:
            True if successful, False otherwise
        """
        try:
            return self.db.update_album(album_id, name, description)
        except Exception as e:
            logger.error(f"Error updating album {album_id}: {str(e)}")
            return False

    def delete_album(self, album_id: int) -> bool:
        """
        Delete an album.
        
        Args:
            album_id: ID of the album to delete
            
        Returns:
            True if successful, False otherwise
        """
        try:
            return self.db.delete_album(album_id)
        except Exception as e:
            logger.error(f"Error deleting album {album_id}: {str(e)}")
            return False

    def get_all_albums(self) -> List[Dict]:
        """
        Get all albums with basic information.
        
        Returns:
            List of album dictionaries with photo counts
        """
        try:
            albums = self.db.get_all_albums()

            # Add photo count to each album
            for album in albums:
                album['photo_count'] = self._get_album_photo_count(album['id'])

            return albums
        except Exception as e:
            logger.error(f"Error retrieving albums: {str(e)}")
            return []

    def add_photos_to_album(self, album_id: int, photo_ids: List[int]) -> int:
        """
        Add multiple photos to an album.
        
        Args:
            album_id: ID of the album
            photo_ids: List of photo IDs to add
            
        Returns:
            Number of photos successfully added
        """
        count = 0
        try:
            for photo_id in photo_ids:
                if self.db.add_photo_to_album(album_id, photo_id):
                    count += 1
            return count
        except Exception as e:
            logger.error(f"Error adding photos to album {album_id}: {str(e)}")
            return count

    def remove_photos_from_album(self, album_id: int, photo_ids: List[int]) -> int:
        """
        Remove multiple photos from an album.
        
        Args:
            album_id: ID of the album
            photo_ids: List of photo IDs to remove
            
        Returns:
            Number of photos successfully removed
        """
        count = 0
        try:
            for photo_id in photo_ids:
                if self.db.remove_photo_from_album(album_id, photo_id):
                    count += 1
            return count
        except Exception as e:
            logger.error(f"Error removing photos from album {album_id}: {str(e)}")
            return count

    def reorder_album_photos(self, album_id: int, order_map: Dict[int, int]) -> bool:
        """
        Reorder photos within an album.
        
        Args:
            album_id: ID of the album
            order_map: Dictionary mapping photo IDs to new order indices
            
        Returns:
            True if successful, False otherwise
        """
        try:
            return self.db.reorder_album_photos(album_id, order_map)
        except Exception as e:
            logger.error(f"Error reordering photos in album {album_id}: {str(e)}")
            return False

    def get_photos_in_album(self, album_id: int) -> List[Dict]:
        """
        Get all photos in an album.
        
        Args:
            album_id: ID of the album
            
        Returns:
            List of photo dictionaries, ordered by their position in the album
        """
        try:
            photos = self.db.get_photos_in_album(album_id)
            return photos
        except Exception as e:
            logger.error(f"Error retrieving photos in album {album_id}: {str(e)}")
            return []

    def get_album_photo_thumbnails(self, album_id: int, size: str = 'sm') -> Dict[int, str]:
        """
        Get thumbnails for all photos in an album.
        
        Args:
            album_id: ID of the album
            size: Size of the thumbnails (xxs, xs, sm, md, lg, xl)
            
        Returns:
            Dictionary mapping photo IDs to thumbnail paths
        """
        try:
            photos = self.db.get_photos_in_album(album_id)
            photo_ids = [photo['id'] for photo in photos]

            result = {}
            for photo_id in photo_ids:
                thumbnail_path = self.thumbnail_service.get_or_create_thumbnail(photo_id, size)
                if thumbnail_path:
                    result[photo_id] = thumbnail_path

            return result
        except Exception as e:
            logger.error(f"Error getting thumbnails for album {album_id}: {str(e)}")
            return {}

    def get_albums_containing_photo(self, photo_id: int) -> List[Dict]:
        """
        Get all albums that contain a specific photo.
        
        Args:
            photo_id: ID of the photo
            
        Returns:
            List of album dictionaries
        """
        try:
            return self.db.get_albums_for_photo(photo_id)
        except Exception as e:
            logger.error(f"Error getting albums for photo {photo_id}: {str(e)}")
            return []

    def copy_album(self, album_id: int, new_name: str = None) -> Optional[int]:
        """
        Create a copy of an album with all its photos.
        
        Args:
            album_id: ID of the source album
            new_name: Name for the new album (defaults to "Copy of [original name]")
            
        Returns:
            ID of the new album if successful, None otherwise
        """
        try:
            # Get source album
            source_album = self.db.get_album(album_id)
            if not source_album:
                return None

            # Generate new name if not provided
            if new_name is None:
                new_name = f"Copy of {source_album['name']}"

            # Create new album
            new_album_id = self.db.create_album(
                name=new_name,
                description=source_album['description']
            )

            if not new_album_id:
                return None

            # Get photos from source album
            photos = self.db.get_photos_in_album(album_id)

            # Add photos to new album, preserving order
            for photo in photos:
                self.db.add_photo_to_album(
                    new_album_id,
                    photo['id'],
                    photo['order_index']
                )

            return new_album_id

        except Exception as e:
            logger.error(f"Error copying album {album_id}: {str(e)}")
            return None

    def _get_album_photo_count(self, album_id: int) -> int:
        """Get the number of photos in an album."""
        cursor = self.db.conn.cursor()
        cursor.execute(
            'SELECT COUNT(*) FROM album_photos WHERE album_id = ?',
            (album_id,)
        )
        return cursor.fetchone()[0]
