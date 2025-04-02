#!/usr/bin/env python3
"""
Pixels - Modern Photo Manager
Main entry point for the application
"""

import logging
import sys
import os

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Ensure config directory exists
os.makedirs(os.path.join(os.path.dirname(__file__), "config"), exist_ok=True)

# Import core modules
from src.core.cli import execute_cli
from src.core.feature_flags import get_feature_flags


def main():
    """Main entry point for the application"""
    # Initialize feature flags
    feature_flags = get_feature_flags()
    
    # Set up CLI specific logging based on feature flags
    if feature_flags.is_enabled("verbose_logging"):
        logging.getLogger().setLevel(logging.DEBUG)
        logger.debug("Verbose logging enabled")
    
    # Execute CLI
    return execute_cli()


if __name__ == "__main__":
    sys.exit(main())
