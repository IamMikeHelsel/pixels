"""
FastAPI REST API for the Pixels photo manager application.

This module provides a RESTful API interface for the core functionality
of the Pixels photo manager, enabling communication with the Flutter frontend.
"""

import os
import datetime
import shutil
from typing import List, Dict, Optional, Any
from pathlib import Path

from fastapi import FastAPI, HTTPException, Query, Path as PathParam, Depends
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

from . import database
from . import album_manager
from . import tag_manager
from . import library_indexer
from . import thumbnail_service
from . import duplicate_detection_service

# Create the FastAPI application
app = FastAPI(
    title="Pixels API",
    description="REST API for the Pixels Photo Manager",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# Add CORS middleware to allow communication with the Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

# Initialize database and services - reuse database instance from main.py if available
try:
    # Try to use an existing database instance if one is already initialized
    from .. import _shared_db_instance
    db = _shared_db_instance
    if db is None:
        db = database.PhotoDatabase()
except (ImportError, AttributeError):
    # If no shared instance exists, create a new one
    db = database.PhotoDatabase()

thumbnail_service = thumbnail_service.ThumbnailService()
library_indexer = library_indexer.LibraryIndexer(db, thumbnail_service)
tag_manager = tag_manager.TagManager(db_path=db.db_path)
album_manager = album_manager.AlbumManager(db_path=db.db_path)
duplicate_detector = duplicate_detection_service.DuplicateDetectionService(db_path=db.db_path)

# Define Pydantic models for request/response validation

class HealthResponse(BaseModel):
    status: str = "ok"
    version: str = "1.0.0"
    timestamp: datetime.datetime = Field(default_factory=datetime.datetime.now)

class FolderBase(BaseModel):
    path: str
    name: Optional[str] = None
    parent_id: Optional[int] = None
    is_monitored: bool = False

class FolderCreate(FolderBase):
    pass

class FolderResponse(FolderBase):
    id: int
    photo_count: Optional[int] = 0
    children: Optional[List['FolderResponse']] = None

class PhotoResponse(BaseModel):
    id: int
    file_name: str
    file_path: str
    folder_id: int
    file_size: Optional[int] = None
    width: Optional[int] = None
    height: Optional[int] = None
    date_taken: Optional[datetime.datetime] = None
    camera_make: Optional[str] = None
    camera_model: Optional[str] = None
    rating: Optional[int] = 0
    is_favorite: bool = False
    thumbnail_path: Optional[str] = None
    tags: Optional[List['TagResponse']] = None
    albums: Optional[List['AlbumResponse']] = None

class PhotoUpdate(BaseModel):
    rating: Optional[int] = None
    is_favorite: Optional[bool] = None

class AlbumBase(BaseModel):
    name: str
    description: Optional[str] = ""

class AlbumCreate(AlbumBase):
    pass

class AlbumResponse(AlbumBase):
    id: int
    date_created: datetime.datetime
    date_modified: datetime.datetime
    photo_count: Optional[int] = 0

class PhotoAlbumRelation(BaseModel):
    order_index: Optional[int] = None

class TagBase(BaseModel):
    name: str
    parent_id: Optional[int] = None

class TagCreate(TagBase):
    pass

class TagResponse(TagBase):
    id: int
    photo_count: Optional[int] = 0
    children: Optional[List['TagResponse']] = None

class DuplicateGroupResponse(BaseModel):
    file_hash: str
    photos: List[PhotoResponse]

class DuplicateStatistics(BaseModel):
    total_groups: int
    total_duplicates: int
    wasted_space_bytes: int
    wasted_space_mb: float
    largest_group_size: int

class DuplicateActionRequest(BaseModel):
    photo_ids: List[int]
    action: str = "trash"  # Options: "trash", "delete", "keep"

class SearchParams(BaseModel):
    keyword: Optional[str] = None
    folder_ids: Optional[List[int]] = None
    date_from: Optional[datetime.datetime] = None
    date_to: Optional[datetime.datetime] = None
    min_rating: Optional[int] = None
    is_favorite: Optional[bool] = None
    tag_ids: Optional[List[int]] = None
    album_id: Optional[int] = None
    limit: int = 100
    offset: int = 0
    sort_by: str = "date_taken"
    sort_desc: bool = True

# Helper functions for serialization
def serialize_datetime(obj):
    """JSON serializer for datetime objects."""
    if isinstance(obj, datetime.datetime):
        return obj.isoformat()
    raise TypeError(f"Type {type(obj)} not serializable")

# Health check endpoint
@app.get("/api/health", response_model=HealthResponse, tags=["health"])
def health_check():
    """Check if the API is running."""
    return {"status": "ok", "version": "1.0.0", "timestamp": datetime.datetime.now()}

# Shutdown endpoint (useful for the Flutter app to close the server)
@app.post("/api/shutdown", tags=["health"])
def shutdown():
    """Shutdown the API server."""
    import sys
    sys.exit(0)

# Folder endpoints
@app.get("/api/folders", response_model=List[FolderResponse], tags=["folders"])
def get_folders(hierarchy: bool = False):
    """
    Get all folders or folder hierarchy.
    
    Args:
        hierarchy: If True, return folders in a hierarchical structure
    """
    if hierarchy:
        folders = db.get_folder_hierarchy()
    else:
        folders = db.get_all_folders()
    return folders

@app.get("/api/folders/{folder_id}", response_model=FolderResponse, tags=["folders"])
def get_folder(folder_id: int = PathParam(..., description="ID of the folder to retrieve")):
    """
    Get a specific folder by ID.
    
    Args:
        folder_id: ID of the folder to retrieve
    """
    folder = db.get_folder(folder_id)
    if not folder:
        raise HTTPException(status_code=404, detail="Folder not found")
    return folder

@app.post("/api/folders", response_model=FolderResponse, status_code=201, tags=["folders"])
def create_folder(folder: FolderCreate):
    """
    Create a new folder and index its contents.
    
    Args:
        folder: Folder details
    """
    # First check if folder exists in file system
    if not os.path.exists(folder.path):
        raise HTTPException(status_code=400, detail="Folder path does not exist")
    
    # Add folder to database
    folder_id = db.add_folder(
        path=folder.path,
        name=folder.name if folder.name else os.path.basename(folder.path),
        parent_id=folder.parent_id,
        is_monitored=folder.is_monitored
    )
    
    # Index the folder if it was successfully added
    if folder_id and folder.is_monitored:
        library_indexer.index_folder(folder_id)
    
    # Return the created folder
    created_folder = db.get_folder(folder_id)
    if not created_folder:
        raise HTTPException(status_code=500, detail="Failed to create folder")
    return created_folder

@app.delete("/api/folders/{folder_id}", tags=["folders"])
def delete_folder(folder_id: int = PathParam(..., description="ID of the folder to delete")):
    """
    Delete a folder from the database (does not delete from filesystem).
    
    Args:
        folder_id: ID of the folder to delete
    """
    # First check if folder exists
    folder = db.get_folder(folder_id)
    if not folder:
        raise HTTPException(status_code=404, detail="Folder not found")
    
    # Delete the folder from the database
    if db.delete_folder(folder_id):
        return {"message": f"Folder {folder_id} deleted successfully"}
    else:
        raise HTTPException(status_code=500, detail="Failed to delete folder")

# Photo endpoints
@app.get("/api/photos/folder/{folder_id}", response_model=List[PhotoResponse], tags=["photos"])
def get_photos_in_folder(
    folder_id: int = PathParam(..., description="ID of the folder to get photos from"),
    limit: int = Query(100, description="Maximum number of photos to return"),
    offset: int = Query(0, description="Number of photos to skip")
):
    """
    Get all photos in a specific folder.
    
    Args:
        folder_id: ID of the folder
        limit: Maximum number of photos to return
        offset: Number of photos to skip
    """
    photos = db.search_photos(folder_ids=[folder_id], limit=limit, offset=offset)
    return photos

@app.get("/api/photos/{photo_id}", response_model=PhotoResponse, tags=["photos"])
def get_photo(photo_id: int = PathParam(..., description="ID of the photo to retrieve")):
    """
    Get a specific photo by ID.
    
    Args:
        photo_id: ID of the photo to retrieve
    """
    photo = db.get_photo(photo_id)
    if not photo:
        raise HTTPException(status_code=404, detail="Photo not found")
    
    # Add tags and albums to the response
    photo["tags"] = db.get_tags_for_photo(photo_id)
    photo["albums"] = db.get_albums_for_photo(photo_id)
    
    return photo

@app.patch("/api/photos/{photo_id}", response_model=PhotoResponse, tags=["photos"])
def update_photo(
    photo_update: PhotoUpdate,
    photo_id: int = PathParam(..., description="ID of the photo to update")
):
    """
    Update photo properties (rating, favorite status).
    
    Args:
        photo_id: ID of the photo to update
        photo_update: Updated photo properties
    """
    # First check if photo exists
    photo = db.get_photo(photo_id)
    if not photo:
        raise HTTPException(status_code=404, detail="Photo not found")
    
    # Build update dict
    updates = {}
    if photo_update.rating is not None:
        updates["rating"] = photo_update.rating
    if photo_update.is_favorite is not None:
        updates["is_favorite"] = 1 if photo_update.is_favorite else 0
    
    # Update the photo
    if updates and db.update_photo(photo_id, **updates):
        updated_photo = db.get_photo(photo_id)
        updated_photo["tags"] = db.get_tags_for_photo(photo_id)
        updated_photo["albums"] = db.get_albums_for_photo(photo_id)
        return updated_photo
    else:
        raise HTTPException(status_code=500, detail="Failed to update photo")

@app.get("/api/photos/search", response_model=List[PhotoResponse], tags=["photos"])
def search_photos(
    keyword: Optional[str] = Query(None, description="Search text"),
    folder_ids: Optional[str] = Query(None, description="Comma-separated folder IDs"),
    date_from: Optional[str] = Query(None, description="Start date (ISO format)"),
    date_to: Optional[str] = Query(None, description="End date (ISO format)"),
    min_rating: Optional[int] = Query(None, description="Minimum rating (1-5)"),
    is_favorite: Optional[bool] = Query(None, description="Filter by favorite status"),
    tag_ids: Optional[str] = Query(None, description="Comma-separated tag IDs"),
    album_id: Optional[int] = Query(None, description="Filter by album ID"),
    limit: int = Query(100, description="Maximum number of results"),
    offset: int = Query(0, description="Offset for pagination"),
    sort_by: str = Query("date_taken", description="Field to sort by"),
    sort_desc: bool = Query(True, description="Sort in descending order")
):
    """
    Search photos with various filters.
    
    Args:
        keyword: Search text matching filename, camera make/model
        folder_ids: Comma-separated folder IDs to include
        date_from: Start date in ISO format
        date_to: End date in ISO format
        min_rating: Minimum rating (1-5)
        is_favorite: Filter by favorite status
        tag_ids: Comma-separated tag IDs
        album_id: Filter by album ID
        limit: Maximum number of results
        offset: Offset for pagination
        sort_by: Field to sort results by
        sort_desc: Whether to sort in descending order
    """
    # Parse comma-separated values into lists
    folder_id_list = None
    if folder_ids:
        try:
            folder_id_list = [int(fid) for fid in folder_ids.split(',')]
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid folder IDs format")
    
    tag_id_list = None
    if tag_ids:
        try:
            tag_id_list = [int(tid) for tid in tag_ids.split(',')]
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid tag IDs format")
    
    # Search photos with all provided parameters
    photos = db.search_photos(
        keyword=keyword,
        folder_ids=folder_id_list,
        date_from=date_from,
        date_to=date_to,
        min_rating=min_rating,
        is_favorite=is_favorite,
        tag_ids=tag_id_list,
        album_id=album_id,
        limit=limit,
        offset=offset,
        sort_by=sort_by,
        sort_desc=sort_desc
    )
    
    return photos

# Album endpoints
@app.get("/api/albums", response_model=List[AlbumResponse], tags=["albums"])
def get_all_albums():
    """Get all albums."""
    return album_manager.get_all_albums()

@app.get("/api/albums/{album_id}", response_model=AlbumResponse, tags=["albums"])
def get_album(album_id: int = PathParam(..., description="ID of the album to retrieve")):
    """
    Get a specific album by ID.
    
    Args:
        album_id: ID of the album to retrieve
    """
    album = album_manager.get_album(album_id)
    if not album:
        raise HTTPException(status_code=404, detail="Album not found")
    return album

@app.post("/api/albums", response_model=AlbumResponse, status_code=201, tags=["albums"])
def create_album(album: AlbumCreate):
    """
    Create a new album.
    
    Args:
        album: Album details
    """
    created_album = album_manager.create_album(album.name, album.description)
    if not created_album:
        raise HTTPException(status_code=500, detail="Failed to create album")
    return created_album

@app.put("/api/albums/{album_id}", response_model=AlbumResponse, tags=["albums"])
def update_album(
    album_update: AlbumBase,
    album_id: int = PathParam(..., description="ID of the album to update")
):
    """
    Update an album's name and description.
    
    Args:
        album_id: ID of the album to update
        album_update: Updated album properties
    """
    # First check if album exists
    album = album_manager.get_album(album_id)
    if not album:
        raise HTTPException(status_code=404, detail="Album not found")
    
    # Update the album
    if album_manager.update_album(album_id, album_update.name, album_update.description):
        updated_album = album_manager.get_album(album_id)
        return updated_album
    else:
        raise HTTPException(status_code=500, detail="Failed to update album")

@app.delete("/api/albums/{album_id}", tags=["albums"])
def delete_album(album_id: int = PathParam(..., description="ID of the album to delete")):
    """
    Delete an album.
    
    Args:
        album_id: ID of the album to delete
    """
    # First check if album exists
    album = album_manager.get_album(album_id)
    if not album:
        raise HTTPException(status_code=404, detail="Album not found")
    
    # Delete the album
    if album_manager.delete_album(album_id):
        return {"message": f"Album {album_id} deleted successfully"}
    else:
        raise HTTPException(status_code=500, detail="Failed to delete album")

@app.get("/api/albums/{album_id}/photos", response_model=List[PhotoResponse], tags=["albums"])
def get_photos_in_album(album_id: int = PathParam(..., description="ID of the album")):
    """
    Get all photos in a specific album.
    
    Args:
        album_id: ID of the album
    """
    # First check if album exists
    album = album_manager.get_album(album_id)
    if not album:
        raise HTTPException(status_code=404, detail="Album not found")
    
    # Get photos in album
    photos = album_manager.get_photos_in_album(album_id)
    return photos

@app.put("/api/albums/{album_id}/photos/{photo_id}", tags=["albums"])
def add_photo_to_album(
    relation: PhotoAlbumRelation,
    album_id: int = PathParam(..., description="ID of the album"),
    photo_id: int = PathParam(..., description="ID of the photo to add")
):
    """
    Add a photo to an album.
    
    Args:
        album_id: ID of the album
        photo_id: ID of the photo to add
        relation: Optional order index for the photo
    """
    # First check if album and photo exist
    album = album_manager.get_album(album_id)
    if not album:
        raise HTTPException(status_code=404, detail="Album not found")
    
    photo = db.get_photo(photo_id)
    if not photo:
        raise HTTPException(status_code=404, detail="Photo not found")
    
    # Add photo to album
    success = album_manager.add_photos_to_album(album_id, [photo_id])
    
    # Update order if provided
    if success and relation.order_index is not None:
        album_manager.reorder_album_photos(album_id, {photo_id: relation.order_index})
    
    if success:
        return {"message": f"Photo {photo_id} added to album {album_id}"}
    else:
        raise HTTPException(status_code=500, detail="Failed to add photo to album")

@app.delete("/api/albums/{album_id}/photos/{photo_id}", tags=["albums"])
def remove_photo_from_album(
    album_id: int = PathParam(..., description="ID of the album"),
    photo_id: int = PathParam(..., description="ID of the photo to remove")
):
    """
    Remove a photo from an album.
    
    Args:
        album_id: ID of the album
        photo_id: ID of the photo to remove
    """
    # First check if album exists
    album = album_manager.get_album(album_id)
    if not album:
        raise HTTPException(status_code=404, detail="Album not found")
    
    # Remove photo from album
    if album_manager.remove_photos_from_album(album_id, [photo_id]):
        return {"message": f"Photo {photo_id} removed from album {album_id}"}
    else:
        raise HTTPException(status_code=500, detail="Failed to remove photo from album")

# Tag endpoints
@app.get("/api/tags", response_model=List[TagResponse], tags=["tags"])
def get_all_tags(hierarchy: bool = Query(False, description="Return tags in a hierarchical structure")):
    """
    Get all tags or tag hierarchy.
    
    Args:
        hierarchy: If True, return tags in a hierarchical structure
    """
    if hierarchy:
        tags = db.get_tag_hierarchy()
    else:
        tags = db.get_all_tags()
    
    # Add photo counts to each tag
    for tag in tags:
        tag["photo_count"] = len(db.get_photos_by_tag(tag["id"], limit=1000))
    
    return tags

@app.post("/api/tags", response_model=TagResponse, status_code=201, tags=["tags"])
def create_tag(tag: TagCreate):
    """
    Create a new tag.
    
    Args:
        tag: Tag details
    """
    tag_id = tag_manager.create_tag(tag.name, tag.parent_id)
    if not tag_id:
        raise HTTPException(status_code=500, detail="Failed to create tag")
    
    created_tag = db.get_tag(tag_id)
    created_tag["photo_count"] = 0
    return created_tag

@app.put("/api/tags/{tag_id}", response_model=TagResponse, tags=["tags"])
def update_tag(
    tag_update: TagBase,
    tag_id: int = PathParam(..., description="ID of the tag to update")
):
    """
    Update a tag's name and parent.
    
    Args:
        tag_id: ID of the tag to update
        tag_update: Updated tag properties
    """
    # First check if tag exists
    tag = db.get_tag(tag_id)
    if not tag:
        raise HTTPException(status_code=404, detail="Tag not found")
    
    # Update the tag
    if db.update_tag(tag_id, tag_update.name, tag_update.parent_id):
        updated_tag = db.get_tag(tag_id)
        updated_tag["photo_count"] = len(db.get_photos_by_tag(tag_id, limit=1000))
        return updated_tag
    else:
        raise HTTPException(status_code=500, detail="Failed to update tag")

@app.delete("/api/tags/{tag_id}", tags=["tags"])
def delete_tag(tag_id: int = PathParam(..., description="ID of the tag to delete")):
    """
    Delete a tag.
    
    Args:
        tag_id: ID of the tag to delete
    """
    # First check if tag exists
    tag = db.get_tag(tag_id)
    if not tag:
        raise HTTPException(status_code=404, detail="Tag not found")
    
    # Delete the tag
    if db.delete_tag(tag_id):
        return {"message": f"Tag {tag_id} deleted successfully"}
    else:
        raise HTTPException(status_code=500, detail="Failed to delete tag")

@app.get("/api/tags/{tag_id}/photos", response_model=List[PhotoResponse], tags=["tags"])
def get_photos_by_tag(
    tag_id: int = PathParam(..., description="ID of the tag"),
    limit: int = Query(100, description="Maximum number of photos to return"),
    offset: int = Query(0, description="Number of photos to skip")
):
    """
    Get all photos with a specific tag.
    
    Args:
        tag_id: ID of the tag
        limit: Maximum number of photos to return
        offset: Number of photos to skip
    """
    # First check if tag exists
    tag = db.get_tag(tag_id)
    if not tag:
        raise HTTPException(status_code=404, detail="Tag not found")
    
    # Get photos with tag
    photos = db.get_photos_by_tag(tag_id, limit=limit, offset=offset)
    return photos

@app.put("/api/photos/{photo_id}/tags/{tag_id}", tags=["tags"])
def add_tag_to_photo(
    photo_id: int = PathParam(..., description="ID of the photo"),
    tag_id: int = PathParam(..., description="ID of the tag to add")
):
    """
    Add a tag to a photo.
    
    Args:
        photo_id: ID of the photo
        tag_id: ID of the tag to add
    """
    # First check if photo and tag exist
    photo = db.get_photo(photo_id)
    if not photo:
        raise HTTPException(status_code=404, detail="Photo not found")
    
    tag = db.get_tag(tag_id)
    if not tag:
        raise HTTPException(status_code=404, detail="Tag not found")
    
    # Add tag to photo
    if db.add_tag_to_photo(photo_id, tag_id):
        return {"message": f"Tag {tag_id} added to photo {photo_id}"}
    else:
        raise HTTPException(status_code=500, detail="Failed to add tag to photo")

@app.delete("/api/photos/{photo_id}/tags/{tag_id}", tags=["tags"])
def remove_tag_from_photo(
    photo_id: int = PathParam(..., description="ID of the photo"),
    tag_id: int = PathParam(..., description="ID of the tag to remove")
):
    """
    Remove a tag from a photo.
    
    Args:
        photo_id: ID of the photo
        tag_id: ID of the tag to remove
    """
    # First check if photo and tag exist
    photo = db.get_photo(photo_id)
    if not photo:
        raise HTTPException(status_code=404, detail="Photo not found")
    
    tag = db.get_tag(tag_id)
    if not tag:
        raise HTTPException(status_code=404, detail="Tag not found")
    
    # Remove tag from photo
    if db.remove_tag_from_photo(photo_id, tag_id):
        return {"message": f"Tag {tag_id} removed from photo {photo_id}"}
    else:
        raise HTTPException(status_code=500, detail="Failed to remove tag from photo")

# Thumbnail endpoints
@app.get("/api/thumbnails/{photo_id}", tags=["thumbnails"])
def get_thumbnail(
    photo_id: int = PathParam(..., description="ID of the photo"),
    size: str = Query("sm", description="Size of thumbnail (sm, md, lg)")
):
    """
    Get a thumbnail for a photo.
    
    Args:
        photo_id: ID of the photo
        size: Size of thumbnail (sm, md, lg)
    """
    # First check if photo exists
    photo = db.get_photo(photo_id)
    if not photo:
        raise HTTPException(status_code=404, detail="Photo not found")
    
    # Get or generate thumbnail
    thumbnail_path = thumbnail_service.get_thumbnail(photo_id, size)
    
    if not thumbnail_path or not os.path.exists(thumbnail_path):
        # Fallback to generating thumbnail
        thumbnail_path = thumbnail_service.generate_thumbnail(photo["file_path"], photo_id, size)
    
    if thumbnail_path and os.path.exists(thumbnail_path):
        return FileResponse(thumbnail_path)
    else:
        # Return a placeholder image
        placeholder_path = os.path.join(os.path.dirname(__file__), "../../assets/placeholder.png")
        if os.path.exists(placeholder_path):
            return FileResponse(placeholder_path)
        else:
            raise HTTPException(status_code=404, detail="Thumbnail not found")

# Duplicate detection endpoints
@app.get("/api/duplicates", response_model=List[DuplicateGroupResponse], tags=["duplicates"])
def find_duplicates(
    folder_id: Optional[int] = Query(None, description="Find duplicates only in a specific folder")
):
    """
    Find duplicate photos based on file hash.
    
    Args:
        folder_id: Optional folder ID to limit the search to a specific folder
    """
    if folder_id is not None:
        # Check if folder exists
        folder = db.get_folder(folder_id)
        if not folder:
            raise HTTPException(status_code=404, detail="Folder not found")
        
        # Find duplicates in folder
        duplicates = duplicate_detector.find_duplicates_in_folder(folder_id)
    else:
        # Find duplicates across the entire library
        duplicates = duplicate_detector.find_exact_duplicates()
        
    return duplicates

@app.get("/api/duplicates/statistics", response_model=DuplicateStatistics, tags=["duplicates"])
def get_duplicate_statistics():
    """Get statistics about duplicates in the library."""
    return duplicate_detector.get_duplicate_statistics()

@app.put("/api/duplicates/suggest", response_model=List[int], tags=["duplicates"])
def suggest_duplicates_to_keep(group: DuplicateGroupResponse):
    """
    Suggest which photos to keep from a group of duplicates.
    
    Args:
        group: A group of duplicate photos
        
    Returns:
        List of photo IDs ordered by suggested priority to keep
    """
    if not group.photos or len(group.photos) < 2:
        raise HTTPException(status_code=400, detail="Not enough photos in the group")
        
    # Convert Pydantic model to dict format expected by the service
    group_dict = {
        "file_hash": group.file_hash,
        "photos": [photo.dict() for photo in group.photos]
    }
    
    return duplicate_detector.suggest_duplicates_to_keep(group_dict)

@app.post("/api/duplicates/action", tags=["duplicates"])
def perform_duplicate_action(action_request: DuplicateActionRequest):
    """
    Perform an action on duplicate photos.
    
    Args:
        action_request: The photos to act on and the action to take
    """
    if not action_request.photo_ids:
        raise HTTPException(status_code=400, detail="No photos specified")
        
    # Validate action
    valid_actions = ["trash", "delete", "keep"]
    if action_request.action not in valid_actions:
        raise HTTPException(status_code=400, detail=f"Invalid action. Must be one of: {', '.join(valid_actions)}")
    
    # For each photo ID, perform the requested action
    results = []
    for photo_id in action_request.photo_ids:
        photo = db.get_photo(photo_id)
        if not photo:
            results.append({"photo_id": photo_id, "success": False, "message": "Photo not found"})
            continue
            
        if action_request.action == "trash":
            success = duplicate_detector.delete_duplicate(photo_id, permanent=False)
            results.append({
                "photo_id": photo_id,
                "success": success,
                "message": "Moved to trash" if success else "Failed to move to trash"
            })
        elif action_request.action == "delete":
            success = duplicate_detector.delete_duplicate(photo_id, permanent=True)
            results.append({
                "photo_id": photo_id,
                "success": success,
                "message": "Permanently deleted" if success else "Failed to delete"
            })
    
    # Summarize results
    success_count = sum(1 for r in results if r["success"])
    
    return {
        "message": f"Completed actions on {success_count}/{len(action_request.photo_ids)} photos",
        "details": results
    }

@app.post("/api/duplicates/scan", tags=["duplicates"])
def scan_folder_for_duplicates(
    folder_path: str = Query(..., description="Path to scan for duplicates")
):
    """
    Scan a folder for images, index them, and find duplicates.
    
    Args:
        folder_path: Path to the folder to scan
    """
    if not os.path.exists(folder_path):
        raise HTTPException(status_code=400, detail="Folder path does not exist")
        
    # Scan and index the folder
    try:
        photos_added, duplicates_found = duplicate_detector.scan_and_index_folder(folder_path)
        
        # Get updated statistics
        stats = duplicate_detector.get_duplicate_statistics()
        
        return {
            "message": f"Scanned folder and found {photos_added} photos with {duplicates_found} duplicates",
            "photos_added": photos_added,
            "duplicates_found": duplicates_found,
            "statistics": stats
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error scanning folder: {str(e)}")