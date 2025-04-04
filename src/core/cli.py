"""
Command Line Interface for Pixels Photo Manager
This module provides an enhanced CLI framework for testing and controlling the application.
"""

import argparse
import logging
import time
from typing import Dict, Any, List, Optional, Callable

from src.core.feature_flags import get_feature_flags

logger = logging.getLogger(__name__)


# Add the missing function that is imported in main.py
def process_cli_command(args):
    """
    Process CLI commands from the main application.
    This function is used by main.py to handle command-line arguments.
    
    Args:
        args: Command-line arguments parsed by argparse
    """
    try:
        # Handle the add-folder command
        if args.command == "add-folder":
            from src.core.library_indexer import LibraryIndexer

            # Initialize the library indexer with the database path
            indexer = LibraryIndexer(db_path=None)  # The database path is already set in main.py

            # Add the folder to the library
            print(f"Adding folder: {args.path}")
            monitor = args.monitor if hasattr(args, 'monitor') else False
            name = args.name if hasattr(args, 'name') else None

            result = indexer.add_folder(args.path, name=name, monitor=monitor)
            if result:
                print(f"Folder added successfully: {args.path}")
                return 0
            else:
                print(f"Failed to add folder: {args.path}")
                return 1

        # Handle the import command
        elif args.command == "import":
            from src.core.library_indexer import LibraryIndexer

            # Initialize the library indexer with the database path
            indexer = LibraryIndexer(db_path=None)  # The database path is already set in main.py

            # Import photos from the folder
            print(f"Importing photos from: {args.path}")
            folders, photos, elapsed = indexer.index_folder(args.path, recursive=True, monitor=False)
            print(f"Imported {photos} photos from {folders} folders in {elapsed:.2f} seconds")
            return 0

        # Handle the search command
        elif args.command == "search":
            from src.core.database import PhotoDatabase

            # Initialize the database
            db = PhotoDatabase(db_path=None)  # The database path is already set in main.py

            # Build the search parameters
            search_params = {}

            if hasattr(args, 'keyword') and args.keyword:
                search_params['keyword'] = args.keyword

            if hasattr(args, 'folder_id') and args.folder_id is not None:
                search_params['folder_ids'] = [args.folder_id]

                # Check if recursive search is disabled
                recursive = True
                if hasattr(args, 'no_recursive') and args.no_recursive:
                    recursive = False
                search_params['recursive_folders'] = recursive

            if hasattr(args, 'tag_id') and args.tag_id is not None:
                search_params['tag_ids'] = [args.tag_id]

            if hasattr(args, 'album_id') and args.album_id is not None:
                search_params['album_id'] = args.album_id

            if hasattr(args, 'min_rating') and args.min_rating is not None:
                search_params['min_rating'] = args.min_rating

            if hasattr(args, 'favorites') and args.favorites:
                search_params['is_favorite'] = True

            # Set the limit for results
            limit = args.limit if hasattr(args, 'limit') else 10
            search_params['limit'] = limit

            # Perform the search
            photos = db.search_photos(**search_params)

            # Display the results
            print(f"Found {len(photos)} photos:")
            for photo in photos:
                print(f"  {photo['id']}: {photo['file_name']} ({photo['file_path']})")

            return 0

        # Handle duplicates command
        elif args.command == "duplicates":
            from src.core.duplicate_detection_service import DuplicateDetectionService

            # Initialize the duplicate detection service
            service = DuplicateDetectionService()

            # Find duplicates
            if hasattr(args, 'folder_id') and args.folder_id is not None:
                print(f"Finding duplicates in folder {args.folder_id}...")
                duplicates = service.find_duplicates_in_folder(args.folder_id)
            else:
                print("Finding duplicates across the entire library...")
                duplicates = service.find_exact_duplicates()

            if not duplicates:
                print("No duplicate photos found.")
                return 0

            # Show statistics
            stats = service.get_duplicate_statistics()
            print(f"Found {stats['total_groups']} groups of duplicate photos:")
            print(f"  Total duplicates: {stats['total_duplicates']}")
            print(f"  Wasted space: {stats['wasted_space_mb']:.2f} MB")
            print(f"  Largest duplicate group: {stats['largest_group_size']} photos")

            # Display duplicates
            if hasattr(args, 'verbose') and args.verbose:
                for i, group in enumerate(duplicates):
                    print(f"\nDuplicate group {i + 1} (hash: {group['file_hash']}):")

                    # Get suggested photos to keep
                    suggestions = service.suggest_duplicates_to_keep(group)

                    for photo in group['photos']:
                        keep_indicator = " (suggested to keep)" if photo['id'] == suggestions[0] else ""
                        print(f"  Photo ID: {photo['id']}{keep_indicator}")
                        print(f"    Path: {photo['file_path']}")
                        print(f"    Size: {photo.get('file_size', 'unknown')} bytes")
                        print(f"    Dimensions: {photo.get('width', '?')}x{photo.get('height', '?')}")
                        print(f"    Date taken: {photo.get('date_taken', 'unknown')}")
            else:
                print(f"\nRun with --verbose to see detailed duplicate information.")

            # Handle deletion if requested
            if hasattr(args, 'auto_delete') and args.auto_delete:
                deleted_count = 0
                for group in duplicates:
                    # Get suggestions of which photos to keep
                    suggestions = service.suggest_duplicates_to_keep(group)
                    keep_id = suggestions[0]

                    # Delete all but the first suggested photo
                    for photo in group['photos']:
                        if photo['id'] != keep_id:
                            permanent = hasattr(args, 'permanent') and args.permanent
                            success = service.delete_duplicate(photo['id'], permanent=permanent)
                            if success:
                                deleted_count += 1

                delete_type = "Permanently deleted" if (
                            hasattr(args, 'permanent') and args.permanent) else "Moved to trash"
                print(f"{delete_type} {deleted_count} duplicate photos.")

            return 0

        else:
            print(f"Command '{args.command}' not implemented in process_cli_command")
            return 1

    except Exception as e:
        print(f"Error executing command '{args.command}': {e}")
        return 1


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

    # Duplicates command for finding and managing duplicate photos
    duplicates_parser = subparsers.add_parser("duplicates", help="Find and manage duplicate photos")
    duplicates_parser.add_argument("--folder-id", type=int, help="Find duplicates only in a specific folder")
    duplicates_parser.add_argument("--verbose", "-v", action="store_true",
                                   help="Show detailed information about duplicates")
    duplicates_parser.add_argument("--auto-delete", "-d", action="store_true",
                                   help="Automatically delete duplicate photos (keeps the best quality one)")
    duplicates_parser.add_argument("--permanent", "-p", action="store_true",
                                   help="Permanently delete files instead of moving to trash")

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


