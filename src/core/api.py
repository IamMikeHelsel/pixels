#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
REST API server for Pixels photo manager application.

This module provides a FastAPI-based REST API that exposes the photo database
functionality to the Flutter frontend.
"""

import os
import sys
import json
import logging
import datetime
import traceback
from typing import Dict, List, Optional, Any, Union, Literal
from pathlib import Path

from fastapi import FastAPI, HTTPException, Query, Path as PathParam, Body, UploadFile, File, Form
from fastapi.responses import FileResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import uvicorn

from .database import PhotoDatabase
from .thumbnail_service import ThumbnailService
from .library_indexer import LibraryIndexer
from .tag_manager import TagManager
from .album_manager import AlbumManager

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("pixels.api")

# Create FastAPI application
app = FastAPI(
    title="Pixels Photo Manager API",
    description="REST API for managing and accessing your photo library",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    openapi_tags=[
        {
            "name": "health",
            "description": "Health check endpoints"
        },
        {
            "name": "folders",
            "description": "Operations with photo folders"
        },
        {
            "name": "photos",
            "description": "Operations with photos"
        },
        {
            "name": "albums",
            "description": "Operations with albums"
        },
        {
            "name": "tags",
            "description": "Operations with tags"
        },
        {
            "name": "thumbnails",
            "description": "Photo thumbnail operations"
        }
    ]
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

# Initialize database and services
db = PhotoDatabase()
thumbnail_service = ThumbnailService(db)
library_indexer = LibraryIndexer(db, thumbnail_service)
tag_manager = TagManager(db)
album_manager = AlbumManager(db)

# Define Pydantic models for request/response validation

class HealthResponse(BaseModel):
    status: str
    timestamp: str

class FolderBase(BaseModel):
    path: str
    name: Optional[str] = None
    parent_id: Optional[int] = None
    is_monitored: Optional[bool] = False

class FolderCreate(FolderBase):
    pass

class FolderResponse(FolderBase):
    id: int
    photo_count: Optional[int] = 0

class PhotoResponse(BaseModel):
    id: int
    file_name: str
    file_path: str
    thumbnail_path: Optional[str] = None
    width: Optional[int] = None
    height: Optional[int] = None
    date_taken: Optional[datetime.datetime] = None
    file_size: Optional[int] = None
    camera_make: Optional[str] = None
    camera_model: Optional[str] = None
    rating: Optional[int] = None
    is_favorite: Optional[bool] = False
    tags: Optional[List[Dict[str, Any]]] = None
    albums: Optional[List[Dict[str, Any]]] = None

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
    if isinstance(obj, (datetime.date, datetime.datetime)):
        return obj.isoformat()
    raise TypeError(f"Type {type(obj)} not serializable")

# Health check endpoint
@app.get("/api/health", response_model=HealthResponse, tags=["health"])
async def health_check():
    """Health check endpoint to confirm the API is running."""
    return {"status": "ok", "timestamp": datetime.datetime.now().isoformat()}

# Folder endpoints
@app.get("/api/folders", response_model=List[FolderResponse], tags=["folders"])
async def get_folders(hierarchy: bool = False):
    """Get all folders or folder hierarchy."""
    try:
        if hierarchy:
            folders = db.get_folder_hierarchy()
        else:
            folders = db.get_all_folders()
            
        # Add photo count for each folder
        for folder in folders:
            folder_id = folder['id']
            photos = db.get_photos_by_folder(folder_id)
            folder['photo_count'] = len(photos)
            
        return folders
    except Exception as e:
        logger.error(f"Error getting folders: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/folders/{folder_id}", response_model=FolderResponse, tags=["folders"])
async def get_folder(folder_id: int = PathParam(..., ge=1)):
    """Get a specific folder by ID."""
    try:
        folder = db.get_folder(folder_id)
        if not folder:
            raise HTTPException(status_code=404, detail="Folder not found")
            
        # Add photo count
        photos = db.get_photos_by_folder(folder_id)
        folder['photo_count'] = len(photos)
            
        return folder
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting folder {folder_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/folders", response_model=Dict[str, Any], status_code=201, tags=["folders"])
async def add_folder(folder: FolderCreate):
    """Add a new folder to the database."""
    try:
        path = folder.path
        name = folder.name
        parent_id = folder.parent_id
        is_monitored = folder.is_monitored
        
        folder_id = db.add_folder(path, name, parent_id, is_monitored)
        
        if folder_id:
            # If folder is monitored, start indexing
            if is_monitored:
                library_indexer.index_folder(path)
                
            return {"id": folder_id, "message": "Folder added successfully"}
        else:
            raise HTTPException(status_code=500, detail="Failed to add folder")
    except Exception as e:
        logger.error(f"Error adding folder: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Photo endpoints
@app.get("/api/photos/folder/{folder_id}", response_model=List[PhotoResponse], tags=["photos"])
async def get_photos_by_folder(folder_id: int = PathParam(..., ge=1)):
    """Get all photos in a folder."""
    try:
        photos = db.get_photos_by_folder(folder_id)
        return photos
    except Exception as e:
        logger.error(f"Error getting photos for folder {folder_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/photos/{photo_id}", response_model=PhotoResponse, tags=["photos"])
async def get_photo(photo_id: int = PathParam(..., ge=1)):
    """Get a specific photo by ID."""
    try:
        photo = db.get_photo(photo_id)
        if not photo:
            raise HTTPException(status_code=404, detail="Photo not found")
            
        # Add tags
        photo['tags'] = db.get_tags_for_photo(photo_id)
        
        # Add albums
        photo['albums'] = db.get_albums_for_photo(photo_id)
            
        return photo
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting photo {photo_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.patch("/api/photos/{photo_id}", response_model=Dict[str, str], tags=["photos"])
async def update_photo(photo_id: int = PathParam(..., ge=1), photo_update: PhotoUpdate = Body(...)):
    """Update photo properties."""
    try:
        # Only allow updating certain fields
        update_data = {}
        if photo_update.rating is not None:
            update_data['rating'] = photo_update.rating
        if photo_update.is_favorite is not None:
            update_data['is_favorite'] = photo_update.is_favorite
        
        if not update_data:
            raise HTTPException(status_code=400, detail="No valid fields to update")
            
        success = db.update_photo(photo_id, **update_data)
        
        if success:
            return {"message": "Photo updated successfully"}
        else:
            raise HTTPException(status_code=500, detail="Failed to update photo")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating photo {photo_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/photos/search", response_model=List[PhotoResponse], tags=["photos"])
async def search_photos(
    keyword: Optional[str] = None,
    folder_ids: Optional[str] = None,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    min_rating: Optional[int] = None,
    is_favorite: Optional[bool] = None,
    tag_ids: Optional[str] = None,
    album_id: Optional[int] = None,
    limit: int = 100,
    offset: int = 0,
    sort_by: str = "date_taken",
    sort_desc: bool = True
):
    """Search photos with multiple filter criteria."""
    try:
        # Process parameters
        folder_ids_list = [int(id) for id in folder_ids.split(',')] if folder_ids else None
        tag_ids_list = [int(id) for id in tag_ids.split(',')] if tag_ids else None
        
        photos = db.search_photos(
            keyword=keyword,
            folder_ids=folder_ids_list,
            date_from=date_from,
            date_to=date_to,
            min_rating=min_rating,
            is_favorite=is_favorite,
            tag_ids=tag_ids_list,
            album_id=album_id,
            limit=limit,
            offset=offset,
            sort_by=sort_by,
            sort_desc=sort_desc
        )
        
        return photos
    except Exception as e:
        logger.error(f"Error searching photos: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Album endpoints
@app.get("/api/albums", response_model=List[AlbumResponse], tags=["albums"])
async def get_albums():
    """Get all albums."""
    try:
        albums = db.get_all_albums()
        
        # Add photo count for each album
        for album in albums:
            album_id = album['id']
            photos = db.get_photos_in_album(album_id)
            album['photo_count'] = len(photos)
            
        return albums
    except Exception as e:
        logger.error(f"Error getting albums: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/albums/{album_id}", response_model=AlbumResponse, tags=["albums"])
async def get_album(album_id: int = PathParam(..., ge=1)):
    """Get a specific album by ID."""
    try:
        album = db.get_album(album_id)
        if not album:
            raise HTTPException(status_code=404, detail="Album not found")
        
        # Add photo count
        photos = db.get_photos_in_album(album_id)
        album['photo_count'] = len(photos)
            
        return album
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting album {album_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/albums/{album_id}/photos", response_model=List[PhotoResponse], tags=["albums"])
async def get_album_photos(album_id: int = PathParam(..., ge=1)):
    """Get all photos in an album."""
    try:
        photos = db.get_photos_in_album(album_id)
        return photos
    except Exception as e:
        logger.error(f"Error getting photos for album {album_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/albums", response_model=Dict[str, Any], status_code=201, tags=["albums"])
async def create_album(album: AlbumCreate):
    """Create a new album."""
    try:
        name = album.name
        description = album.description
        
        album_id = db.create_album(name, description)
        
        if album_id:
            return {"id": album_id, "message": "Album created successfully"}
        else:
            raise HTTPException(status_code=500, detail="Failed to create album")
    except Exception as e:
        logger.error(f"Error creating album: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/albums/{album_id}/photos/{photo_id}", response_model=Dict[str, str], tags=["albums"])
async def add_photo_to_album(
    album_id: int = PathParam(..., ge=1), 
    photo_id: int = PathParam(..., ge=1),
    relation: PhotoAlbumRelation = Body(...)
):
    """Add a photo to an album."""
    try:
        success = db.add_photo_to_album(album_id, photo_id, relation.order_index)
        
        if success:
            return {"message": "Photo added to album successfully"}
        else:
            raise HTTPException(status_code=500, detail="Failed to add photo to album")
    except Exception as e:
        logger.error(f"Error adding photo {photo_id} to album {album_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/albums/{album_id}/photos/{photo_id}", response_model=Dict[str, str], tags=["albums"])
async def remove_photo_from_album(album_id: int = PathParam(..., ge=1), photo_id: int = PathParam(..., ge=1)):
    """Remove a photo from an album."""
    try:
        success = db.remove_photo_from_album(album_id, photo_id)
        
        if success:
            return {"message": "Photo removed from album successfully"}
        else:
            raise HTTPException(status_code=500, detail="Failed to remove photo from album")
    except Exception as e:
        logger.error(f"Error removing photo {photo_id} from album {album_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Tag endpoints
@app.get("/api/tags", response_model=List[TagResponse], tags=["tags"])
async def get_tags(hierarchy: bool = False):
    """Get all tags or tag hierarchy."""
    try:
        if hierarchy:
            tags = db.get_tag_hierarchy()
        else:
            tags = db.get_all_tags()
            
        return tags
    except Exception as e:
        logger.error(f"Error getting tags: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/tags/{tag_id}/photos", response_model=List[PhotoResponse], tags=["tags"])
async def get_photos_by_tag(
    tag_id: int = PathParam(..., ge=1),
    limit: int = 100,
    offset: int = 0
):
    """Get all photos with a specific tag."""
    try:
        photos = db.get_photos_by_tag(tag_id, limit, offset)
        return photos
    except Exception as e:
        logger.error(f"Error getting photos for tag {tag_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/photos/{photo_id}/tags/{tag_id}", response_model=Dict[str, str], tags=["tags"])
async def add_tag_to_photo(photo_id: int = PathParam(..., ge=1), tag_id: int = PathParam(..., ge=1)):
    """Add a tag to a photo."""
    try:
        success = db.add_tag_to_photo(photo_id, tag_id)
        
        if success:
            return {"message": "Tag added to photo successfully"}
        else:
            raise HTTPException(status_code=500, detail="Failed to add tag to photo")
    except Exception as e:
        logger.error(f"Error adding tag {tag_id} to photo {photo_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/photos/{photo_id}/tags/{tag_id}", response_model=Dict[str, str], tags=["tags"])
async def remove_tag_from_photo(photo_id: int = PathParam(..., ge=1), tag_id: int = PathParam(..., ge=1)):
    """Remove a tag from a photo."""
    try:
        success = db.remove_tag_from_photo(photo_id, tag_id)
        
        if success:
            return {"message": "Tag removed from photo successfully"}
        else:
            raise HTTPException(status_code=500, detail="Failed to remove tag from photo")
    except Exception as e:
        logger.error(f"Error removing tag {tag_id} from photo {photo_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Thumbnail endpoints
@app.get("/api/thumbnails/{photo_id}", tags=["thumbnails"])
async def get_thumbnail(
    photo_id: int = PathParam(..., ge=1),
    size: Literal["small", "medium", "large"] = "medium"
):
    """Get a thumbnail for a photo."""
    try:
        # Get the photo
        photo = db.get_photo(photo_id)
        if not photo:
            raise HTTPException(status_code=404, detail="Photo not found")
            
        # Generate or retrieve thumbnail
        thumbnail_path = thumbnail_service.get_thumbnail(photo_id, photo['file_path'], size)
        
        if not thumbnail_path or not os.path.exists(thumbnail_path):
            raise HTTPException(status_code=404, detail="Thumbnail not available")
            
        return FileResponse(thumbnail_path)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting thumbnail for photo {photo_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

# Shutdown endpoint
@app.post("/api/shutdown", response_model=Dict[str, str], tags=["health"])
async def shutdown():
    """Gracefully shutdown the API server."""
    try:
        # This will only work when running with Uvicorn directly
        import asyncio
        asyncio.create_task(shutdown_server())
        return {"message": "Server is shutting down"}
    except Exception as e:
        logger.error(f"Error during shutdown: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

async def shutdown_server():
    """Shutdown the server after a short delay to allow response to be sent."""
    # Wait a moment to allow the response to be sent
    await asyncio.sleep(1)
    # Exit the process
    import sys
    sys.exit(0)

def start_server(host='localhost', port=5000, debug=False):
    """Start the FastAPI server."""
    log_level = "debug" if debug else "info"
    
    if debug:
        import uvicorn
        uvicorn.run(app, host=host, port=port, log_level=log_level)
    else:
        import uvicorn
        logger.info(f"Starting Pixels API server on {host}:{port}")
        uvicorn.run(app, host=host, port=port, log_level=log_level)

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Start the Pixels API server")
    parser.add_argument('--host', default='localhost', help='Host to bind to')
    parser.add_argument('--port', type=int, default=5000, help='Port to bind to')
    parser.add_argument('--debug', action='store_true', help='Run in debug mode')
    
    args = parser.parse_args()
    
    start_server(args.host, args.port, args.debug)