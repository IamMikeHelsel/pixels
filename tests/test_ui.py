import pytest
from PyQt5.QtWidgets import QListWidgetItem
from ui import ThumbnailView, FullScreenView, SlideshowView, PhotoBrowserUI

@pytest.fixture
def thumbnail_view(qtbot):
    view = ThumbnailView()
    qtbot.addWidget(view)
    return view

@pytest.fixture
def full_screen_view(qtbot):
    view = FullScreenView()
    qtbot.addWidget(view)
    return view

@pytest.fixture
def slideshow_view(qtbot):
    view = SlideshowView()
    qtbot.addWidget(view)
    return view

@pytest.fixture
def photo_browser_ui(qtbot):
    ui = PhotoBrowserUI()
    qtbot.addWidget(ui)
    return ui

def test_thumbnail_view_add_thumbnail(thumbnail_view, qtbot):
    image_path = "path/to/image.jpg"
    thumbnail_view.add_thumbnail(image_path)
    assert thumbnail_view.thumbnail_list.count() == 1
    item = thumbnail_view.thumbnail_list.item(0)
    assert item.data(Qt.UserRole) == image_path

def test_thumbnail_view_highlight_photo(thumbnail_view, qtbot):
    item1 = QListWidgetItem()
    item2 = QListWidgetItem()
    thumbnail_view.thumbnail_list.addItem(item1)
    thumbnail_view.thumbnail_list.addItem(item2)
    thumbnail_view.highlight_photo(item1)
    assert item1.isSelected()
    assert not item2.isSelected()

def test_full_screen_view_show_image(full_screen_view, qtbot):
    image_path = "path/to/image.jpg"
    full_screen_view.show_image(image_path)
    assert full_screen_view.image_label.pixmap() is not None

def test_slideshow_view_show_image(slideshow_view, qtbot):
    image_path = "path/to/image.jpg"
    slideshow_view.show_image(image_path)
    assert slideshow_view.image_label.pixmap() is not None

def test_photo_browser_ui_switch_to_thumbnail_view(photo_browser_ui, qtbot):
    photo_browser_ui.switch_to_thumbnail_view()
    assert photo_browser_ui.stacked_widget.currentWidget() == photo_browser_ui.thumbnail_view

def test_photo_browser_ui_switch_to_full_screen_view(photo_browser_ui, qtbot):
    photo_browser_ui.switch_to_full_screen_view()
    assert photo_browser_ui.stacked_widget.currentWidget() == photo_browser_ui.full_screen_view

def test_photo_browser_ui_switch_to_slideshow_view(photo_browser_ui, qtbot):
    photo_browser_ui.switch_to_slideshow_view()
    assert photo_browser_ui.stacked_widget.currentWidget() == photo_browser_ui.slideshow_view

def test_photo_browser_ui_highlight_photo(photo_browser_ui, qtbot):
    item = QListWidgetItem()
    photo_browser_ui.thumbnail_view.thumbnail_list.addItem(item)
    photo_browser_ui.highlight_photo(item)
    assert item.isSelected()
