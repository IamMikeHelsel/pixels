#!/usr/bin/env python3
"""
Pixels - Modern Photo Manager

Main application entry point for the Pixels photo manager.
Provides CLI functionality and launches the FastAPI server.
"""

import os
import sys
import argparse
import uvicorn
from pathlib import Path

from src.core.database import PhotoDatabase
from src.core.cli import process_cli_command

# Define the application version
__version__ = "1.0.0"

def main():
    """Main entry point for the Pixels application."""
    # Create an argument parser
    parser = argparse.ArgumentParser(description="Pixels - Modern Photo Manager")
    subparsers = parser.add_subparsers(dest="command", help="Command to execute")
    
    # Serve command - Start the FastAPI server
    serve_parser = subparsers.add_parser("serve", help="Start the API server")
    serve_parser.add_argument("--host", default="localhost", help="Host to bind the server to")
    serve_parser.add_argument("--port", type=int, default=5000, help="Port to bind the server to")
    serve_parser.add_argument("--reload", action="store_true", help="Enable auto-reload for development")
    
    # Add folder command - Add a folder to the library
    add_folder_parser = subparsers.add_parser("add-folder", help="Add a folder to the photo library")
    add_folder_parser.add_argument("path", help="Path to the folder to add")
    add_folder_parser.add_argument("--name", help="Custom name for the folder")
    add_folder_parser.add_argument("--monitor", action="store_true", help="Monitor the folder for changes")
    
    # Import command - Import photos from a folder without adding it to monitored folders
    import_parser = subparsers.add_parser("import", help="Import photos from a folder")
    import_parser.add_argument("path", help="Path to the folder to import from")
    
    # Search command - Search for photos
    search_parser = subparsers.add_parser("search", help="Search for photos")
    search_parser.add_argument("--keyword", help="Keyword to search for")
    search_parser.add_argument("--folder-id", type=int, help="Folder ID to search in")
    search_parser.add_argument("--tag-id", type=int, help="Tag ID to search for")
    search_parser.add_argument("--album-id", type=int, help="Album ID to search for")
    search_parser.add_argument("--min-rating", type=int, choices=range(1, 6), help="Minimum rating")
    search_parser.add_argument("--favorites", action="store_true", help="Only show favorites")
    search_parser.add_argument("--limit", type=int, default=10, help="Maximum number of results to show")
    
    # Version command - Show version information
    version_parser = subparsers.add_parser("version", help="Show version information")
    
    # Parse the arguments
    args = parser.parse_args()
    
    # If no command was specified, show help and exit
    if not args.command:
        parser.print_help()
        return
    
    # Initialize the database
    db_path = os.environ.get("PIXELS_DB_PATH")
    if not db_path:
        # Set a default database location in user's home directory
        home_dir = os.path.expanduser("~")
        pixels_dir = os.path.join(home_dir, ".pixels")
        os.makedirs(pixels_dir, exist_ok=True)
        db_path = os.path.join(pixels_dir, "pixels.db")
    
    # Ensure the database directory exists
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    
    # Handle version command
    if args.command == "version":
        print(f"Pixels Photo Manager version {__version__}")
        print(f"Database location: {db_path}")
        return
    
    # Handle serve command
    if args.command == "serve":
        # Initialize the database
        # This ensures tables are created before the API is started
        PhotoDatabase(db_path=db_path)
        
        print(f"Starting Pixels API server at http://{args.host}:{args.port}")
        print(f"API documentation will be available at http://{args.host}:{args.port}/docs")
        # Starting the uvicorn server
        uvicorn.run(
            "src.core.api:app", 
            host=args.host, 
            port=args.port, 
            reload=args.reload,
            log_level="info"
        )
        return
    
    # For all other commands, use the CLI processor
    process_cli_command(args)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nExiting Pixels...")
        sys.exit(0)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
