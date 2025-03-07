import os
import pytest
from PIL import Image
from utils import load_image, save_image, create_thumbnail, crop_image, rotate_image, resize_image, cache_image

@pytest.fixture
def sample_image(tmp_path):
    image_path = tmp_path / "sample.jpg"
    image = Image.new("RGB", (200, 200), color="red")
    image.save(image_path)
    return image_path

def test_load_image(sample_image):
    image = load_image(sample_image)
    assert image is not None
    assert image.size == (200, 200)

def test_save_image(tmp_path):
    image = Image.new("RGB", (100, 100), color="blue")
    image_path = tmp_path / "saved_image.jpg"
    save_image(image, image_path)
    assert os.path.exists(image_path)

def test_create_thumbnail(sample_image):
    thumbnail_path = create_thumbnail(sample_image)
    assert os.path.exists(thumbnail_path)
    thumbnail = load_image(thumbnail_path)
    assert thumbnail.size == (100, 100)

def test_crop_image(sample_image):
    image = load_image(sample_image)
    cropped_image = crop_image(image, (50, 50, 150, 150))
    assert cropped_image.size == (100, 100)

def test_rotate_image(sample_image):
    image = load_image(sample_image)
    rotated_image = rotate_image(image, 90)
    assert rotated_image.size == (200, 200)

def test_resize_image(sample_image):
    image = load_image(sample_image)
    resized_image = resize_image(image, (50, 50))
    assert resized_image.size == (50, 50)

def test_cache_image(sample_image, tmp_path):
    cache_dir = tmp_path / "cache"
    cached_image_path = cache_image(sample_image, cache_dir)
    assert os.path.exists(cached_image_path)
    cached_image = load_image(cached_image_path)
    assert cached_image.size == (200, 200)
