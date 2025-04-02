#!/usr/bin/env python3
"""
Pixels - Modern Photo Manager
Main entry point for the application
"""

import argparse
import logging
import sys

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Import core modules
from src.core.scanner import FileSystemScanner, get_scan_summary
from src.core.metadata_extractor import MetadataExtractor
from src.core.library_indexer import LibraryIndexer


def main():
    """Main entry point for the application"""
    parser = argparse.ArgumentParser(description="Pixels - Modern Photo Manager")

    # Add subparsers for different commands
    subparsers = parser.add_subparsers(dest="command", help="Commands")

    # Scan command
    scan_parser = subparsers.add_parser("scan", help="Scan a directory for images")
    scan_parser.add_argument("path", help="Directory path to scan")
    scan_parser.add_argument("--recursive", "-r", action="store_true", help="Scan subdirectories recursively")

    # Index command
    index_parser = subparsers.add_parser("index", help="Index a directory into the library")
    index_parser.add_argument("path", help="Directory path to index")
    index_parser.add_argument("--recursive", "-r", action="store_true", help="Index subdirectories recursively")
    index_parser.add_argument("--monitor", "-m", action="store_true", help="Monitor directory for changes")
    index_parser.add_argument("--db", help="Path to database file")

    # Refresh command
    refresh_parser = subparsers.add_parser("refresh", help="Refresh the library index")
    refresh_parser.add_argument("--db", help="Path to database file")

    # Extract command
    extract_parser = subparsers.add_parser("extract", help="Extract metadata from an image")
    extract_parser.add_argument("path", help="Path to the image file")

    args = parser.parse_args()

    # Handle the commands
    if args.command == "scan":
        handle_scan(args.path, args.recursive)
    elif args.command == "index":
        handle_index(args.path, args.recursive, args.monitor, args.db)
    elif args.command == "refresh":
        handle_refresh(args.db)
    elif args.command == "extract":
        handle_extract(args.path)
    else:
        parser.print_help()
        return 1

    return 0


def handle_scan(path, recursive):
    """Handle the scan command"""
    logger.info(f"Scanning directory: {path}")
    scanner = FileSystemScanner()
    result = scanner.scan_directory(path, recursive)
    print(get_scan_summary(result))


def handle_index(path, recursive, monitor, db_path):
    """Handle the index command"""
    logger.info(f"Indexing directory: {path}")
    indexer = LibraryIndexer(db_path)
    folders, photos, elapsed = indexer.index_folder(path, recursive, monitor)
    print(f"Indexed {photos} photos in {folders} folders in {elapsed:.2f} seconds")


def handle_refresh(db_path):
    """Handle the refresh command"""
    logger.info("Refreshing library index")
    indexer = LibraryIndexer(db_path)
    folders, photos, elapsed = indexer.refresh_index()
    print(f"Updated {folders} folders and added {photos} new photos in {elapsed:.2f} seconds")


def handle_extract(path):
    """Handle the extract command"""
    logger.info(f"Extracting metadata from: {path}")
    extractor = MetadataExtractor()
    metadata = extractor.extract_metadata(path)

    print("Metadata:")
    for key, value in metadata.items():
        print(f"  {key}: {value}")


if __name__ == "__main__":
    sys.exit(main())
