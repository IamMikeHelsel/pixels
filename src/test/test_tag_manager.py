import pytest
from src.core.tag_manager import TagManager


@pytest.fixture
def tag_manager():
    return TagManager(db_path=':memory:')


def test_create_tag(tag_manager):
    tag = tag_manager.create_tag(name="Test Tag")
    assert tag is not None
    assert tag['name'] == "test tag"


def test_get_tag_hierarchy(tag_manager):
    parent_tag = tag_manager.create_tag(name="Parent Tag")
    child_tag = tag_manager.create_tag(name="Child Tag", parent_id=parent_tag['id'])
    hierarchy = tag_manager.get_tag_hierarchy()
    assert len(hierarchy) > 0
    # Verify parent-child relationship in hierarchy
    assert len(hierarchy[0]['children']) > 0
    assert hierarchy[0]['children'][0]['name'] == "child tag"


def test_delete_tag(tag_manager):
    tag = tag_manager.create_tag(name="Test Tag")
    result = tag_manager.delete_tag(tag['id'])
    assert result is True
    # Verify the tag is actually deleted
    tags = tag_manager.get_all_tags()
    assert len([t for t in tags if t['name'] == "test tag"]) == 0


def test_update_tag(tag_manager):
    tag = tag_manager.create_tag(name="Original Name")
    result = tag_manager.update_tag(tag['id'], name="Updated Name")
    assert result is True
    updated_tags = tag_manager.get_all_tags()
    assert len([t for t in updated_tags if t['name'] == "updated name"]) == 1


def test_add_tag_to_photo(tag_manager, monkeypatch):
    # Mock the database add_tag_to_photo method to avoid actual DB operations
    monkeypatch.setattr(tag_manager.db, "add_tag_to_photo", lambda photo_id, tag_id: True)
    
    tag = tag_manager.create_tag(name="Photo Tag")
    result = tag_manager.add_tag_to_photo(photo_id=1, tag_id=tag['id'])
    assert result is True


def test_add_tag_by_name_to_photo(tag_manager, monkeypatch):
    # Mock the necessary database methods
    monkeypatch.setattr(tag_manager.db, "get_tag_by_name", lambda name: None)
    monkeypatch.setattr(tag_manager.db, "add_tag", lambda name, parent_id=None: 1)
    monkeypatch.setattr(tag_manager.db, "add_tag_to_photo", lambda photo_id, tag_id: True)
    
    result = tag_manager.add_tag_by_name_to_photo(photo_id=1, tag_name="New Tag")
    assert result is True


def test_find_tag_suggestions(tag_manager):
    # Create some tags first
    tag_manager.create_tag(name="Nature")
    tag_manager.create_tag(name="Natural Beauty")
    tag_manager.create_tag(name="Wildlife")
    
    # Test partial matching
    suggestions = tag_manager.find_tag_suggestions("nat")
    assert len(suggestions) == 2
    assert "nature" in [tag['name'] for tag in suggestions]
    assert "natural beauty" in [tag['name'] for tag in suggestions]


def test_set_photo_rating(tag_manager, monkeypatch):
    # Mock the database update_photo method
    monkeypatch.setattr(tag_manager.db, "update_photo", lambda photo_id, **kwargs: True)
    
    # Test setting valid rating
    result = tag_manager.set_photo_rating(photo_id=1, rating=5)
    assert result is True
    
    # Test with out-of-range rating (should be clamped to 0-5)
    result = tag_manager.set_photo_rating(photo_id=1, rating=10)
    assert result is True


def test_toggle_photo_favorite(tag_manager, monkeypatch):
    # Mock the necessary database methods
    monkeypatch.setattr(tag_manager.db, "get_photo", lambda photo_id: {'id': 1, 'is_favorite': 0})
    monkeypatch.setattr(tag_manager.db, "update_photo", lambda photo_id, **kwargs: True)
    
    # Test toggling favorite status
    new_status = tag_manager.toggle_photo_favorite(photo_id=1)
    assert new_status is True  # Changed from 0 (False) to 1 (True)
