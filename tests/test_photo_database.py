# -*- coding: utf-8 -*-
import os
import sys

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../src')))

# Existing imports
import pytest
from core.database import PhotoDatabase


@pytest.fixture
def temp_db_path(tmp_path):
    """Fixture to create a temporary database file."""
    return os.path.join(tmp_path, "test_pixels.db")


@pytest.fixture
def photo_db(temp_db_path):
    """Fixture to initialize the PhotoDatabase with a temporary database."""
    db = PhotoDatabase(temp_db_path)
    yield db
    db.close()


@pytest.fixture
def sample_photos(photo_db):
    """Fixture to populate the database with sample photos."""
    photo_db.add_photo("/path/to/photo1.jpg", folder_id=1, file_hash="hash1")
    photo_db.add_photo("/path/to/photo2.jpg", folder_id=1, file_hash="hash1")
    photo_db.add_photo("/path/to/photo3.jpg", folder_id=1, file_hash="hash2")

    return photo_db


def test_find_duplicates(sample_photos):
    """Test the find_duplicates method."""
    duplicates = sample_photos.find_duplicates()
    assert len(duplicates) == 1
    assert duplicates[0]["file_hash"] == "hash1"
    assert set(duplicates[0]["photo_ids"]) == {"1", "2"}


def test_move_to_trash(photo_db, tmp_path):
    """Test the move_to_trash method."""
    photo_id = photo_db.add_photo("/path/to/photo4.jpg", folder_id=1, file_hash="hash3")
    trash_folder = tmp_path / "app_trash"

    # Mock the trash folder
    os.makedirs(trash_folder, exist_ok=True)
    os.rename = lambda src, dst: None  # Mock os.rename

    result = photo_db.move_to_trash(photo_id, trash_type="application")
    assert result is True


def test_permanently_delete_photo(photo_db):
    """Test the permanently_delete_photo method."""
    photo_id = photo_db.add_photo("/path/to/photo5.jpg", folder_id=1, file_hash="hash4")

    # Mock os.remove
    os.remove = lambda path: None

    result = photo_db.permanently_delete_photo(photo_id)
    assert result is True
