"""
Test the duplicate detection service
"""

import os
import tempfile
import pytest
import shutil
from pathlib import Path
import hashlib

from src.core.duplicate_detection_service import DuplicateDetectionService
from src.core.database import PhotoDatabase


@pytest.fixture
def temp_db():
    """Create a temporary database for testing"""
    with tempfile.NamedTemporaryFile(suffix='.db') as f:
        db_path = f.name
        db = PhotoDatabase(db_path=db_path)
        yield db.db_path
        try:
            os.remove(db_path)
        except:
            pass  # File might be closed/deleted already


@pytest.fixture
def test_library():
    """Create a temporary test library with image files"""
    with tempfile.TemporaryDirectory() as temp_dir:
        # Create test files
        files = {
            "original.jpg": b"test content 1",
            "duplicate.jpg": b"test content 1",  # Exact duplicate
            "unique.jpg": b"different content",   # Unique file
            "subfolder/another_dup.jpg": b"test content 1"  # Duplicate in subfolder
        }
        
        # Create directories and files
        for file_path, content in files.items():
            full_path = os.path.join(temp_dir, file_path)
            os.makedirs(os.path.dirname(full_path), exist_ok=True)
            with open(full_path, 'wb') as f:
                f.write(content)
        
        yield temp_dir


@pytest.fixture
def duplicate_detection_service(temp_db):
    """Create a duplicate detection service with a test database"""
    return DuplicateDetectionService(db_path=temp_db)


@pytest.fixture
def populated_db(duplicate_detection_service, test_library):
    """Populate the database with test images"""
    # Index the test library
    duplicate_detection_service.scan_and_index_folder(test_library)
    return duplicate_detection_service


def test_calculate_file_hash(duplicate_detection_service):
    """Test file hash calculation"""
    with tempfile.NamedTemporaryFile(mode='wb') as f:
        f.write(b'test content')
        f.flush()
        
        # Calculate hash using our service
        hash1 = duplicate_detection_service.calculate_file_hash(f.name)
        
        # Calculate expected hash directly
        hasher = hashlib.sha256()
        with open(f.name, 'rb') as f2:
            hasher.update(f2.read())
        expected_hash = hasher.hexdigest()
        
        # Compare results
        assert hash1 == expected_hash
        assert len(hash1) == 64  # SHA-256 produces 64 character hex strings


def test_find_exact_duplicates(populated_db):
    """Test finding exact duplicate photos"""
    # Find duplicates
    duplicates = populated_db.find_exact_duplicates()
    
    # We should have one group of duplicates with 3 photos
    assert len(duplicates) == 1
    assert len(duplicates[0]['photos']) == 3
    
    # Check if all duplicates have the same hash
    file_hash = duplicates[0]['file_hash']
    for photo in duplicates[0]['photos']:
        assert photo['file_hash'] == file_hash
    
    # Verify unique.jpg is not included
    photo_paths = [photo['file_path'] for photo in duplicates[0]['photos']]
    assert not any('unique.jpg' in path for path in photo_paths)


def test_find_duplicates_in_folder(populated_db):
    """Test finding duplicates within a specific folder"""
    # Get the folder ID of the test library
    folders = populated_db.db.get_all_folders()
    main_folder_id = next(f['id'] for f in folders if not f['parent_id'])
    
    # Find duplicates in the main folder (should only include original.jpg and duplicate.jpg)
    duplicates = populated_db.find_duplicates_in_folder(main_folder_id)
    
    # We should have one group with 2 photos
    assert len(duplicates) == 1
    assert len(duplicates[0]['photos']) == 2
    
    # Verify the subfolder duplicate is not included
    photo_paths = [photo['file_path'] for photo in duplicates[0]['photos']]
    assert not any('subfolder' in path for path in photo_paths)


def test_duplicate_statistics(populated_db):
    """Test getting statistics about duplicates"""
    stats = populated_db.get_duplicate_statistics()
    
    assert stats['total_groups'] == 1
    assert stats['total_duplicates'] == 2  # 3 files total, but only 2 are duplicates
    assert stats['largest_group_size'] == 3
    assert stats['wasted_space_bytes'] > 0
    assert stats['wasted_space_mb'] > 0


def test_suggest_duplicates_to_keep(populated_db):
    """Test the suggestions for which duplicates to keep"""
    duplicates = populated_db.find_exact_duplicates()
    
    # Get suggestions
    suggested_ids = populated_db.suggest_duplicates_to_keep(duplicates[0])
    
    # We should have suggestions for all photos in the group
    assert len(suggested_ids) == len(duplicates[0]['photos'])
    
    # All IDs should be unique
    assert len(set(suggested_ids)) == len(suggested_ids)
    
    # All suggested IDs should correspond to actual photos in the group
    group_ids = [photo['id'] for photo in duplicates[0]['photos']]
    for id in suggested_ids:
        assert id in group_ids


def test_scan_and_index_folder(duplicate_detection_service, test_library):
    """Test scanning and indexing a folder"""
    photos_added, duplicates_found = duplicate_detection_service.scan_and_index_folder(test_library)
    
    # Should find 4 photos total
    assert photos_added >= 4
    
    # Should find 2 duplicates
    assert duplicates_found == 2