def register_duplicates_command():
    """Register the duplicates command"""

    def setup_parser(parser):
        parser.add_argument("--folder-id", type=int, help="Find duplicates only in a specific folder")
        parser.add_argument("--verbose", "-v", action="store_true", help="Show detailed information about duplicates")
        parser.add_argument("--auto-delete", "-d", action="store_true",
                            help="Automatically delete duplicate photos (keeps the best quality one)")
        parser.add_argument("--permanent", "-p", action="store_true",
                            help="Permanently delete files instead of moving to trash")

    def handler(args):
        from src.core.duplicate_detection_service import DuplicateDetectionService

        # Initialize the duplicate detection service
        service = DuplicateDetectionService()

        # Find duplicates
        if hasattr(args, 'folder_id') and args.folder_id is not None:
            print(f"Finding duplicates in folder {args.folder_id}...")
            duplicates = service.find_duplicates_in_folder(args.folder_id)
        else:
            print("Finding duplicates across the entire library...")
            duplicates = service.find_exact_duplicates()

        if not duplicates:
            print("No duplicate photos found.")
            return 0

        # Show statistics
        stats = service.get_duplicate_statistics()
        print(f"Found {stats['total_groups']} groups of duplicate photos:")
        print(f"  Total duplicates: {stats['total_duplicates']}")
        print(f"  Wasted space: {stats['wasted_space_mb']:.2f} MB")
        print(f"  Largest duplicate group: {stats['largest_group_size']} photos")

        # Display duplicates
        if hasattr(args, 'verbose') and args.verbose:
            for i, group in enumerate(duplicates):
                print(f"\nDuplicate group {i + 1} (hash: {group['file_hash']}):")

                # Get suggested photos to keep
                suggestions = service.suggest_duplicates_to_keep(group)

                for photo in group['photos']:
                    keep_indicator = " (suggested to keep)" if photo['id'] == suggestions[0] else ""
                    print(f"  Photo ID: {photo['id']}{keep_indicator}")
                    print(f"    Path: {photo['file_path']}")
                    print(f"    Size: {photo.get('file_size', 'unknown')} bytes")
                    print(f"    Dimensions: {photo.get('width', '?')}x{photo.get('height', '?')}")
                    print(f"    Date taken: {photo.get('date_taken', 'unknown')}")
        else:
            print(f"\nRun with --verbose to see detailed duplicate information.")

        # Handle deletion if requested
        if hasattr(args, 'auto_delete') and args.auto_delete:
            deleted_count = 0
            for group in duplicates:
                # Get suggestions of which photos to keep
                suggestions = service.suggest_duplicates_to_keep(group)
                keep_id = suggestions[0]

                # Delete all but the first suggested photo
                for photo in group['photos']:
                    if photo['id'] != keep_id:
                        permanent = hasattr(args, 'permanent') and args.permanent
                        success = service.delete_duplicate(photo['id'], permanent=permanent)
                        if success:
                            deleted_count += 1

            delete_type = "Permanently deleted" if (hasattr(args, 'permanent') and args.permanent) else "Moved to trash"
            print(f"{delete_type} {deleted_count} duplicate photos.")

        return 0

    command_registry.register_command(
        name="duplicates",
        handler=handler,
        parser_setup=setup_parser,
        help_text="Find and manage duplicate photos"
    )


# Register built-in commands
register_scan_command()
register_index_command()
register_extract_command()
register_refresh_command()
register_duplicates_command()
