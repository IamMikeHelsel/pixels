import os
from PIL import Image
from PyQt5.QtCore import Qt
from PyQt5.QtGui import QIcon
from PyQt5.QtWidgets import QListWidgetItem

def search_images(keyword, image_list):
    return [image for image in image_list if keyword.lower() in os.path.basename(image).lower()]

def filter_images_by_format(image_list, formats):
    return [image for image in image_list if image.lower().endswith(tuple(formats))]

def display_metadata(image_path):
    image = Image.open(image_path)
    metadata = {
        "Format": image.format,
        "Mode": image.mode,
        "Size": image.size,
        "Info": image.info
    }
    return metadata

def add_search_functionality(photo_browser):
    search_keyword = photo_browser.search_input.text()
    filtered_images = search_images(search_keyword, photo_browser.image_list)
    photo_browser.thumbnail_list.clear()
    for image_path in filtered_images:
        thumbnail = photo_browser.load_thumbnail(image_path)
        item = QListWidgetItem(QIcon(thumbnail), "")
        item.setData(Qt.UserRole, image_path)
        photo_browser.thumbnail_list.addItem(item)

def add_filter_functionality(photo_browser, formats):
    filtered_images = filter_images_by_format(photo_browser.image_list, formats)
    photo_browser.thumbnail_list.clear()
    for image_path in filtered_images:
        thumbnail = photo_browser.load_thumbnail(image_path)
        item = QListWidgetItem(QIcon(thumbnail), "")
        item.setData(Qt.UserRole, image_path)
        photo_browser.thumbnail_list.addItem(item)
