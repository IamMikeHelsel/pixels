"""
Duplicate detection service for Pixels photo manager.

This module provides functionality to identify and manage duplicate photos.
"""

import hashlib
import logging
import os
from typing import Dict, List, Optional, Tuple, Any

# Import libraries for perceptual hashing
import imagehash
from PIL import Image, UnidentifiedImageError
from src.core.database import PhotoDatabase

logger = logging.getLogger(__name__)


class DuplicateDetectionService:
    """
    Service for detecting and managing duplicate photos.
    
    This service provides methods to scan the library for duplicate photos,
    using both exact file hash matching and perceptual hashing.
    """

    def __init__(self, db_path: Optional[str] = None):
        """
        Initialize the duplicate detection service.
        
        Args:
            db_path: Path to the database file. If None, uses the default path.
        """
        self.db = PhotoDatabase(db_path)

    def find_exact_duplicates(self) -> List[Dict[str, Any]]:
        """
        Find groups of photos with identical file hashes.
        
        Returns:
            List of dictionaries where each dictionary represents a group of duplicate photos.
            Each dictionary contains 'file_hash' and 'photos' keys.
        """
        db_results = self.db.find_duplicates()

        # Enhance results with full photo information
        duplicates = []
        for group in db_results:
            photo_ids = [int(id_str) for id_str in group["photo_ids"]]
            photos = []

            for photo_id in photo_ids:
                photo_info = self.db.get_photo(photo_id)
                if photo_info:
                    photos.append(photo_info)

            if len(photos) > 1:  # Only include groups with at least 2 photos
                duplicates.append({
                    "file_hash": group["file_hash"],
                    "photos": photos
                })

        return duplicates

    def find_duplicates_in_folder(self, folder_id: int) -> List[Dict[str, Any]]:
        """
        Find duplicate photos within a specific folder.
        
        Args:
            folder_id: ID of the folder to scan for duplicates
            
        Returns:
            List of duplicate photo groups
        """
        # Get all photos in the folder
        photos = self.db.get_photos_by_folder(folder_id)

        # Group by file hash
        hash_groups = {}
        for photo in photos:
            file_hash = photo.get("file_hash")
            if file_hash:
                if file_hash not in hash_groups:
                    hash_groups[file_hash] = []
                hash_groups[file_hash].append(photo)

        # Filter for groups with more than one photo
        duplicates = []
        for file_hash, photos in hash_groups.items():
            if len(photos) > 1:
                duplicates.append({
                    "file_hash": file_hash,
                    "photos": photos
                })

        return duplicates

    def calculate_file_hash(self, file_path: str, block_size: int = 65536) -> str:
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

    def calculate_perceptual_hash(self, file_path: str, hash_size: int = 8) -> Optional[str]:
        """
        Calculate a perceptual hash of an image file for finding visually similar images.
        
        This method uses a combination of different perceptual hashing algorithms:
        - Average hash (sensitive to colors)
        - Perceptual hash (sensitive to features)
        - Difference hash (sensitive to edges)
        - Wavelet hash (sensitive to patterns)
        
        Args:
            file_path: Path to the image file
            hash_size: Size of the hash (default: 8, producing 64-bit hashes)
            
        Returns:
            Hexadecimal string representation of the combined hash, or None if failed
        """
        try:
            with Image.open(file_path) as img:
                # Convert to RGB mode if the image has an alpha channel
                if img.mode == 'RGBA':
                    # Create a white background
                    background = Image.new('RGB', img.size, (255, 255, 255))
                    # Paste the image on the background
                    background.paste(img, mask=img.split()[3])  # 3 is the alpha channel
                    img = background
                elif img.mode != 'RGB':
                    img = img.convert('RGB')

                # Calculate different types of hashes
                avg_hash = imagehash.average_hash(img, hash_size=hash_size)
                p_hash = imagehash.phash(img, hash_size=hash_size)
                d_hash = imagehash.dhash(img, hash_size=hash_size)
                w_hash = imagehash.whash(img, hash_size=hash_size)

                # Combine the hashes (simple concatenation)
                combined = str(avg_hash) + str(p_hash) + str(d_hash) + str(w_hash)

                # Create a single hash from the combined string
                return hashlib.sha256(combined.encode()).hexdigest()
        except (UnidentifiedImageError, IOError, OSError) as e:
            logger.warning(f"Failed to calculate perceptual hash for {file_path}: {e}")
            return None

    def find_similar_images(self, threshold: float = 0.9, limit: int = 100) -> List[Dict[str, Any]]:
        """
        Find visually similar images using perceptual hashing.
        
        Args:
            threshold: Similarity threshold (0.0-1.0), higher values find only more similar images
            limit: Maximum number of photos to compare (to avoid excessive processing)
            
        Returns:
            List of similar image groups
        """
        # Get photos that have perceptual hash values
        photos = self.db.get_photos_with_perceptual_hash(limit=limit)

        # Group similar photos
        similarity_groups = []
        processed_ids = set()

        for i, photo1 in enumerate(photos):
            if photo1['id'] in processed_ids:
                continue

            similar_photos = [photo1]
            processed_ids.add(photo1['id'])

            p_hash1 = photo1.get('perceptual_hash')
            if not p_hash1:
                continue

            # Compare with all other unprocessed photos
            for j in range(i + 1, len(photos)):
                photo2 = photos[j]
                if photo2['id'] in processed_ids:
                    continue

                p_hash2 = photo2.get('perceptual_hash')
                if not p_hash2:
                    continue

                # Calculate similarity based on perceptual hash difference
                similarity = self.calculate_hash_similarity(p_hash1, p_hash2)

                if similarity >= threshold:
                    similar_photos.append(photo2)
                    processed_ids.add(photo2['id'])

            # Only add groups with more than one photo
            if len(similar_photos) > 1:
                similarity_groups.append({
                    'similarity': threshold,
                    'photos': similar_photos
                })

        return similarity_groups

    def calculate_hash_similarity(self, hash1: str, hash2: str) -> float:
        """
        Calculate the similarity between two perceptual hashes.
        
        Args:
            hash1: First hash string
            hash2: Second hash string
            
        Returns:
            Similarity score between 0.0 (completely different) and 1.0 (identical)
        """
        # For SHA-256 hashes, we need to compare bit by bit
        # Convert hashes to binary representation
        try:
            h1_int = int(hash1, 16)
            h2_int = int(hash2, 16)

            # Calculate Hamming distance (number of different bits)
            xor_result = h1_int ^ h2_int
            hamming_distance = bin(xor_result).count('1')

            # Calculate similarity (1.0 means identical)
            # SHA-256 produces 256-bit hashes
            return 1.0 - (hamming_distance / 256)
        except (ValueError, TypeError):
            return 0.0

    def scan_and_index_folder(self, folder_path: str) -> Tuple[int, int]:
        """
        Scan a folder for images, calculate their hashes, and add to the database.
        
        Args:
            folder_path: Path to the folder to scan
            
        Returns:
            Tuple of (number of images processed, number of duplicates found)
        """
        from src.core.library_indexer import LibraryIndexer
        from src.core.thumbnail_service import ThumbnailService

        # Initialize required services
        thumbnail_service = ThumbnailService()
        indexer = LibraryIndexer(db_path=self.db.db_path, thumbnail_service=thumbnail_service)

        # Index the folder
        folders_added, photos_added, _ = indexer.index_folder(folder_path, recursive=True)

        # Find duplicates after indexing
        duplicates = self.find_exact_duplicates()
        duplicate_count = sum(len(group["photos"]) - 1 for group in duplicates)

        return photos_added, duplicate_count

    def delete_duplicate(self, photo_id: int, permanent: bool = False) -> bool:
        """
        Delete a duplicate photo.
        
        Args:
            photo_id: ID of the photo to delete
            permanent: If True, permanently delete the file; if False, move to trash
            
        Returns:
            True if successful, False otherwise
        """
        if permanent:
            return self.db.permanently_delete_photo(photo_id)
        else:
            return self.db.move_to_trash(photo_id)

    def suggest_duplicates_to_keep(self, duplicate_group: Dict[str, Any]) -> List[int]:
        """
        Suggest which photos to keep from a group of duplicates based on quality metrics.
        
        This method applies various heuristics to rank duplicates by quality:
        - Higher resolution is better
        - Original file is preferred over edited versions
        - Files with more complete metadata are preferred
        - Older files may be preferred (original source)
        
        Args:
            duplicate_group: A group of duplicate photos
            
        Returns:
            List of photo IDs ordered by suggested priority to keep
        """
        photos = duplicate_group["photos"]

        # Create a list of (photo, score) tuples
        scored_photos = []

        for photo in photos:
            score = 0

            # Higher resolution gets more points
            width = photo.get("width", 0) or 0
            height = photo.get("height", 0) or 0
            score += width * height

            # More complete metadata is better
            if photo.get("date_taken"):
                score += 10
            if photo.get("camera_make") and photo.get("camera_model"):
                score += 5
            if photo.get("iso") or photo.get("aperture") or photo.get("exposure_time"):
                score += 5

            # Rating and favorites get bonus points
            score += (photo.get("rating", 0) or 0) * 20
            if photo.get("is_favorite"):
                score += 50

            scored_photos.append((photo, score))

        # Sort photos by score (descending)
        scored_photos.sort(key=lambda x: x[1], reverse=True)

        # Return the sorted photo IDs
        return [photo["id"] for photo, _ in scored_photos]

    def get_duplicate_statistics(self) -> Dict[str, Any]:
        """
        Get statistics about duplicates in the library.
        
        Returns:
            Dictionary with statistics about duplicates
        """
        duplicate_groups = self.find_exact_duplicates()

        total_duplicates = 0
        duplicate_file_sizes = 0
        largest_group_size = 0

        for group in duplicate_groups:
            group_size = len(group["photos"])
            # Count all but one photo in each group as duplicates
            total_duplicates += group_size - 1

            # Count potentially wasted storage space
            for photo in group["photos"][1:]:  # Skip the first one
                if photo.get("file_size"):
                    duplicate_file_sizes += photo["file_size"]

            # Track the largest duplicate group
            largest_group_size = max(largest_group_size, group_size)

        return {
            "total_groups": len(duplicate_groups),
            "total_duplicates": total_duplicates,
            "wasted_space_bytes": duplicate_file_sizes,
            "wasted_space_mb": duplicate_file_sizes / (1024 * 1024),
            "largest_group_size": largest_group_size
        }

    def update_perceptual_hashes(self, limit: int = 100) -> int:
        """
        Update perceptual hashes for photos that don't have them yet.
        
        Args:
            limit: Maximum number of photos to process in one call
            
        Returns:
            Number of photos updated
        """
        # Get photos without perceptual hashes
        photos = self.db.get_photos_without_perceptual_hash(limit=limit)

        updates = 0
        for photo in photos:
            file_path = photo.get('file_path')
            if file_path and os.path.exists(file_path):
                perceptual_hash = self.calculate_perceptual_hash(file_path)
                if perceptual_hash:
                    success = self.db.update_photo_perceptual_hash(photo['id'], perceptual_hash)
                    if success:
                        updates += 1

        return updates
