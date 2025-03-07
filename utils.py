import os
from PIL import Image

def load_image(image_path):
    return Image.open(image_path)

def save_image(image, image_path):
    image.save(image_path)

def create_thumbnail(image_path, thumbnail_size=(100, 100)):
    image = load_image(image_path)
    image.thumbnail(thumbnail_size)
    thumbnail_path = os.path.join(os.path.dirname(image_path), "thumbnail_" + os.path.basename(image_path))
    save_image(image, thumbnail_path)
    return thumbnail_path

def crop_image(image, crop_box):
    return image.crop(crop_box)

def rotate_image(image, angle):
    return image.rotate(angle)

def resize_image(image, size):
    return image.resize(size)

def cache_image(image_path, cache_dir):
    if not os.path.exists(cache_dir):
        os.makedirs(cache_dir)
    image = load_image(image_path)
    cached_image_path = os.path.join(cache_dir, os.path.basename(image_path))
    save_image(image, cached_image_path)
    return cached_image_path
