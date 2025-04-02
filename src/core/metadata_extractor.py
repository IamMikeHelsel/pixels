"""
Metadata Extractor module for the Pixels photo manager application.

This module provides functionality to extract metadata from image files.
"""

import datetime
import logging
import os
from typing import Dict, Optional, Any

# Use Pillow for basic image operations and EXIF extraction
try:
    from PIL import Image, ExifTags
    from PIL.ExifTags import TAGS, GPSTAGS
except ImportError:
    logging.error("Pillow library not found. Install using: pip install Pillow")
    raise

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class MetadataExtractor:
    """Extractor for image metadata."""

    def __init__(self):
        """Initialize the metadata extractor."""
        pass

    def extract_metadata(self, image_path: str) -> Dict[str, Any]:
        """
        Extract metadata from an image file.
        
        Args:
            image_path: Path to the image file
            
        Returns:
            A dictionary containing metadata fields
        """
        if not os.path.exists(image_path):
            logger.error(f"Image file does not exist: {image_path}")
            return {}

        try:
            # Get basic file information
            file_stats = os.stat(image_path)
            file_size = file_stats.st_size
            file_modified = datetime.datetime.fromtimestamp(file_stats.st_mtime).isoformat()

            metadata = {
                "file_path": image_path,
                "file_name": os.path.basename(image_path),
                "file_size": file_size,
                "date_modified": file_modified
            }

            # Open the image to extract dimensions and EXIF data
            with Image.open(image_path) as img:
                # Get dimensions
                metadata["width"], metadata["height"] = img.size

                # Extract EXIF data if available
                exif_data = self._extract_exif(img)
                if exif_data:
                    metadata.update(exif_data)

            return metadata

        except Exception as e:
            logger.error(f"Error extracting metadata from {image_path}: {str(e)}")
            return {
                "file_path": image_path,
                "file_name": os.path.basename(image_path),
                "error": str(e)
            }

    def _extract_exif(self, img: Image.Image) -> Dict[str, Any]:
        """
        Extract EXIF metadata from a PIL Image object.
        
        Args:
            img: A PIL Image object
            
        Returns:
            Dictionary with normalized EXIF data
        """
        result = {}

        # Check if image has EXIF data
        if not hasattr(img, '_getexif') or img._getexif() is None:
            return result

        # Get raw EXIF data
        exif = {
            ExifTags.TAGS[k]: v
            for k, v in img._getexif().items()
            if k in ExifTags.TAGS
        }

        # Process date taken
        if "DateTimeOriginal" in exif:
            try:
                # EXIF date format: YYYY:MM:DD HH:MM:SS
                date_str = exif["DateTimeOriginal"]
                # Convert to ISO format
                date_obj = datetime.datetime.strptime(date_str, "%Y:%m:%d %H:%M:%S")
                result["date_taken"] = date_obj.isoformat()
            except Exception as e:
                logger.warning(f"Error parsing DateTimeOriginal: {str(e)}")

        # Camera information
        if "Make" in exif:
            result["camera_make"] = exif["Make"].strip()
        if "Model" in exif:
            result["camera_model"] = exif["Model"].strip()

        # Camera settings
        if "ISOSpeedRatings" in exif:
            result["iso"] = self._process_exif_value(exif["ISOSpeedRatings"])

        if "FNumber" in exif:
            f_num = self._process_rational(exif["FNumber"])
            if f_num is not None:
                result["aperture"] = f_num

        if "ExposureTime" in exif:
            exp_time = self._process_rational(exif["ExposureTime"])
            if exp_time is not None:
                result["exposure_time"] = exp_time

        if "FocalLength" in exif:
            focal_len = self._process_rational(exif["FocalLength"])
            if focal_len is not None:
                result["focal_length"] = focal_len

        # Extract GPS information if available
        if "GPSInfo" in exif:
            gps_info = self._extract_gps_info(exif["GPSInfo"])
            if gps_info:
                result.update(gps_info)

        return result

    def _process_exif_value(self, value: Any) -> Any:
        """Process EXIF value to a more usable format."""
        if isinstance(value, (tuple, list)) and len(value) == 1:
            return value[0]
        return value

    def _process_rational(self, rational: tuple) -> Optional[float]:
        """Process a rational EXIF value (numerator/denominator)."""
        try:
            if isinstance(rational, tuple) and len(rational) == 2:
                return rational[0] / rational[1]
            return None
        except (ZeroDivisionError, TypeError):
            return None

    def _extract_gps_info(self, gps_info: Dict) -> Dict[str, Any]:
        """Extract GPS information from EXIF data."""
        result = {}

        # Convert GPS EXIF tags to a readable format
        gps_data = {}
        for key in gps_info.keys():
            if key in GPSTAGS:
                gps_data[GPSTAGS[key]] = gps_info[key]

        # Extract latitude
        if "GPSLatitude" in gps_data and "GPSLatitudeRef" in gps_data:
            try:
                lat = self._convert_to_degrees(gps_data["GPSLatitude"])
                if gps_data["GPSLatitudeRef"] == "S":
                    lat = -lat
                result["latitude"] = lat
            except:
                pass

        # Extract longitude
        if "GPSLongitude" in gps_data and "GPSLongitudeRef" in gps_data:
            try:
                lon = self._convert_to_degrees(gps_data["GPSLongitude"])
                if gps_data["GPSLongitudeRef"] == "W":
                    lon = -lon
                result["longitude"] = lon
            except:
                pass

        # Extract altitude
        if "GPSAltitude" in gps_data and "GPSAltitudeRef" in gps_data:
            try:
                alt = self._process_rational(gps_data["GPSAltitude"])
                if alt is not None:
                    # If GPSAltitudeRef is 1, altitude is below sea level
                    if gps_data["GPSAltitudeRef"] == 1:
                        alt = -alt
                    result["altitude"] = alt
            except:
                pass

        return result

    def _convert_to_degrees(self, value: tuple) -> float:
        """
        Convert GPS coordinates stored in tuples to decimal degrees.
        
        Args:
            value: GPS coordinates in (degrees, minutes, seconds) format
        
        Returns:
            Decimal degrees
        """
        try:
            degrees = value[0][0] / value[0][1]
            minutes = value[1][0] / value[1][1] / 60.0
            seconds = value[2][0] / value[2][1] / 3600.0
            return degrees + minutes + seconds
        except (IndexError, ZeroDivisionError, TypeError):
            return 0.0
