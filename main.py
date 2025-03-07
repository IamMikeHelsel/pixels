import sys
from PyQt5.QtWidgets import QApplication, QMainWindow, QLabel, QVBoxLayout, QWidget, QPushButton, QFileDialog, QListWidget, QListWidgetItem
from PyQt5.QtGui import QPixmap, QIcon
from PyQt5.QtCore import Qt, QTimer, QThread, pyqtSignal, QSize
from PIL import Image
import os

class ThumbnailLoader(QThread):
    thumbnail_loaded = pyqtSignal(str, str)

    def __init__(self, image_path):
        super().__init__()
        self.image_path = image_path

    def run(self):
        image = Image.open(self.image_path)
        image.thumbnail((100, 100))
        thumbnail_path = os.path.join(os.path.dirname(self.image_path), "thumbnail_" + os.path.basename(self.image_path))
        image.save(thumbnail_path)
        self.thumbnail_loaded.emit(self.image_path, thumbnail_path)

class PhotoBrowser(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Blazingly Fast Python Photo Browser")
        self.setGeometry(100, 100, 800, 600)
        
        self.image_label = QLabel(self)
        self.image_label.setAlignment(Qt.AlignCenter)
        
        self.thumbnail_list = QListWidget(self)
        self.thumbnail_list.setViewMode(QListWidget.IconMode)
        self.thumbnail_list.setIconSize(QSize(100, 100))
        self.thumbnail_list.setResizeMode(QListWidget.Adjust)
        self.thumbnail_list.itemClicked.connect(self.highlight_photo)
        
        self.slideshow_timer = QTimer(self)
        self.slideshow_timer.timeout.connect(self.next_image)
        
        self.init_ui()
        
        self.image_cache = {}
        self.image_list = []
        self.current_image_index = 0

    def init_ui(self):
        layout = QVBoxLayout()
        
        open_button = QPushButton("Open Folder", self)
        open_button.clicked.connect(self.open_folder)
        
        slideshow_button = QPushButton("Start Slideshow", self)
        slideshow_button.clicked.connect(self.start_slideshow)
        
        layout.addWidget(open_button)
        layout.addWidget(slideshow_button)
        layout.addWidget(self.thumbnail_list)
        layout.addWidget(self.image_label)
        
        container = QWidget()
        container.setLayout(layout)
        self.setCentralWidget(container)
        
    def open_folder(self):
        folder_path = QFileDialog.getExistingDirectory(self, "Select Folder")
        if folder_path:
            self.load_images(folder_path)
            
    def load_images(self, folder_path):
        self.image_list = [os.path.join(folder_path, f) for f in os.listdir(folder_path) if f.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.gif'))]
        for i in range(self.thumbnail_list.count()):
            item = self.thumbnail_list.item(i)
            item.setHidden(True)
        for image_path in self.image_list:
            if image_path not in self.image_cache:
                loader = ThumbnailLoader(image_path)
                loader.thumbnail_loaded.connect(self.add_thumbnail)
                loader.start()
            else:
                for i in range(self.thumbnail_list.count()):
                    item = self.thumbnail_list.item(i)
                    if item.data(Qt.UserRole) == image_path:
                        item.setHidden(False)
                        break

    def add_thumbnail(self, image_path, thumbnail_path):
        self.image_cache[image_path] = thumbnail_path
        item = QListWidgetItem(QIcon(thumbnail_path), "")
        item.setData(Qt.UserRole, image_path)
        self.thumbnail_list.addItem(item)
        
    def highlight_photo(self, item):
        for i in range(self.thumbnail_list.count()):
            self.thumbnail_list.item(i).setSelected(False)
        item.setSelected(True)
        
    def show_image(self, item):
        image_path = item.data(Qt.UserRole)
        pixmap = QPixmap(image_path)
        self.image_label.setPixmap(pixmap)
        
    def start_slideshow(self):
        self.slideshow_timer.start(2000)
        
    def next_image(self):
        self.current_image_index = (self.current_image_index + 1) % len(self.image_list)
        image_path = self.image_list[self.current_image_index]
        pixmap = QPixmap(image_path)
        self.image_label.setPixmap(pixmap)
        
if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = PhotoBrowser()
    window.show()
    sys.exit(app.exec_())
