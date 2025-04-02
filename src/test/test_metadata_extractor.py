import io

import pytest
from PIL import Image
from src.core.metadata_extractor import MetadataExtractor


@pytest.fixture
def extractor():
    return MetadataExtractor()


@pytest.fixture
def sample_image():
    # Create a small test image in memory
    img = Image.new('RGB', (100, 100))
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='JPEG')
    img_byte_arr.seek(0)
    return img_byte_arr


def test_basic_metadata_extraction(extractor, tmp_path):
    # Save test image to disk
    image_path = tmp_path / "test.jpg"
    img = Image.new('RGB', (100, 100))
    img.save(image_path)

    metadata = extractor.extract_metadata(str(image_path))
    assert metadata["file_name"] == "test.jpg"
    assert metadata["width"] == 100
    assert metadata["height"] == 100
    assert "file_size" in metadata
    assert "date_modified" in metadata


def test_exif_extraction(extractor):
    # Create image with EXIF data
    img = Image.new('RGB', (100, 100))
    exif_bytes = b'Exif\x00\x00II*\x00\x08\x00\x00\x00'
    img.info['exif'] = exif_bytes

    exif_data = extractor._extract_exif(img)
    assert isinstance(exif_data, dict)


def test_process_rational(extractor):
    assert extractor._process_rational((1, 2)) == 0.5
    assert extractor._process_rational((1, 0)) is None  # Division by zero
    assert extractor._process_rational("invalid") is None


def test_nonexistent_file(extractor):
    metadata = extractor.extract_metadata("/nonexistent/image.jpg")
    assert "error" in metadata
    assert metadata["file_name"] == "image.jpg"


def test_gps_info_extraction(extractor):
    gps_info = {
        1: "N",  # GPSLatitudeRef
        2: ((51, 1), (30, 1), (0, 1)),  # GPSLatitude
        3: "E",  # GPSLongitudeRef
        4: ((0, 1), (10, 1), (0, 1)),  # GPSLongitude
    }

    result = extractor._extract_gps_info(gps_info)
    assert "latitude" in result
    assert "longitude" in result
    assert result["latitude"] == pytest.approx(51.5)
    assert result["longitude"] == pytest.approx(0.167)


def test_corrupted_image_handling(extractor, tmp_path):
    # Create a corrupted image file
    image_path = tmp_path / "corrupted.jpg"
    with open(image_path, 'wb') as f:
        f.write(b'not a valid image')

    metadata = extractor.extract_metadata(str(image_path))
    assert "error" in metadata
    assert metadata["file_name"] == "corrupted.jpg"


def test_date_parsing(extractor):
    # Test various date formats in EXIF
    test_dates = {
        "2024:03:21 15:30:00": True,  # Valid format
        "2024-03-21 15:30:00": False,  # Invalid format
        "invalid date": False,  # Invalid date
    }

    for date_str, should_parse in test_dates.items():
        img = Image.new('RGB', (100, 100))
        img.info['exif_data'] = {"DateTimeOriginal": date_str}
        result = extractor._extract_exif(img)
        if should_parse:
            assert "date_taken" in result
        else:
            assert "date_taken" not in result


def test_minimal_exif_handling(extractor):
    # Test with minimal EXIF data
    img = Image.new('RGB', (100, 100))
    img.info['exif_data'] = {
        "Make": "TestCamera",
        "Model": "TestModel"
    }
    exif_data = extractor._extract_exif(img)
    assert isinstance(exif_data, dict)
    assert exif_data.get('camera_make') == "TestCamera"
    assert exif_data.get('camera_model') == "TestModel"


def test_invalid_gps_data(extractor):
    invalid_gps_info = {
        1: "Invalid",  # Invalid ref
        2: ((91, 1), (0, 1)),  # Invalid latitude
        3: "E",
        4: ((0, 1), (0, 1))
    }

    result = extractor._extract_gps_info(invalid_gps_info)
    assert result == {}
