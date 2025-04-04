"""
Feature Flag System for Pixels Photo Manager
This module manages feature flags to enable or disable features during development and testing.
"""

import json
import logging
import os
from typing import Dict, Any, Optional

logger = logging.getLogger(__name__)

# Default path for feature flags configuration file
DEFAULT_CONFIG_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))),
                                   "config", "feature_flags.json")

# Default feature flags configuration
DEFAULT_FEATURE_FLAGS = {
    # Core functionality
    "enhanced_metadata_extraction": False,  # Use advanced metadata extraction (more CPU intensive)
    "raw_support": False,  # Support for RAW image formats
    "video_support": False,  # Support for video files
    "monitor_directories": False,  # Enable real-time directory monitoring

    # UI features
    "dark_mode": True,  # Enable dark mode UI
    "experimental_ui": False,  # Enable experimental UI features

    # Performance features
    "parallel_processing": True,  # Use parallel processing for heavy operations
    "optimized_thumbnail_generation": True,  # Use optimized thumbnail generation algorithms

    # Advanced features
    "face_detection": False,  # Enable face detection
    "visual_similarity_detection": False,  # Enable detection of visually similar images
    "geolocation_features": False,  # Enable geolocation features

    # Testing and debugging
    "verbose_logging": False,  # Enable verbose logging
    "mock_filesystem": False,  # Use mock filesystem for testing
    "test_mode": False,  # Enable various test-specific behaviors
}


class FeatureFlags:
    """
    Feature flag management system that controls which features are enabled or disabled.
    
    Attributes:
        _flags (Dict[str, Any]): Dictionary of feature flags
        _config_path (str): Path to the feature flags configuration file
    """
    _instance = None

    def __new__(cls, config_path: Optional[str] = None):
        if cls._instance is None:
            cls._instance = super(FeatureFlags, cls).__new__(cls)
            cls._instance._initialize(config_path)
        return cls._instance

    def _initialize(self, config_path: Optional[str] = None):
        """Initialize the feature flags with default values and load from config if available."""
        self._config_path = config_path or DEFAULT_CONFIG_PATH
        self._flags = DEFAULT_FEATURE_FLAGS.copy()
        self._load()

    def _load(self) -> None:
        """Load feature flags from configuration file."""
        try:
            # Ensure directory exists
            os.makedirs(os.path.dirname(self._config_path), exist_ok=True)

            # Load configuration if exists
            if os.path.exists(self._config_path):
                with open(self._config_path, 'r') as f:
                    loaded_flags = json.load(f)
                    # Update only existing flags
                    for key in self._flags.keys():
                        if key in loaded_flags:
                            self._flags[key] = loaded_flags[key]
                logger.info(f"Feature flags loaded from {self._config_path}")
            else:
                # Create default configuration file if it doesn't exist
                self._save()
                logger.info(f"Created default feature flags at {self._config_path}")
        except Exception as e:
            logger.error(f"Error loading feature flags: {e}")

    def _save(self) -> None:
        """Save feature flags to configuration file."""
        try:
            # Ensure directory exists
            os.makedirs(os.path.dirname(self._config_path), exist_ok=True)

            with open(self._config_path, 'w') as f:
                json.dump(self._flags, f, indent=4)
            logger.info(f"Feature flags saved to {self._config_path}")
        except Exception as e:
            logger.error(f"Error saving feature flags: {e}")

    def is_enabled(self, flag_name: str) -> bool:
        """
        Check if a feature flag is enabled.
        
        Args:
            flag_name: The name of the flag to check
            
        Returns:
            bool: True if the flag is enabled, False otherwise
        """
        if flag_name not in self._flags:
            logger.warning(f"Unknown feature flag: {flag_name}, returning False")
            return False
        return bool(self._flags[flag_name])

    def enable(self, flag_name: str) -> None:
        """
        Enable a feature flag.
        
        Args:
            flag_name: The name of the flag to enable
        """
        if flag_name in self._flags:
            self._flags[flag_name] = True
            self._save()
        else:
            logger.warning(f"Attempted to enable unknown feature flag: {flag_name}")

    def disable(self, flag_name: str) -> None:
        """
        Disable a feature flag.
        
        Args:
            flag_name: The name of the flag to disable
        """
        if flag_name in self._flags:
            self._flags[flag_name] = False
            self._save()
        else:
            logger.warning(f"Attempted to disable unknown feature flag: {flag_name}")

    def get_all_flags(self) -> Dict[str, Any]:
        """
        Get all feature flags.
        
        Returns:
            Dict[str, Any]: Dictionary of all feature flags
        """
        return self._flags.copy()

    def set_flags(self, flags: Dict[str, Any]) -> None:
        """
        Set multiple feature flags at once.
        
        Args:
            flags: Dictionary of flag name to value mappings
        """
        for flag_name, value in flags.items():
            if flag_name in self._flags:
                self._flags[flag_name] = bool(value)
            else:
                logger.warning(f"Attempted to set unknown feature flag: {flag_name}")
        self._save()


# Convenience function to get the feature flags instance
def get_feature_flags(config_path: Optional[str] = None):
    """
    Get the feature flags instance.
    
    Args:
        config_path: Optional path to the feature flags configuration file
        
    Returns:
        FeatureFlags: The feature flags instance
    """
    return FeatureFlags(config_path)
