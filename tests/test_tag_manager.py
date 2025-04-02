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
    tag_manager.create_tag(name="Parent Tag")
    hierarchy = tag_manager.get_tag_hierarchy()
    assert len(hierarchy) > 0


def test_delete_tag(tag_manager):
    tag = tag_manager.create_tag(name="Test Tag")
    result = tag_manager.delete_tag(tag['id'])
    assert result is True
