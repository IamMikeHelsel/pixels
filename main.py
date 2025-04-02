#!/usr/bin/env python3
"""
Pixels - Modern Photo Manager
Main entry point for the application
"""

import logging
import sys
import os
import argparse

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
from src.core.api import start_server
from src.core.feature_flags import get_feature_flags


def main():
    """Main entry point for the application"""
    # Parse command line arguments
    parser = argparse.ArgumentParser(description="Pixels - Modern Photo Manager")
    subparsers = parser.add_subparsers(dest='command', help='Command to run')
    
    # CLI command
    cli_parser = subparsers.add_parser('cli', help='Run the command-line interface')
    
    # API server command
    server_parser = subparsers.add_parser('serve', help='Start the API server')
    server_parser.add_argument('--host', default='localhost', help='Host to bind to')
    server_parser.add_argument('--port', type=int, default=5000, help='Port to bind to')
    server_parser.add_argument('--debug', action='store_true', help='Run in debug mode')
    
    # Parse arguments
    args = parser.parse_args()
    
    # Initialize feature flags
    feature_flags = get_feature_flags()
    
    # Set up logging based on feature flags
    if feature_flags.is_enabled("verbose_logging"):
        logging.getLogger().setLevel(logging.DEBUG)
        logger.debug("Verbose logging enabled")
    
    # Execute the appropriate command
    if args.command == 'serve':
        logger.info(f"Starting API server on {args.host}:{args.port}")
        start_server(host=args.host, port=args.port, debug=args.debug)
        return 0
    else:
        # Default to CLI if no command specified or 'cli' command used
        return execute_cli()


if __name__ == "__main__":
    sys.exit(main())
