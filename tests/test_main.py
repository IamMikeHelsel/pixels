import pytest
from PyQt5.QtWidgets import QApplication
from main import PhotoBrowser, ThumbnailLoader
import os
import sys

@pytest.fixture(scope="module")
def app():
    app = QApplication(sys.argv)
    yield app
    app.quit()

@pytest.fixture
def photo_browser():
    return PhotoBrowser()

def test_photo_browser_initialization(photo_browser):
    assert photo_browser.windowTitle() == "Blazingly Fast Python Photo Browser"
    assert photo_browser.geometry().width() == 800
    assert photo_browser.geometry().height() == 600

def test_photo_browser_open_folder(photo_browser, tmpdir):
    test_dir = tmpdir.mkdir("test_images")
    test_image = test_dir.join("test_image.jpg")
    test_image.write("test content")
    photo_browser.load_images(str(test_dir))
    assert len(photo_browser.image_list) == 1
    assert photo_browser.image_list[0] == str(test_image)

def test_photo_browser_add_thumbnail(photo_browser, tmpdir):
    test_dir = tmpdir.mkdir("test_images")
    test_image = test_dir.join("test_image.jpg")
    test_image.write("test content")
    photo_browser.add_thumbnail(str(test_image), str(test_image))
    assert photo_browser.thumbnail_list.count() == 1

def test_thumbnail_loader(tmpdir):
    test_dir = tmpdir.mkdir("test_images")
    test_image = test_dir.join("test_image.jpg")
    test_image.write("test content")
    loader = ThumbnailLoader(str(test_image))
    loader.run()
    thumbnail_path = os.path.join(test_dir, "thumbnail_test_image.jpg")
    assert os.path.exists(thumbnail_path)
