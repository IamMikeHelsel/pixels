import pytest
from src.core.album_manager import AlbumManager

@pytest.fixture
def album_manager():
    return AlbumManager(db_path=':memory:')

def test_create_album(album_manager):
    album = album_manager.create_album(name="Test Album", description="A test album")
    assert album is not None
    assert album['name'] == "Test Album"

def test_get_album(album_manager):
    album = album_manager.create_album(name="Test Album")
    retrieved_album = album_manager.get_album(album['id'])
    assert retrieved_album is not None
    assert retrieved_album['id'] == album['id']

def test_delete_album(album_manager):
    album = album_manager.create_album(name="Test Album")
    result = album_manager.delete_album(album['id'])
    assert result is True
    assert album_manager.get_album(album['id']) is None