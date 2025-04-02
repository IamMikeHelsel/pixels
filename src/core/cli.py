"""
Command Line Interface for Pixels Photo Manager
This module provides an enhanced CLI framework for testing and controlling the application.
"""

import argparse
import logging
import time
import sys
from typing import Dict, Any, List, Optional, Callable

from src.core.feature_flags import get_feature_flags

logger = logging.getLogger(__name__)


class CliCommandRegistry:
    """Registry for CLI commands to allow extending the command set easily"""
    
    def __init__(self):
        self._commands = {}
        
    def register_command(self, name: str, handler: Callable, parser_setup: Callable, help_text: str):
        """
        Register a new CLI command
        
        Args:
            name: Command name
            handler: Function that handles the command
            parser_setup: Function to set up command-specific arguments
            help_text: Brief help text for the command
        """
        self._commands[name] = {
            'handler': handler,
            'parser_setup': parser_setup,
            'help': help_text
        }
        
    def get_command(self, name: str) -> Dict[str, Any]:
        """Get command details by name"""
        return self._commands.get(name)
    
    def get_all_commands(self) -> Dict[str, Dict[str, Any]]:
        """Get all registered commands"""
        return self._commands


# Global command registry
command_registry = CliCommandRegistry()


def setup_parser() -> argparse.ArgumentParser:
    """
    Set up the command-line argument parser with all registered commands
    
    Returns:
        argparse.ArgumentParser: Configured argument parser
    """
    parser = argparse.ArgumentParser(description="Pixels - Modern Photo Manager")
    subparsers = parser.add_subparsers(dest="command", help="Commands")
    
    # Add registered commands to parser
    for cmd_name, cmd_info in command_registry.get_all_commands().items():
        cmd_parser = subparsers.add_parser(cmd_name, help=cmd_info['help'])
        cmd_info['parser_setup'](cmd_parser)
    
    # Feature flag specific commands
    feature_parser = subparsers.add_parser("feature", help="Manage feature flags")
    feature_subparsers = feature_parser.add_subparsers(dest="feature_command", help="Feature flag commands")
    
    # List features command
    list_parser = feature_subparsers.add_parser("list", help="List all feature flags")
    
    # Enable feature command
    enable_parser = feature_subparsers.add_parser("enable", help="Enable a feature flag")
    enable_parser.add_argument("flag_name", help="Name of the flag to enable")
    
    # Disable feature command
    disable_parser = feature_subparsers.add_parser("disable", help="Disable a feature flag")
    disable_parser.add_argument("flag_name", help="Name of the flag to disable")
    
    # Test command for quick tests
    test_parser = subparsers.add_parser("test", help="Run tests on application components")
    test_subparsers = test_parser.add_subparsers(dest="test_command", help="Test commands")
    
    # Connection test
    conn_test_parser = test_subparsers.add_parser("connection", help="Test database connection")
    
    # Scanner test
    scanner_test_parser = test_subparsers.add_parser("scanner", help="Test scanner functionality")
    scanner_test_parser.add_argument("path", help="Path to test scanning")
    
    # Thumbnail test
    thumb_test_parser = test_subparsers.add_parser("thumbnails", help="Test thumbnail generation")
    thumb_test_parser.add_argument("path", help="Path to test thumbnail generation")
    thumb_test_parser.add_argument("--count", type=int, default=5, help="Number of images to process")
    
    return parser


def execute_cli(args: Optional[List[str]] = None) -> int:
    """
    Parse arguments and execute the appropriate command
    
    Args:
        args: Command line arguments (if None, sys.argv[1:] will be used)
        
    Returns:
        int: Exit code (0 for success, non-zero for errors)
    """
    parser = setup_parser()
    parsed_args = parser.parse_args(args)
    
    if not parsed_args.command:
        parser.print_help()
        return 1
    
    # Handle feature flag commands
    if parsed_args.command == "feature":
        return handle_feature_commands(parsed_args)
    
    # Handle test commands
    if parsed_args.command == "test":
        return handle_test_commands(parsed_args)
    
    # Handle registered commands
    cmd_info = command_registry.get_command(parsed_args.command)
    if cmd_info:
        try:
            return cmd_info['handler'](parsed_args)
        except Exception as e:
            logger.error(f"Error executing command '{parsed_args.command}': {e}")
            return 1
    
    parser.print_help()
    return 1


def handle_feature_commands(args):
    """Handle feature flag related commands"""
    feature_flags = get_feature_flags()
    
    if args.feature_command == "list":
        print("Feature flags:")
        for flag, value in feature_flags.get_all_flags().items():
            status = "enabled" if value else "disabled"
            print(f"  {flag}: {status}")
        return 0
    
    elif args.feature_command == "enable":
        try:
            feature_flags.enable(args.flag_name)
            print(f"Feature '{args.flag_name}' enabled")
            return 0
        except Exception as e:
            print(f"Error enabling feature: {e}")
            return 1
    
    elif args.feature_command == "disable":
        try:
            feature_flags.disable(args.flag_name)
            print(f"Feature '{args.flag_name}' disabled")
            return 0
        except Exception as e:
            print(f"Error disabling feature: {e}")
            return 1
    
    else:
        print("Unknown feature command")
        return 1


def handle_test_commands(args):
    """Handle test related commands"""
    if args.test_command == "connection":
        return test_database_connection()
    
    elif args.test_command == "scanner":
        return test_scanner_functionality(args.path)
    
    elif args.test_command == "thumbnails":
        return test_thumbnail_generation(args.path, args.count)
    
    else:
        print("Unknown test command")
        return 1


