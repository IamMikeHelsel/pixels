import shutil
import tempfile
from pathlib import Path

import pytest
from src.core.library_indexer import LibraryIndexer


@pytest.fixture
def indexer():
    return LibraryIndexer(db_path=":memory:")


@pytest.fixture
def test_library():
    with tempfile.TemporaryDirectory() as temp_dir:
        # Create test directory structure
        photos_dir = Path(temp_dir) / "photos"
        photos_dir.mkdir()

        # Create some test images
        (photos_dir / "test1.jpg").touch()
        (photos_dir / "test2.jpg").touch()

        # Create a subdirectory with images
        subdir = photos_dir / "vacation"
        subdir.mkdir()
        (subdir / "beach.jpg").touch()

        yield str(photos_dir)


def test_index_folder(indexer, test_library):
    folders_added, photos_added, elapsed = indexer.index_folder(test_library, recursive=True)
    assert folders_added == 2  # Root and one subdirectory
    assert photos_added == 3  # Three total images
    assert elapsed > 0


def test_index_folder_non_recursive(indexer, test_library):
    folders_added, photos_added, elapsed = indexer.index_folder(test_library, recursive=False)
    assert folders_added == 1  # Only root directory
    assert photos_added == 2  # Only images in root


def test_refresh_index(indexer, test_library):
    # First index the folder
    indexer.index_folder(test_library, recursive=True, monitor=True)

    # Add a new file
    new_file = Path(test_library) / "new.jpg"
    new_file.touch()

    # Refresh index
    folders_updated, photos_added, elapsed = indexer.refresh_index()
    assert folders_updated >= 1
    assert photos_added == 1  # One new photo
    assert elapsed > 0


def test_duplicate_detection(indexer, test_library):
    # Create a duplicate file with identical content
    orig_file = Path(test_library) / "original.jpg"
    dup_file = Path(test_library) / "duplicate.jpg"

    # Create files with same content
    with open(orig_file, 'wb') as f:
        f.write(b'test content')
    with open(dup_file, 'wb') as f:
        f.write(b'test content')

    # Index the folder
    indexer.index_folder(test_library, recursive=True)

    # Check for duplicates
    duplicates = indexer.identify_duplicates()
    assert len(duplicates) == 1  # One group of duplicates
    assert len(duplicates[0]) == 2  # Two files in the group


def test_process_images_parallel(indexer, test_library):
    # Test parallel processing with different numbers of workers
    indexer.max_workers = 2
    folders_added, photos_added, elapsed = indexer.index_folder(test_library, recursive=True)
    assert photos_added == 3  # Should index all photos regardless of worker count


def test_monitored_folders(indexer, test_library):
    # Index with monitoring enabled
    indexer.index_folder(test_library, recursive=True, monitor=True)

    # Check monitored folders
    monitored = indexer._get_monitored_folders()
    assert len(monitored) >= 1
    assert monitored[0]["path"] == test_library


def test_handle_missing_monitored_folder(indexer, test_library):
    # Index a folder then delete it
    indexer.index_folder(test_library, recursive=True, monitor=True)
    shutil.rmtree(test_library)

    # Refresh should handle missing folder gracefully
    folders_updated, photos_added, elapsed = indexer.refresh_index()
    assert folders_updated == 0
    assert photos_added == 0


def test_concurrent_indexing(indexer, test_library):
    # Test with different worker counts
    for workers in [1, 2, 4, 8]:
        indexer.max_workers = workers
        folders_added, photos_added, elapsed = indexer.index_folder(test_library, recursive=True)
        assert photos_added == 3  # Should find all photos regardless of worker count


def test_hash_calculation(indexer):
    with tempfile.NamedTemporaryFile(mode='wb') as f:
        f.write(b'test content')
        f.flush()

        hash1 = indexer._calculate_file_hash(f.name)
        assert isinstance(hash1, str)
        assert len(hash1) == 64  # SHA-256 hash length

        # Test with different block sizes
        hash2 = indexer._calculate_file_hash(f.name, block_size=1024)
        assert hash1 == hash2  # Hash should be the same regardless of block size


def test_duplicate_handling_edge_cases(indexer, test_library):
    # Test handling of zero-byte files
    file1 = Path(test_library) / "empty1.jpg"
    file2 = Path(test_library) / "empty2.jpg"
    file1.touch()
    file2.touch()

    indexer.index_folder(test_library, recursive=True)
    duplicates = indexer.identify_duplicates()

    # Zero-byte files should be identified as duplicates
    assert any(len(group) == 2 for group in duplicates)


@pytest.mark.parametrize("max_workers", [1, 2, 4])
def test_parallel_processing_stress(indexer, test_library, max_workers):
    # Create many small files to test parallel processing
    for i in range(20):
        path = Path(test_library) / f"test{i}.jpg"
        path.touch()

    indexer.max_workers = max_workers
    folders_added, photos_added, elapsed = indexer.index_folder(test_library, recursive=True)

    # All files should be processed regardless of worker count
    assert photos_added >= 20  # Including existing test files
