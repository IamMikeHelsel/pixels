from PyQt5.QtWidgets import QWidget, QVBoxLayout, QLabel, QListWidget, QListWidgetItem, QStackedWidget
from PyQt5.QtGui import QPixmap, QIcon
from PyQt5.QtCore import Qt, QSize, pyqtSignal

class ThumbnailView(QWidget):
    photoSelected = pyqtSignal(QListWidgetItem)  # P4890

    def __init__(self, parent=None):
        super().__init__(parent)
        self.layout = QVBoxLayout(self)
        self.thumbnail_list = QListWidget(self)
        self.thumbnail_list.setViewMode(QListWidget.IconMode)
        self.thumbnail_list.setIconSize(QSize(100, 100))
        self.thumbnail_list.setResizeMode(QListWidget.Adjust)
        self.thumbnail_list.itemClicked.connect(self.on_item_clicked)  # P4890
        self.layout.addWidget(self.thumbnail_list)

    def add_thumbnail(self, image_path):
        thumbnail = QPixmap(image_path)
        item = QListWidgetItem(QIcon(thumbnail), "")
        item.setData(Qt.UserRole, image_path)
        self.thumbnail_list.addItem(item)

    def on_item_clicked(self, item):  # P4890
        self.photoSelected.emit(item)

    def highlight_photo(self, item):  # Pe19c
        for i in range(self.thumbnail_list.count()):
            self.thumbnail_list.item(i).setSelected(False)
        item.setSelected(True)

class FullScreenView(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.layout = QVBoxLayout(self)
        self.image_label = QLabel(self)
        self.image_label.setAlignment(Qt.AlignCenter)
        self.layout.addWidget(self.image_label)

    def show_image(self, image_path):
        pixmap = QPixmap(image_path)
        self.image_label.setPixmap(pixmap)

class SlideshowView(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.layout = QVBoxLayout(self)
        self.image_label = QLabel(self)
        self.image_label.setAlignment(Qt.AlignCenter)
        self.layout.addWidget(self.image_label)

    def show_image(self, image_path):
        pixmap = QPixmap(image_path)
        self.image_label.setPixmap(pixmap)

class PhotoBrowserUI(QWidget):
    def __init__(self, parent=None):
        super().__init__(parent)
        self.layout = QVBoxLayout(self)
        self.stacked_widget = QStackedWidget(self)
        self.thumbnail_view = ThumbnailView(self)
        self.full_screen_view = FullScreenView(self)
        self.slideshow_view = SlideshowView(self)
        self.stacked_widget.addWidget(self.thumbnail_view)
        self.stacked_widget.addWidget(self.full_screen_view)
        self.stacked_widget.addWidget(self.slideshow_view)
        self.layout.addWidget(self.stacked_widget)
        self.thumbnail_view.photoSelected.connect(self.highlight_photo)  # P7df4

    def switch_to_thumbnail_view(self):
        self.stacked_widget.setCurrentWidget(self.thumbnail_view)

    def switch_to_full_screen_view(self):
        self.stacked_widget.setCurrentWidget(self.full_screen_view)

    def switch_to_slideshow_view(self):
        self.stacked_widget.setCurrentWidget(self.slideshow_view)

    def highlight_photo(self, item):  # P7df4
        self.thumbnail_view.highlight_photo(item)
