import pytest
from src.core.thumbnail_service import ThumbnailService


@pytest.fixture
def thumbnail_service():
    return ThumbnailService()


def test_generate_thumbnail(thumbnail_service):
    thumbnail_path = thumbnail_service.generate_thumbnail("/path/to/photo.jpg", size="sm")
    assert thumbnail_path is not None
    assert thumbnail_path.endswith("_sm.jpg")


def test_cache_thumbnail(thumbnail_service):
    thumbnail_service.generate_thumbnail("/path/to/photo.jpg", size="sm")
    cached_path = thumbnail_service.get_cached_thumbnail("/path/to/photo.jpg", size="sm")
    assert cached_path is not None
