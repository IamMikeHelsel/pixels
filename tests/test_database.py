import pytest
from src.core.database import PhotoDatabase


@pytest.fixture
def photo_database():
    return PhotoDatabase(db_path=':memory:')


def test_add_folder(photo_database):
    folder_id = photo_database.add_folder(path="/test/folder", name="Test Folder")
    assert folder_id is not None
    folder = photo_database.get_folder(folder_id)
    assert folder['name'] == "Test Folder"


def test_add_photo(photo_database):
    folder_id = photo_database.add_folder(path="/test/folder")
    photo_id = photo_database.add_photo(file_path="/test/folder/photo.jpg", folder_id=folder_id)
    assert photo_id is not None
    photo = photo_database.get_photo(photo_id)
    assert photo['file_path'] == "/test/folder/photo.jpg"


def test_find_duplicates(photo_database):
    folder_id = photo_database.add_folder(path="/test/folder")
    photo_database.add_photo(file_path="/test/folder/photo1.jpg", folder_id=folder_id, file_hash="hash1")
    photo_database.add_photo(file_path="/test/folder/photo2.jpg", folder_id=folder_id, file_hash="hash1")
    duplicates = photo_database.find_duplicates()
    assert len(duplicates) == 1
    assert duplicates[0]['file_hash'] == "hash1"
