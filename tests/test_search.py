import pytest
from search import search_images, filter_images_by_format, display_metadata

def test_search_images():
    image_list = ["photo1.jpg", "photo2.png", "holiday_photo.jpg", "birthday.png"]
    result = search_images("photo", image_list)
    assert result == ["photo1.jpg", "holiday_photo.jpg"]

def test_filter_images_by_format():
    image_list = ["photo1.jpg", "photo2.png", "holiday_photo.jpg", "birthday.png"]
    result = filter_images_by_format(image_list, [".jpg"])
    assert result == ["photo1.jpg", "holiday_photo.jpg"]

def test_display_metadata():
    image_path = "tests/test_image.jpg"
    metadata = display_metadata(image_path)
    assert metadata["Format"] == "JPEG"
    assert metadata["Mode"] == "RGB"
    assert metadata["Size"] == (800, 600)
    assert "Info" in metadata
