"""
Tag & Rating Management Service for the Pixels photo manager application.

This module provides higher-level functionality for managing tags and ratings.
"""

import os
import logging
from typing import Dict, List, Optional, Union, Set
from datetime import datetime

# Import our core components
from .database import PhotoDatabase

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class TagManager:
    """Manager for tag and rating operations and functionality."""
    
    def __init__(self, db_path: str = None):
        """
        Initialize the tag manager.
        
        Args:
            db_path: Path to the database file (optional)
        """
        self.db = PhotoDatabase(db_path)
    
    # Tag management operations
    def create_tag(self, name: str, parent_id: int = None) -> Optional[Dict]:
        """
        Create a new tag.
        
        Args:
            name: Tag name
            parent_id: ID of parent tag (for hierarchical tags)
            
        Returns:
            Dictionary with tag information or None if creation failed
        """
        try:
            # Normalize tag name (trim whitespace, convert to lowercase)
            name = name.strip().lower()
            if not name:
                return None
            
            # Check if tag already exists
            existing_tag = self.db.get_tag_by_name(name)
            if existing_tag:
                return existing_tag
            
            # Create new tag
            tag_id = self.db.add_tag(name, parent_id)
            if tag_id:
                return self.db.get_tag(tag_id)
            return None
        except Exception as e:
            logger.error(f"Error creating tag: {str(e)}")
            return None
    
    def update_tag(self, tag_id: int, name: str = None, parent_id: int = None) -> bool:
        """
        Update tag properties.
        
        Args:
            tag_id: ID of the tag
            name: New tag name (optional)
            parent_id: New parent tag ID (optional)
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Normalize tag name if provided
            if name is not None:
                name = name.strip().lower()
                if not name:
                    return False
            
            return self.db.update_tag(tag_id, name, parent_id)
        except Exception as e:
            logger.error(f"Error updating tag {tag_id}: {str(e)}")
            return False
    
    def delete_tag(self, tag_id: int) -> bool:
        """
        Delete a tag.
        
        Args:
            tag_id: ID of the tag
            
        Returns:
            True if successful, False otherwise
        """
        try:
            return self.db.delete_tag(tag_id)
        except Exception as e:
            logger.error(f"Error deleting tag {tag_id}: {str(e)}")
            return False
    
    def get_tag_hierarchy(self) -> List[Dict]:
        """
        Get the tag hierarchy as a nested structure.
        
        Returns:
            List of dictionaries with tag information and children
        """
        try:
            return self.db.get_tag_hierarchy()
        except Exception as e:
            logger.error(f"Error retrieving tag hierarchy: {str(e)}")
            return []
    
    def get_all_tags(self, include_count: bool = False) -> List[Dict]:
        """
        Get all tags.
        
        Args:
            include_count: Whether to include photo counts for each tag
            
        Returns:
            List of tag dictionaries
        """
        try:
            tags = self.db.get_all_tags()
            
            if include_count:
                for tag in tags:
                    tag['photo_count'] = self._get_tag_photo_count(tag['id'])
                    
            return tags
        except Exception as e:
            logger.error(f"Error retrieving tags: {str(e)}")
            return []
    
    # Photo tagging operations
    def add_tag_to_photo(self, photo_id: int, tag_id: int) -> bool:
        """
        Add a tag to a photo.
        
        Args:
            photo_id: ID of the photo
            tag_id: ID of the tag
            
        Returns:
            True if successful, False otherwise
        """
        try:
            return self.db.add_tag_to_photo(photo_id, tag_id)
        except Exception as e:
            logger.error(f"Error adding tag {tag_id} to photo {photo_id}: {str(e)}")
            return False
    
    def add_tag_to_photos(self, photo_ids: List[int], tag_id: int) -> int:
        """
        Add a tag to multiple photos.
        
        Args:
            photo_ids: List of photo IDs
            tag_id: ID of the tag
            
        Returns:
            Number of photos successfully tagged
        """
        count = 0
        try:
            for photo_id in photo_ids:
                if self.db.add_tag_to_photo(photo_id, tag_id):
                    count += 1
            return count
        except Exception as e:
            logger.error(f"Error adding tag {tag_id} to multiple photos: {str(e)}")
            return count
    
    def add_tags_to_photo(self, photo_id: int, tag_ids: List[int]) -> int:
        """
        Add multiple tags to a photo.
        
        Args:
            photo_id: ID of the photo
            tag_ids: List of tag IDs
            
        Returns:
            Number of tags successfully added
        """
        count = 0
        try:
            for tag_id in tag_ids:
                if self.db.add_tag_to_photo(photo_id, tag_id):
                    count += 1
            return count
        except Exception as e:
            logger.error(f"Error adding multiple tags to photo {photo_id}: {str(e)}")
            return count
    
    def add_tag_by_name_to_photo(self, photo_id: int, tag_name: str) -> bool:
        """
        Add a tag to a photo by tag name, creating the tag if it doesn't exist.
        
        Args:
            photo_id: ID of the photo
            tag_name: Name of the tag
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Normalize tag name
            tag_name = tag_name.strip().lower()
            if not tag_name:
                return False
            
            # Get or create tag
            tag = self.db.get_tag_by_name(tag_name)
            if not tag:
                tag_id = self.db.add_tag(tag_name)
            else:
                tag_id = tag['id']
            
            if not tag_id:
                return False
                
            return self.db.add_tag_to_photo(photo_id, tag_id)
        except Exception as e:
            logger.error(f"Error adding tag '{tag_name}' to photo {photo_id}: {str(e)}")
            return False
    
    def remove_tag_from_photo(self, photo_id: int, tag_id: int) -> bool:
        """
        Remove a tag from a photo.
        
        Args:
            photo_id: ID of the photo
            tag_id: ID of the tag
            
        Returns:
            True if successful, False otherwise
        """
        try:
            return self.db.remove_tag_from_photo(photo_id, tag_id)
        except Exception as e:
            logger.error(f"Error removing tag {tag_id} from photo {photo_id}: {str(e)}")
            return False
    
    def remove_tag_from_photos(self, photo_ids: List[int], tag_id: int) -> int:
        """
        Remove a tag from multiple photos.
        
        Args:
            photo_ids: List of photo IDs
            tag_id: ID of the tag
            
        Returns:
            Number of photos successfully untagged
        """
        count = 0
        try:
            for photo_id in photo_ids:
                if self.db.remove_tag_from_photo(photo_id, tag_id):
                    count += 1
            return count
        except Exception as e:
            logger.error(f"Error removing tag {tag_id} from multiple photos: {str(e)}")
            return count
    
    def get_photos_by_tag(self, tag_id: int, limit: int = 100, offset: int = 0) -> List[Dict]:
        """
        Get photos with a specific tag.
        
        Args:
            tag_id: ID of the tag
            limit: Maximum number of results
            offset: Offset for pagination
            
        Returns:
            List of photo dictionaries
        """
        try:
            return self.db.get_photos_by_tag(tag_id, limit, offset)
        except Exception as e:
            logger.error(f"Error getting photos with tag {tag_id}: {str(e)}")
            return []
    
    def get_tags_for_photo(self, photo_id: int) -> List[Dict]:
        """
        Get all tags for a photo.
        
        Args:
            photo_id: ID of the photo
            
        Returns:
            List of tag dictionaries
        """
        try:
            return self.db.get_tags_for_photo(photo_id)
        except Exception as e:
            logger.error(f"Error getting tags for photo {photo_id}: {str(e)}")
            return []
    
    def find_tag_suggestions(self, partial_name: str, limit: int = 10) -> List[Dict]:
        """
        Find tag suggestions based on partial tag name.
        
        Args:
            partial_name: Partial tag name to match
            limit: Maximum number of suggestions
            
        Returns:
            List of tag dictionaries matching the partial name
        """
        try:
            # Normalize input
            partial_name = partial_name.strip().lower()
            if not partial_name:
                return []
            
            cursor = self.db.conn.cursor()
            cursor.execute(
                'SELECT * FROM tags WHERE name LIKE ? ORDER BY name LIMIT ?',
                (f'%{partial_name}%', limit)
            )
            return [dict(row) for row in cursor.fetchall()]
        except Exception as e:
            logger.error(f"Error finding tag suggestions: {str(e)}")
            return []
    
    def _get_tag_photo_count(self, tag_id: int) -> int:
        """Get the number of photos with a specific tag."""
        cursor = self.db.conn.cursor()
        cursor.execute(
            'SELECT COUNT(*) FROM photo_tags WHERE tag_id = ?', 
            (tag_id,)
        )
        return cursor.fetchone()[0]
    
    # Rating and favorite operations
    def set_photo_rating(self, photo_id: int, rating: int) -> bool:
        """
        Set the rating for a photo.
        
        Args:
            photo_id: ID of the photo
            rating: Rating value (0-5)
            
        Returns:
            True if successful, False otherwise
        """
        try:
            # Validate rating
            rating = max(0, min(5, rating))  # Clamp to 0-5 range
            
            return self.db.update_photo(photo_id, rating=rating)
        except Exception as e:
            logger.error(f"Error setting rating for photo {photo_id}: {str(e)}")
            return False
    
    def set_photos_rating(self, photo_ids: List[int], rating: int) -> int:
        """
        Set the rating for multiple photos.
        
        Args:
            photo_ids: List of photo IDs
            rating: Rating value (0-5)
            
        Returns:
            Number of photos successfully updated
        """
        count = 0
        try:
            # Validate rating
            rating = max(0, min(5, rating))  # Clamp to 0-5 range
            
            for photo_id in photo_ids:
                if self.db.update_photo(photo_id, rating=rating):
                    count += 1
            return count
        except Exception as e:
            logger.error(f"Error setting rating for multiple photos: {str(e)}")
            return count
    
    def toggle_photo_favorite(self, photo_id: int) -> Optional[bool]:
        """
        Toggle the favorite status of a photo.
        
        Args:
            photo_id: ID of the photo
            
        Returns:
            New favorite status if successful, None if failed
        """
        try:
            # Get current status
            photo = self.db.get_photo(photo_id)
            if not photo:
                return None
                
            # Toggle status
            new_status = not photo.get('is_favorite', False)
            
            if self.db.update_photo(photo_id, is_favorite=1 if new_status else 0):
                return new_status
            return None
        except Exception as e:
            logger.error(f"Error toggling favorite status for photo {photo_id}: {str(e)}")
            return None
    
    def set_photo_favorite(self, photo_id: int, favorite: bool) -> bool:
        """
        Set the favorite status of a photo.
        
        Args:
            photo_id: ID of the photo
            favorite: Whether the photo should be marked as favorite
            
        Returns:
            True if successful, False otherwise
        """
        try:
            return self.db.update_photo(photo_id, is_favorite=1 if favorite else 0)
        except Exception as e:
            logger.error(f"Error setting favorite status for photo {photo_id}: {str(e)}")
            return False
    
    def set_photos_favorite(self, photo_ids: List[int], favorite: bool) -> int:
        """
        Set the favorite status for multiple photos.
        
        Args:
            photo_ids: List of photo IDs
            favorite: Whether the photos should be marked as favorite
            
        Returns:
            Number of photos successfully updated
        """
        count = 0
        try:
            for photo_id in photo_ids:
                if self.db.update_photo(photo_id, is_favorite=1 if favorite else 0):
                    count += 1
            return count
        except Exception as e:
            logger.error(f"Error setting favorite status for multiple photos: {str(e)}")
            return count
    
    def get_photos_by_rating(self, min_rating: int, limit: int = 100, offset: int = 0) -> List[Dict]:
        """
        Get photos with a minimum rating.
        
        Args:
            min_rating: Minimum rating (1-5)
            limit: Maximum number of results
            offset: Offset for pagination
            
        Returns:
            List of photo dictionaries
        """
        try:
            return self.db.get_photos_by_rating(min_rating, limit, offset)
        except Exception as e:
            logger.error(f"Error getting photos with minimum rating {min_rating}: {str(e)}")
            return []
    
    def get_favorite_photos(self, limit: int = 100, offset: int = 0) -> List[Dict]:
        """
        Get photos marked as favorites.
        
        Args:
            limit: Maximum number of results
            offset: Offset for pagination
            
        Returns:
            List of photo dictionaries
        """
        try:
            return self.db.get_favorite_photos(limit, offset)
        except Exception as e:
            logger.error(f"Error getting favorite photos: {str(e)}")
            return []
