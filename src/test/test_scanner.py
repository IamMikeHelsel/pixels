import os
import tempfile
from pathlib import Path

import pytest
from src.core.scanner import FileSystemScanner, get_scan_summary


@pytest.fixture
def scanner():
    return FileSystemScanner()


@pytest.fixture
def test_directory():
    with tempfile.TemporaryDirectory() as temp_dir:
        # Create test files
        Path(temp_dir, "test1.jpg").touch()
        Path(temp_dir, "test2.png").touch()
        Path(temp_dir, "test.txt").touch()  # Unsupported format

        # Create subdirectory with files
        subdir = Path(temp_dir, "subdir")
        subdir.mkdir()
        Path(subdir, "test3.jpg").touch()

        yield temp_dir


def test_scan_directory(scanner, test_directory):
    result = scanner.scan_directory(test_directory, recursive=True)
    assert len(result) == 2  # Two directories (root and subdir)
    assert len(result[test_directory]) == 2  # Two images in root
    assert len(result[str(Path(test_directory, "subdir"))]) == 1  # One image in subdir


def test_scan_directory_non_recursive(scanner, test_directory):
    result = scanner.scan_directory(test_directory, recursive=False)
    assert len(result) == 1  # Only root directory
    assert len(result[test_directory]) == 2  # Two images in root


def test_scan_nonexistent_directory(scanner):
    result = scanner.scan_directory("/nonexistent/path")
    assert result == {}


def test_supported_image_detection(scanner):
    assert scanner._is_supported_image("test.jpg") is True
    assert scanner._is_supported_image("test.jpeg") is True
    assert scanner._is_supported_image("test.png") is True
    assert scanner._is_supported_image("test.txt") is False


def test_scan_multiple_directories(scanner, test_directory):
    # Create a second test directory
    with tempfile.TemporaryDirectory() as second_dir:
        Path(second_dir, "test4.jpg").touch()

        result = scanner.scan_directories([test_directory, second_dir])
        assert len(result) == 3  # Root, subdir, and second directory
        assert sum(len(files) for files in result.values()) == 4  # Total images


def test_scan_empty_directory(scanner):
    with tempfile.TemporaryDirectory() as temp_dir:
        result = scanner.scan_directory(temp_dir)
        assert result == {}


def test_scan_directory_without_permission():
    with tempfile.TemporaryDirectory() as temp_dir:
        # Remove read permission
        os.chmod(temp_dir, 0o000)
        try:
            scanner = FileSystemScanner()
            result = scanner.scan_directory(temp_dir)
            assert result == {}
        finally:
            # Restore permissions to allow cleanup
            os.chmod(temp_dir, 0o755)


def test_get_scan_summary():
    scan_result = {
        "/test": ["photo1.jpg", "photo2.jpg"],
        "/test/subfolder": ["photo3.jpg"]
    }
    summary = get_scan_summary(scan_result)
    assert "3 images in 2 folders" in summary
    assert "/test: 2 images" in summary
    assert "/test/subfolder: 1 images" in summary
