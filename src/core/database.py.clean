# -*- coding: utf-8 -*-
"""
Database module for the Pixels photo manager application.

This module defines the SQLite schema and provides a Data Access Layer (DAL)
for performing CRUD operations on the photo library database.
"""

import os
import sqlite3
import threading
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Union, Any

class PhotoDatabase:
    """Main database class for the Pixels application."""
    
    _instance = None
    _lock = threading.Lock()
    
    # Singleton pattern to ensure only one database connection
    def __new__(cls, db_path: str = None):
        with cls._lock:
            if cls._instance is None:
                cls._instance = super(PhotoDatabase, cls).__new__(cls)
                cls._instance._initialized = False
            return cls._instance
    
    def __init__(self, db_path: str = None):
        """Initialize the database with the given path or default location."""
        if self._initialized:
            return
            
        # Use provided path or default to user's home directory
        if db_path is None:
            home_dir = os.path.expanduser("~")
            pixels_dir = os.path.join(home_dir, ".pixels")
            os.makedirs(pixels_dir, exist_ok=True)
            self.db_path = os.path.join(pixels_dir, "pixels.db")
        else:
            self.db_path = db_path
            
        # Create database directory if it doesn't exist
        db_dir = os.path.dirname(self.db_path)
        if not os.path.exists(db_dir):
            os.makedirs(db_dir)
            
        # Initialize connection and create tables if they don't exist
        self.conn = sqlite3.connect(self.db_path, check_same_thread=False)
        self.conn.row_factory = sqlite3.Row
        self._create_tables()
        self._initialized = True
        
    def _create_tables(self):
        """Create database tables if they don't exist."""
        cursor = self.conn.cursor()
        
        # Photos table - stores information about each photo
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS photos (
                id INTEGER PRIMARY KEY,
                file_path TEXT NOT NULL UNIQUE,
                file_name TEXT NOT NULL,
                folder_id INTEGER,
                file_size INTEGER,
                file_hash TEXT,
                width INTEGER,
                height INTEGER,
                date_taken TEXT,
                camera_make TEXT,
                camera_model TEXT,
                iso INTEGER,
                aperture REAL,
                exposure_time REAL,
                focal_length REAL,
                date_added TEXT,
                date_modified TEXT,
                rating INTEGER DEFAULT 0,
                is_favorite INTEGER DEFAULT 0,
                FOREIGN KEY (folder_id) REFERENCES folders(id)
            )
        ''')
        
        # Folders table - stores information about folders containing photos
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS folders (
                id INTEGER PRIMARY KEY,
                path TEXT NOT NULL UNIQUE,
                name TEXT NOT NULL,
                parent_id INTEGER,
                date_added TEXT,
                date_scanned TEXT,
                is_monitored INTEGER DEFAULT 0,
                FOREIGN KEY (parent_id) REFERENCES folders(id)
            )
        ''')
        
        # Tags table - stores available tags for photos
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS tags (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL UNIQUE,
                parent_id INTEGER,
                FOREIGN KEY (parent_id) REFERENCES tags(id)
            )
        ''')
        
        # Photo_tags table - many-to-many relationship between photos and tags
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS photo_tags (
                photo_id INTEGER,
                tag_id INTEGER,
                PRIMARY KEY (photo_id, tag_id),
                FOREIGN KEY (photo_id) REFERENCES photos(id),
                FOREIGN KEY (tag_id) REFERENCES tags(id)
            )
        ''')
        
        # Albums table - virtual collections of photos
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS albums (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL,
                description TEXT,
                date_created TEXT,
                date_modified TEXT
            )
        ''')
        
        # Album_photos table - many-to-many relationship between albums and photos
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS album_photos (
                album_id INTEGER,
                photo_id INTEGER,
                order_index INTEGER,
                PRIMARY KEY (album_id, photo_id),
                FOREIGN KEY (album_id) REFERENCES albums(id),
                FOREIGN KEY (photo_id) REFERENCES photos(id)
            )
        ''')
        
        # People table - stores people identified in photos
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS people (
                id INTEGER PRIMARY KEY,
                name TEXT NOT NULL UNIQUE
            )
        ''')
        
        # Face_regions table - stores face regions detected in photos
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS face_regions (
                id INTEGER PRIMARY KEY,
                photo_id INTEGER,
                person_id INTEGER,
                x INTEGER,
                y INTEGER,
                width INTEGER,
                height INTEGER,
                confidence REAL,
                FOREIGN KEY (photo_id) REFERENCES photos(id),
                FOREIGN KEY (person_id) REFERENCES people(id)
            )
        ''')
        
        # Edit_history table - stores non-destructive edits applied to photos
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS edit_history (
                id INTEGER PRIMARY KEY,
                photo_id INTEGER,
                edit_type TEXT,
                parameters TEXT,
                date_created TEXT,
                order_index INTEGER,
                FOREIGN KEY (photo_id) REFERENCES photos(id)
            )
        ''')
        
        # Thumbnails table - stores thumbnail cache information
        cursor.execute('''
            CREATE TABLE IF NOT EXISTS thumbnails (
                id INTEGER PRIMARY KEY,
                photo_id INTEGER,
                size TEXT,
                path TEXT,
                date_created TEXT,
                FOREIGN KEY (photo_id) REFERENCES photos(id)
            )
        ''')
        
        # Create indexes for performance
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_photos_folder_id ON photos(folder_id)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_photos_date_taken ON photos(date_taken)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_photos_rating ON photos(rating)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_photos_favorite ON photos(is_favorite)')
        cursor.execute('CREATE INDEX IF NOT EXISTS idx_photos_file_hash ON photos(file_hash)')
        
        self.conn.commit()
    
    def close(self):
        """Close the database connection."""
        if hasattr(self, 'conn') and self.conn:
            self.conn.close()
    
    # CRUD operations for folders
    def add_folder(self, path: str, name: str = None, parent_id: int = None, is_monitored: bool = False) -> int:
        """Add a new folder to the database."""
        if name is None:
            name = os.path.basename(path)
            
        cursor = self.conn.cursor()
        cursor.execute(
            '''
            INSERT OR IGNORE INTO folders (path, name, parent_id, date_added, date_scanned, is_monitored)
            VALUES (?, ?, ?, datetime('now'), datetime('now'), ?)
            ''',
            (path, name, parent_id, 1 if is_monitored else 0)
        )
        self.conn.commit()
        
        # Get the ID of the inserted folder
        cursor.execute('SELECT id FROM folders WHERE path = ?', (path,))
        result = cursor.fetchone()
        return result[0] if result else None
    
    def get_folder(self, folder_id: int) -> Dict:
        """Get folder details by ID."""
        cursor = self.conn.cursor()
        cursor.execute('SELECT * FROM folders WHERE id = ?', (folder_id,))
        result = cursor.fetchone()
        return dict(result) if result else None
    
    def get_folder_by_path(self, path: str) -> Dict:
        """Get folder details by path."""
        cursor = self.conn.cursor()
        cursor.execute('SELECT * FROM folders WHERE path = ?', (path,))
        result = cursor.fetchone()
        return dict(result) if result else None
    
    def update_folder(self, folder_id: int, **kwargs) -> bool:
        """Update folder properties."""
        if not kwargs:
            return False
            
        set_clauses = []
        params = []
        
        for key, value in kwargs.items():
            set_clauses.append(f"{key} = ?")
            params.append(value)
        
        params.append(folder_id)
        
        cursor = self.conn.cursor()
        cursor.execute(
            f"UPDATE folders SET {', '.join(set_clauses)} WHERE id = ?",
            params
        )
        self.conn.commit()
        return cursor.rowcount > 0
    
    def delete_folder(self, folder_id: int) -> bool:
        """Delete a folder from the database."""
        cursor = self.conn.cursor()
        cursor.execute('DELETE FROM folders WHERE id = ?', (folder_id,))
        self.conn.commit()
        return cursor.rowcount > 0
    
    def get_all_folders(self) -> List[Dict]:
        """Get all folders."""
        cursor = self.conn.cursor()
        cursor.execute('SELECT * FROM folders')
        return [dict(row) for row in cursor.fetchall()]
    
    def get_child_folders(self, parent_id: int = None) -> List[Dict]:
        """
        Get child folders for a specific parent folder.
        
        Args:
            parent_id: ID of the parent folder, or None for root folders
        
        Returns:
            List of folder dictionaries
        """
        cursor = self.conn.cursor()
        
        if parent_id is None:
            cursor.execute('SELECT * FROM folders WHERE parent_id IS NULL')
        else:
            cursor.execute('SELECT * FROM folders WHERE parent_id = ?', (parent_id,))
            
        return [dict(row) for row in cursor.fetchall()]
    
    def get_folder_hierarchy(self) -> List[Dict]:
        """
        Get the entire folder hierarchy as a nested structure.
        
        Returns:
            List of dictionaries where each dictionary represents a folder
            and contains a 'children' key with its subfolders
        """
        # First get all folders
        all_folders = {folder['id']: dict(folder) for folder in self.get_all_folders()}
        
        # Add children list to each folder
        for folder_id in all_folders:
            all_folders[folder_id]['children'] = []
        
        # Build the hierarchy
        root_folders = []
        
        for folder_id, folder in all_folders.items():
            parent_id = folder.get('parent_id')
            if parent_id is None:
                root_folders.append(folder)
            elif parent_id in all_folders:
                all_folders[parent_id]['children'].append(folder)
        
        return root_folders
    
    # CRUD operations for photos
    def add_photo(self, file_path: str, folder_id: int, **kwargs) -> int:
        """Add a new photo to the database."""
        file_name = os.path.basename(file_path)
        
        cursor = self.conn.cursor()
        
        # Build the query dynamically based on provided fields
        fields = ['file_path', 'file_name', 'folder_id', 'date_added']
        values = [file_path, file_name, folder_id, 'datetime("now")']
        
        for key, value in kwargs.items():
            fields.append(key)
            values.append(value)
        
        placeholders = ', '.join(['?'] * len(values))
        field_names = ', '.join(fields)
        
        cursor.execute(
            f"INSERT OR IGNORE INTO photos ({field_names}) VALUES ({placeholders})",
            values
        )
        self.conn.commit()
        
        # Get the ID of the inserted photo
        cursor.execute('SELECT id FROM photos WHERE file_path = ?', (file_path,))
        result = cursor.fetchone()
        return result[0] if result else None
    
    def get_photo(self, photo_id: int) -> Dict:
        """Get photo details by ID."""
        cursor = self.conn.cursor()
        cursor.execute('SELECT * FROM photos WHERE id = ?', (photo_id,))
        result = cursor.fetchone()
        return dict(result) if result else None
    
    def get_photo_by_path(self, file_path: str) -> Dict:
        """Get photo details by file path."""
        cursor = self.conn.cursor()
        cursor.execute('SELECT * FROM photos WHERE file_path = ?', (file_path,))
        result = cursor.fetchone()
        return dict(result) if result else None
    
    def update_photo(self, photo_id: int, **kwargs) -> bool:
        """Update photo properties."""
        if not kwargs:
            return False
            
        set_clauses = []
        params = []
        
        for key, value in kwargs.items():
            set_clauses.append(f"{key} = ?")
            params.append(value)
        
        params.append(photo_id)
        
        cursor = self.conn.cursor()
        cursor.execute(
            f"UPDATE photos SET {', '.join(set_clauses)} WHERE id = ?",
            params
        )
        self.conn.commit()
        return cursor.rowcount > 0
    
    def delete_photo(self, photo_id: int) -> bool:
        """Delete a photo from the database."""
        cursor = self.conn.cursor()
        cursor.execute('DELETE FROM photos WHERE id = ?', (photo_id,))
        self.conn.commit()
        return cursor.rowcount > 0
    
    def get_photos_by_folder(self, folder_id: int) -> List[Dict]:
        """Get all photos in a specified folder."""
        cursor = self.conn.cursor()
        cursor.execute('SELECT * FROM photos WHERE folder_id = ?', (folder_id,))
        return [dict(row) for row in cursor.fetchall()]
    
    # Enhanced query methods
    def search_photos(self, 
                      keyword: str = None, 
                      folder_ids: List[int] = None, 
                      date_from: str = None, 
                      date_to: str = None, 
                      min_rating: int = None,
                      is_favorite: bool = None,
                      tag_ids: List[int] = None,
                      album_id: int = None,
                      limit: int = 100,
                      offset: int = 0,
                      sort_by: str = 'date_taken',
                      sort_desc: bool = True) -> List[Dict]:
        """
        Search photos with multiple filter criteria.
        
        Args:
            keyword: Search in filename, camera make/model
            folder_ids: List of folder IDs to include
            date_from: Start date (ISO format)
            date_to: End date (ISO format)
            min_rating: Minimum rating (1-5)
            is_favorite: Filter by favorite status
            tag_ids: List of tag IDs that must be associated with photos
            album_id: Filter by album
            limit: Maximum number of results
            offset: Offset for pagination
            sort_by: Field to sort results by
            sort_desc: Whether to sort in descending order
            
        Returns:
            List of photo dictionaries
        """
        query_parts = ['SELECT p.* FROM photos p']
        params = []
        
        # Join tables if needed
        if tag_ids:
            query_parts.append('JOIN photo_tags pt ON p.id = pt.photo_id')
        
        if album_id is not None:
            query_parts.append('JOIN album_photos ap ON p.id = ap.photo_id')
        
        # Build WHERE clause
        where_clauses = []
        
        if keyword:
            where_clauses.append('(p.file_name LIKE ? OR p.camera_make LIKE ? OR p.camera_model LIKE ?)')
            keyword_pattern = f'%{keyword}%'
            params.extend([keyword_pattern, keyword_pattern, keyword_pattern])
        
        if folder_ids:
            placeholders = ', '.join(['?'] * len(folder_ids))
            where_clauses.append(f'p.folder_id IN ({placeholders})')
            params.extend(folder_ids)
        
        if date_from:
            where_clauses.append('p.date_taken >= ?')
            params.append(date_from)
        
        if date_to:
            where_clauses.append('p.date_taken <= ?')
            params.append(date_to)
        
        if min_rating is not None:
            where_clauses.append('p.rating >= ?')
            params.append(min_rating)
        
        if is_favorite is not None:
            where_clauses.append('p.is_favorite = ?')
            params.append(1 if is_favorite else 0)
        
        if tag_ids:
            placeholders = ', '.join(['?'] * len(tag_ids))
            where_clauses.append(f'pt.tag_id IN ({placeholders})')
            params.extend(tag_ids)
        
        if album_id is not None:
            where_clauses.append('ap.album_id = ?')
            params.append(album_id)
        
        # Combine WHERE conditions
        if where_clauses:
            query_parts.append('WHERE ' + ' AND '.join(where_clauses))
        
        # Group by photo ID if joins caused duplicates
        if tag_ids or album_id is not None:
            query_parts.append('GROUP BY p.id')
        
        # Add sorting
        valid_sort_fields = {'id', 'file_name', 'date_taken', 'date_added', 'date_modified', 'rating'}
        if sort_by not in valid_sort_fields:
            sort_by = 'date_taken'
        
        query_parts.append(f'ORDER BY p.{sort_by} {"DESC" if sort_desc else "ASC"}')
        
        # Add limit and offset
        query_parts.append('LIMIT ? OFFSET ?')
        params.extend([limit, offset])
        
        # Execute query
        cursor = self.conn.cursor()
        cursor.execute(' '.join(query_parts), params)
        
        return [dict(row) for row in cursor.fetchall()]
    
    def get_photo_count(self) -> int:
        """Get the total number of photos in the database."""
        cursor = self.conn.cursor()
        cursor.execute('SELECT COUNT(*) FROM photos')
        return cursor.fetchone()[0]
    
    def get_photos_by_date_range(self, start_date: str, end_date: str) -> List[Dict]:
        """
        Get photos taken within a specific date range.
        
        Args:
            start_date: Start date in ISO format
            end_date: End date in ISO format
            
        Returns:
            List of photo dictionaries
        """
        cursor = self.conn.cursor()
        cursor.execute(
            'SELECT * FROM photos WHERE date_taken >= ? AND date_taken <= ? ORDER BY date_taken',
            (start_date, end_date)
        )
        return [dict(row) for row in cursor.fetchall()]
    
    def get_favorite_photos(self, limit: int = 100, offset: int = 0) -> List[Dict]:
        """
        Get photos marked as favorites.
        
        Args:
            limit: Maximum number of results
            offset: Offset for pagination
            
        Returns:
            List of photo dictionaries
        """
        cursor = self.conn.cursor()
        cursor.execute(
            'SELECT * FROM photos WHERE is_favorite = 1 ORDER BY date_taken DESC LIMIT ? OFFSET ?',
            (limit, offset)
        )
        return [dict(row) for row in cursor.fetchall()]
    
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
        cursor = self.conn.cursor()
        cursor.execute(
            'SELECT * FROM photos WHERE rating >= ? ORDER BY rating DESC, date_taken DESC LIMIT ? OFFSET ?',
            (min_rating, limit, offset)
        )
        return [dict(row) for row in cursor.fetchall()]
    
    def get_recent_photos(self, limit: int = 100) -> List[Dict]:
        """
        Get recently added photos.
        
        Args:
            limit: Maximum number of results
            
        Returns:
            List of photo dictionaries
        """
        cursor = self.conn.cursor()
        cursor.execute(
            'SELECT * FROM photos ORDER BY date_added DESC LIMIT ?',
            (limit,)
        )
        return [dict(row) for row in cursor.fetchall()]
    
    # CRUD operations for tags
    def add_tag(self, name: str, parent_id: int = None) -> int:
        """
        Add a new tag to the database.
        
        Args:
            name: Tag name
            parent_id: ID of parent tag (for hierarchical tags)
            
        Returns:
            ID of the new tag
        """
        cursor = self.conn.cursor()
        try:
            cursor.execute(
                'INSERT INTO tags (name, parent_id) VALUES (?, ?)',
                (name, parent_id)
            )
            self.conn.commit()
            return cursor.lastrowid
        except sqlite3.IntegrityError:
            # Tag with this name already exists
            cursor.execute('SELECT id FROM tags WHERE name = ?', (name,))
            result = cursor.fetchone()
            return result[0] if result else None
    
    def get_tag(self, tag_id: int) -> Dict:
        """
        Get tag details by ID.
        
        Args:
            tag_id: ID of the tag
            
        Returns:
            Dictionary with tag information
        """
        cursor = self.conn.cursor()
        cursor.execute('SELECT * FROM tags WHERE id = ?', (tag_id,))
        result = cursor.fetchone()
        return dict(result) if result else None
    
    def get_tag_by_name(self, name: str) -> Dict:
        """
        Get tag details by name.
        
        Args:
            name: Name of the tag
            
        Returns:
            Dictionary with tag information
        """
        cursor = self.conn.cursor()
        cursor.execute('SELECT * FROM tags WHERE name = ?', (name,))
        result = cursor.fetchone()
        return dict(result) if result else None
    
    def update_tag(self, tag_id: int, name: str = None, parent_id: int = None) -> bool:
        """
        Update tag properties.
        
        Args:
            tag_id: ID of the tag to update
            name: New tag name (optional)
            parent_id: New parent tag ID (optional)
            
        Returns:
            True if successful, False otherwise
        """
        updates = []
        params = []
        
        if name is not None:
            updates.append('name = ?')
            params.append(name)
        
        if parent_id is not None or parent_id == 0:  # 0 means remove parent
            updates.append('parent_id = ?')
            params.append(parent_id if parent_id != 0 else None)
        
        if not updates:
            return False
        
        params.append(tag_id)
        
        cursor = self.conn.cursor()
        try:
            cursor.execute(
                f"UPDATE tags SET {', '.join(updates)} WHERE id = ?",
                params
            )
            self.conn.commit()
            return cursor.rowcount > 0
        except sqlite3.IntegrityError:
            return False
    
    def delete_tag(self, tag_id: int) -> bool:
        """
        Delete a tag from the database.
        
        Args:
            tag_id: ID of the tag to delete
            
        Returns:
            True if successful, False otherwise
        """
        cursor = self.conn.cursor()
        
        # Remove tag from photos first
        cursor.execute('DELETE FROM photo_tags WHERE tag_id = ?', (tag_id,))
        
        # Then delete the tag
        cursor.execute('DELETE FROM tags WHERE id = ?', (tag_id,))
        
        # Update any children to remove the parent reference
        cursor.execute('UPDATE tags SET parent_id = NULL WHERE parent_id = ?', (tag_id,))
        
        self.conn.commit()
        return True
    
    def get_all_tags(self) -> List[Dict]:
        """
        Get all tags.
        
        Returns:
            List of tag dictionaries
        """
        cursor = self.conn.cursor()
        cursor.execute('SELECT * FROM tags ORDER BY name')
        return [dict(row) for row in cursor.fetchall()]
    
    def get_tag_hierarchy(self) -> List[Dict]:
        """
        Get the tag hierarchy as a nested structure.
        
        Returns:
            List of dictionaries with tag information and children
        """
        all_tags = {tag['id']: dict(tag) for tag in self.get_all_tags()}
        
        # Add children list to each tag
        for tag_id in all_tags:
            all_tags[tag_id]['children'] = []
        
        # Build hierarchy
        root_tags = []
        
        for tag_id, tag in all_tags.items():
            parent_id = tag.get('parent_id')
            if parent_id is None:
                root_tags.append(tag)
            elif parent_id in all_tags:
                all_tags[parent_id]['children'].append(tag)
        
        return root_tags
    
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
        cursor = self.conn.cursor()
        try:
            cursor.execute(
                'INSERT OR IGNORE INTO photo_tags (photo_id, tag_id) VALUES (?, ?)',
                (photo_id, tag_id)
            )
            self.conn.commit()
            return cursor.rowcount > 0
        except sqlite3.IntegrityError:
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
        cursor = self.conn.cursor()
        cursor.execute(
            'DELETE FROM photo_tags WHERE photo_id = ? AND tag_id = ?',
            (photo_id, tag_id)
        )
        self.conn.commit()
        return cursor.rowcount > 0
    
    def get_tags_for_photo(self, photo_id: int) -> List[Dict]:
        """
        Get all tags associated with a photo.
        
        Args:
            photo_id: ID of the photo
            
        Returns:
            List of tag dictionaries
        """
        cursor = self.conn.cursor()
        cursor.execute(
            '''
            SELECT t.* 
            FROM tags t
            JOIN photo_tags pt ON t.id = pt.tag_id
            WHERE pt.photo_id = ?
            ORDER BY t.name
            ''',
            (photo_id,)
        )
        return [dict(row) for row in cursor.fetchall()]
    
    def get_photos_by_tag(self, tag_id: int, limit: int = 100, offset: int = 0) -> List[Dict]:
        """
        Get all photos with a specific tag.
        
        Args:
            tag_id: ID of the tag
            limit: Maximum number of results
            offset: Offset for pagination
            
        Returns:
            List of photo dictionaries
        """
        cursor = self.conn.cursor()
        cursor.execute(
            '''
            SELECT p.* 
            FROM photos p
            JOIN photo_tags pt ON p.id = pt.photo_id
            WHERE pt.tag_id = ?
            ORDER BY p.date_taken DESC
            LIMIT ? OFFSET ?
            ''',
            (tag_id, limit, offset)
        )
        return [dict(row) for row in cursor.fetchall()]
    
    # CRUD operations for albums
    def create_album(self, name: str, description: str = "") -> int:
        """
        Create a new album.
        
        Args:
            name: Album name
            description: Album description (optional)
            
        Returns:
            ID of the new album
        """
        cursor = self.conn.cursor()
        cursor.execute(
            '''
            INSERT INTO albums (name, description, date_created, date_modified) 
            VALUES (?, ?, datetime('now'), datetime('now'))
            ''',
            (name, description)
        )
        self.conn.commit()
        return cursor.lastrowid
    
    def get_album(self, album_id: int) -> Dict:
        """
        Get album details by ID.
        
        Args:
            album_id: ID of the album
            
        Returns:
            Dictionary with album information
        """
        cursor = self.conn.cursor()
        cursor.execute('SELECT * FROM albums WHERE id = ?', (album_id,))
        result = cursor.fetchone()
        return dict(result) if result else None
    
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
        updates = []
        params = []
        
        if name is not None:
            updates.append('name = ?')
            params.append(name)
        
        if description is not None:
            updates.append('description = ?')
            params.append(description)
        
        if not updates:
            return False
        
        updates.append('date_modified = datetime("now")')
        params.append(album_id)
        
        cursor = self.conn.cursor()
        cursor.execute(
            f"UPDATE albums SET {', '.join(updates)} WHERE id = ?",
            params
        )
        self.conn.commit()
        return cursor.rowcount > 0
    
    def delete_album(self, album_id: int) -> bool:
        """
        Delete an album.
        
        Args:
            album_id: ID of the album to delete
            
        Returns:
            True if successful, False otherwise
        """
        cursor = self.conn.cursor()
        
        # Remove all photo associations first
        cursor.execute('DELETE FROM album_photos WHERE album_id = ?', (album_id,))
        
        # Then delete the album
        cursor.execute('DELETE FROM albums WHERE id = ?', (album_id,))
        
        self.conn.commit()
        return True
    
    def get_all_albums(self) -> List[Dict]:
        """
        Get all albums.
        
        Returns:
            List of album dictionaries
        """
        cursor = self.conn.cursor()
        cursor.execute('SELECT * FROM albums ORDER BY name')
        return [dict(row) for row in cursor.fetchall()]
    
    # Album photo management
    def add_photo_to_album(self, album_id: int, photo_id: int, order_index: int = None) -> bool:
        """
        Add a photo to an album.
        
        Args:
            album_id: ID of the album
            photo_id: ID of the photo
            order_index: Position in the album (optional)
            
        Returns:
            True if successful, False otherwise
        """
        cursor = self.conn.cursor()
        
        # If order_index is not provided, append to the end
        if order_index is None:
            cursor.execute(
                'SELECT MAX(order_index) FROM album_photos WHERE album_id = ?',
                (album_id,)
            )
            result = cursor.fetchone()
            max_order = result[0] if result and result[0] is not None else -1
            order_index = max_order + 1
        
        try:
            cursor.execute(
                '''
                INSERT OR REPLACE INTO album_photos (album_id, photo_id, order_index) 
                VALUES (?, ?, ?)
                ''',
                (album_id, photo_id, order_index)
            )
            
            # Update album modification date
            cursor.execute(
                'UPDATE albums SET date_modified = datetime("now") WHERE id = ?',
                (album_id,)
            )
            
            self.conn.commit()
            return True
        except sqlite3.IntegrityError:
            return False
    
    def remove_photo_from_album(self, album_id: int, photo_id: int) -> bool:
        """
        Remove a photo from an album.
        
        Args:
            album_id: ID of the album
            photo_id: ID of the photo
            
        Returns:
            True if successful, False otherwise
        """
        cursor = self.conn.cursor()
        cursor.execute(
            'DELETE FROM album_photos WHERE album_id = ? AND photo_id = ?',
            (album_id, photo_id)
        )
        
        if cursor.rowcount > 0:
            # Update album modification date
            cursor.execute(
                'UPDATE albums SET date_modified = datetime("now") WHERE id = ?',
                (album_id,)
            )
            
        self.conn.commit()
        return cursor.rowcount > 0
    
    def reorder_album_photos(self, album_id: int, order_map: Dict[int, int]) -> bool:
        """
        Reorder photos within an album.
        
        Args:
            album_id: ID of the album
            order_map: Dictionary mapping photo IDs to new order indices
            
        Returns:
            True if successful, False otherwise
        """
        cursor = self.conn.cursor()
        
        for photo_id, order_index in order_map.items():
            cursor.execute(
                '''
                UPDATE album_photos 
                SET order_index = ? 
                WHERE album_id = ? AND photo_id = ?
                ''',
                (order_index, album_id, photo_id)
            )
        
        # Update album modification date
        cursor.execute(
            'UPDATE albums SET date_modified = datetime("now") WHERE id = ?',
            (album_id,)
        )
        
        self.conn.commit()
        return True
    
    def get_photos_in_album(self, album_id: int) -> List[Dict]:
        """
        Get all photos in an album.
        
        Args:
            album_id: ID of the album
            
        Returns:
            List of photo dictionaries, ordered by their position in the album
        """
        cursor = self.conn.cursor()
        cursor.execute(
            '''
            SELECT p.*, ap.order_index 
            FROM photos p
            JOIN album_photos ap ON p.id = ap.photo_id
            WHERE ap.album_id = ?
            ORDER BY ap.order_index
            ''',
            (album_id,)
        )
        return [dict(row) for row in cursor.fetchall()]
    
    def get_albums_for_photo(self, photo_id: int) -> List[Dict]:
        """
        Get all albums containing a specific photo.
        
        Args:
            photo_id: ID of the photo
            
        Returns:
            List of album dictionaries
        """
        cursor = self.conn.cursor()
        cursor.execute(
            '''
            SELECT a.* 
            FROM albums a
            JOIN album_photos ap ON a.id = ap.album_id
            WHERE ap.photo_id = ?
            ORDER BY a.name
            ''',
            (photo_id,)
        )
        return [dict(row) for row in cursor.fetchall()]

    def find_duplicates(self) -> List[Dict]:
        """
        Find and group photos with identical file hashes.

        Returns:
            List of dictionaries where each dictionary represents a group of duplicate photos.
        """
        cursor = self.conn.cursor()
        cursor.execute(
            '''
            SELECT file_hash, GROUP_CONCAT(id) AS photo_ids
            FROM photos
            WHERE file_hash IS NOT NULL
            GROUP BY file_hash
            HAVING COUNT(*) > 1
            ''')
        
        duplicates = []
        for row in cursor.fetchall():
            duplicates.append({
                "file_hash": row["file_hash"],
                "photo_ids": row["photo_ids"].split(",")
            })
        
        return duplicates

    def move_to_trash(self, photo_id: int, trash_type: str = "application") -> bool:
        """
        Move a photo to the trash (application or system).

        Args:
            photo_id: ID of the photo to move to trash.
            trash_type: Type of trash ('application' or 'system').

        Returns:
            True if the operation was successful, False otherwise.
        """
        cursor = self.conn.cursor()
        photo = self.get_photo_by_id(photo_id)
        if not photo:
            return False

        file_path = photo["file_path"]

        try:
            if trash_type == "application":
                # Move to application trash (e.g., a dedicated folder)
                trash_folder = os.path.join(os.path.dirname(self.conn.database), "app_trash")
                os.makedirs(trash_folder, exist_ok=True)
                os.rename(file_path, os.path.join(trash_folder, os.path.basename(file_path)))
            elif trash_type == "system":
                # Move to system trash (requires `send2trash` library)
                from send2trash import send2trash
                send2trash(file_path)
            else:
                raise ValueError("Invalid trash type")

            # Update database to reflect the file is trashed
            cursor.execute('UPDATE photos SET is_trashed = 1 WHERE id = ?', (photo_id,))
            self.conn.commit()
            return True
        except Exception as e:
            logging.error(f"Failed to move photo {photo_id} to trash: {e}")
            return False

    def permanently_delete_photo(self, photo_id: int) -> bool:
        """
        Permanently delete a photo from the database and file system.

        Args:
            photo_id: ID of the photo to delete.

        Returns:
            True if the operation was successful, False otherwise.
        """
        photo = self.get_photo_by_id(photo_id)
        if not photo:
            return False

        file_path = photo["file_path"]

        try:
            # Delete the file from the file system
            os.remove(file_path)

            # Remove the photo from the database
            return self.delete_photo(photo_id)
        except Exception as e:
            logging.error(f"Failed to permanently delete photo {photo_id}: {e}")
            return False