def test_database_connection():
    """Test database connection"""
    try:
        from src.core.database import Database
        print("Testing database connection...")
        start_time = time.time()
        db = Database()
        conn = db.get_connection()
        if conn:
            print(f"Database connection successful ({time.time() - start_time:.2f}s)")
            return 0
        else:
            print("Database connection failed")
            return 1
    except Exception as e:
        print(f"Error testing database connection: {e}")
        return 1


def test_scanner_functionality(path):
    """Test scanner functionality"""
    try:
        from src.core.scanner import FileSystemScanner, get_scan_summary
        print(f"Testing scanner on path: {path}")
        start_time = time.time()
        scanner = FileSystemScanner()
        result = scanner.scan_directory(path, recursive=True)
        elapsed = time.time() - start_time
        
        summary = get_scan_summary(result)
        print(f"Scan completed in {elapsed:.2f}s")
        print(summary)
        return 0
    except Exception as e:
        print(f"Error testing scanner: {e}")
        return 1


def test_thumbnail_generation(path, count):
    """Test thumbnail generation"""
    try:
        import os
        from src.core.scanner import FileSystemScanner
        from src.core.thumbnail_service import ThumbnailService
        
        print(f"Testing thumbnail generation on up to {count} images in {path}")
        
        # First scan to find images
        scanner = FileSystemScanner()
        result = scanner.scan_directory(path, recursive=True)
        
        # Filter image files
        image_files = []
        for file_info in result.get('files', []):
            if file_info.get('is_image', False):
                image_files.append(file_info['path'])
                if len(image_files) >= count:
                    break
        
        if not image_files:
            print("No image files found in the specified path")
            return 1
        
        # Generate thumbnails
        thumb_service = ThumbnailService()
        start_time = time.time()
        
        for idx, image_path in enumerate(image_files, 1):
            print(f"Generating thumbnail {idx}/{len(image_files)}: {os.path.basename(image_path)}")
            thumb_path = thumb_service.generate_thumbnail(image_path)
            if thumb_path:
                print(f"  ✓ Thumbnail saved to: {thumb_path}")
            else:
                print(f"  ✗ Failed to generate thumbnail")
        
        elapsed = time.time() - start_time
        print(f"Generated {len(image_files)} thumbnails in {elapsed:.2f}s")
        return 0
    except Exception as e:
        print(f"Error testing thumbnail generation: {e}")
        return 1


def register_scan_command():
    """Register the scan command"""
    def setup_parser(parser):
        parser.add_argument("path", help="Directory path to scan")
        parser.add_argument("--recursive", "-r", action="store_true", help="Scan subdirectories recursively")
    
    def handler(args):
        from src.core.scanner import FileSystemScanner, get_scan_summary
        scanner = FileSystemScanner()
        result = scanner.scan_directory(args.path, args.recursive)
        print(get_scan_summary(result))
        return 0
    
    command_registry.register_command(
        name="scan",
        handler=handler,
        parser_setup=setup_parser,
        help_text="Scan a directory for images"
    )


def register_index_command():
    """Register the index command"""
    def setup_parser(parser):
        parser.add_argument("path", help="Directory path to index")
        parser.add_argument("--recursive", "-r", action="store_true", help="Index subdirectories recursively")
        parser.add_argument("--monitor", "-m", action="store_true", help="Monitor directory for changes")
        parser.add_argument("--db", help="Path to database file")
    
    def handler(args):
        from src.core.library_indexer import LibraryIndexer
        indexer = LibraryIndexer(args.db)
        folders, photos, elapsed = indexer.index_folder(args.path, args.recursive, args.monitor)
        print(f"Indexed {photos} photos in {folders} folders in {elapsed:.2f} seconds")
        return 0
    
    command_registry.register_command(
        name="index",
        handler=handler,
        parser_setup=setup_parser,
        help_text="Index a directory into the library"
    )


def register_extract_command():
    """Register the extract command"""
    def setup_parser(parser):
        parser.add_argument("path", help="Path to the image file")
        parser.add_argument("--json", "-j", action="store_true", help="Output in JSON format")
    
    def handler(args):
        import json
        from src.core.metadata_extractor import MetadataExtractor
        extractor = MetadataExtractor()
        metadata = extractor.extract_metadata(args.path)
        
        if args.json:
            print(json.dumps(metadata, indent=2))
        else:
            print("Metadata:")
            for key, value in metadata.items():
                print(f"  {key}: {value}")
        return 0
    
    command_registry.register_command(
        name="extract",
        handler=handler,
        parser_setup=setup_parser,
        help_text="Extract metadata from an image"
    )


def register_refresh_command():
    """Register the refresh command"""
    def setup_parser(parser):
        parser.add_argument("--db", help="Path to database file")
    
    def handler(args):
        from src.core.library_indexer import LibraryIndexer
        indexer = LibraryIndexer(args.db)
        folders, photos, elapsed = indexer.refresh_index()
        print(f"Updated {folders} folders and added {photos} new photos in {elapsed:.2f} seconds")
        return 0
    
    command_registry.register_command(
        name="refresh",
        handler=handler,
        parser_setup=setup_parser,
        help_text="Refresh the library index"
    )


# Register built-in commands
register_scan_command()
register_index_command()
register_extract_command()
register_refresh_command()