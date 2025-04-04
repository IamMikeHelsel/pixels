import glob
import logging
import os
import time
from enum import Enum
from typing import List, Optional

import uvicorn
from fastapi import FastAPI, HTTPException, BackgroundTasks, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel, Field

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger("pixels-tester")

# Create FastAPI app
app = FastAPI(
    title="Pixels Python Tester",
    description="Test interface for Pixels photo management functions",
    version="1.0.0"
)

# Enable CORS for frontend access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Models that mirror your Flutter app's data structures
class Folder(BaseModel):
    id: int
    name: str
    path: str
    photo_count: int = 0
    is_monitored: bool = True


class ScanType(str, Enum):
    COMMON = "common"
    SYSTEM = "system"
    SELECTED = "selected"


# Mock database - in a real app, you'd connect to your actual database
folders_db = {}
next_folder_id = 1


# Mock backend functions
def get_folders():
    return list(folders_db.values())


def add_folder(path: str, name: Optional[str] = None, is_monitored: bool = True):
    global next_folder_id

    # Normalize path for cross-platform compatibility
    normalized_path = os.path.normpath(path)

    # Check if folder exists
    if not os.path.exists(normalized_path):
        raise HTTPException(status_code=400, detail=f"Folder not found: {normalized_path}")

    # Check if folder is already in the database
    for folder in folders_db.values():
        if os.path.normpath(folder.path) == normalized_path:
            raise HTTPException(status_code=400, detail=f"Folder already exists in library: {normalized_path}")

    # Use path basename if no name provided
    if name is None:
        name = os.path.basename(normalized_path) or normalized_path

    # Count photos in directory
    try:
        photo_count = len([f for f in glob.glob(os.path.join(normalized_path, "**/*.*"), recursive=True)
                           if f.lower().endswith(('.jpg', '.jpeg', '.png', '.gif', '.bmp'))])
    except Exception as e:
        logger.error(f"Error counting photos in {normalized_path}: {str(e)}")
        photo_count = 0

    folder = Folder(
        id=next_folder_id,
        name=name,
        path=normalized_path,
        photo_count=photo_count,
        is_monitored=is_monitored
    )

    folders_db[next_folder_id] = folder
    next_folder_id += 1

    return folder


def remove_folder(folder_id: int):
    if folder_id not in folders_db:
        raise HTTPException(status_code=404, detail=f"Folder with ID {folder_id} not found")

    del folders_db[folder_id]
    return {"success": True}


def scan_folder(folder_id: int):
    if folder_id not in folders_db:
        raise HTTPException(status_code=404, detail=f"Folder with ID {folder_id} not found")

    folder = folders_db[folder_id]
    # Simulate scanning by recounting files
    try:
        photo_count = len([f for f in glob.glob(os.path.join(folder.path, "**/*.*"), recursive=True)
                           if f.lower().endswith(('.jpg', '.jpeg', '.png', '.gif', '.bmp'))])

        folder.photo_count = photo_count
        folders_db[folder_id] = folder
    except Exception as e:
        logger.error(f"Error scanning folder {folder.path}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Error scanning folder: {str(e)}")

    return folder


# API Routes
@app.get("/folders", response_model=List[Folder])
def api_get_folders():
    """Get all folders in the library"""
    try:
        logger.info("Loading folders...")
        folders = get_folders()
        logger.info(f"Loaded {len(folders)} folders")
        return folders
    except Exception as e:
        logger.error(f"Failed to load folders: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to load folders: {str(e)}")


@app.post("/folders", response_model=Folder)
def api_add_folder(path: str, name: Optional[str] = None, is_monitored: bool = True):
    """Add a new folder to the library"""
    try:
        logger.info(f"Adding folder: {path} (name: {name})")
        folder = add_folder(path, name, is_monitored)
        logger.info(f"Added folder: ID={folder.id}, Name={folder.name}")
        return folder
    except Exception as e:
        logger.error(f"Failed to add folder: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to add folder: {str(e)}")


@app.delete("/folders/{folder_id}")
def api_remove_folder(folder_id: int):
    """Remove a folder from the library"""
    try:
        logger.info(f"Removing folder ID: {folder_id}")
        result = remove_folder(folder_id)
        logger.info(f"Folder {folder_id} removed")
        return result
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Failed to remove folder: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to remove folder: {str(e)}")


@app.post("/folders/{folder_id}/scan", response_model=Folder)
def api_scan_folder(folder_id: int, background_tasks: BackgroundTasks):
    """Scan a folder to update photo count"""
    try:
        logger.info(f"Scanning folder ID: {folder_id}")
        # Simulate a time-consuming scanning process
        time.sleep(1)
        folder = scan_folder(folder_id)
        logger.info(f"Folder {folder_id} scanned, found {folder.photo_count} photos")
        return folder
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Failed to scan folder: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to scan folder: {str(e)}")


@app.post("/scan/{scan_type}")
def api_scan_locations(scan_type: ScanType, path: Optional[str] = None):
    """Scan common locations, system folders, or a selected folder"""
    try:
        if scan_type == ScanType.COMMON:
            logger.info("Scanning common photo locations")
            # Example implementation - you'd expand with actual common locations
            home_dir = os.path.expanduser("~")
            locations = [
                os.path.join(home_dir, "Pictures"),
                os.path.join(home_dir, "Downloads"),
            ]

            added = []
            for loc in locations:
                if os.path.exists(loc):
                    folder = add_folder(loc)
                    added.append(folder)

            return {"message": f"Added {len(added)} folders from common locations", "folders": added}

        elif scan_type == ScanType.SYSTEM:
            logger.info("Scanning system drives")
            # Simplified implementation
            drives = []
            if os.name == 'nt':  # Windows
                import string
                for letter in string.ascii_uppercase:
                    drive = f"{letter}:\\"
                    if os.path.exists(drive):
                        drives.append(drive)
            else:  # Unix-like
                drives = ["/"]

            added = []
            for drive in drives:
                try:
                    folder = add_folder(drive, f"Drive {os.path.basename(drive) or 'Root'}")
                    added.append(folder)
                except Exception as e:
                    logger.error(f"Error adding drive {drive}: {e}")

            return {"message": f"Added {len(added)} drives to library", "folders": added}

        elif scan_type == ScanType.SELECTED:
            if not path:
                raise HTTPException(status_code=400, detail="Path must be provided for selected folder scan")

            logger.info(f"Adding selected folder: {path}")
            folder = add_folder(path)
            return {"message": f"Added folder: {folder.name}", "folder": folder}

    except Exception as e:
        logger.error(f"Failed to scan {scan_type} locations: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to scan locations: {str(e)}")


# HTML interface to test the API - similar to Flutter UI but in web form
templates = Jinja2Templates(directory="templates")

# Create templates directory and HTML file
os.makedirs("templates", exist_ok=True)
with open("templates/index.html", "w") as f:
    f.write("""
<!DOCTYPE html>
<html>
<head>
    <title>Pixels Python Tester</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
        .card { border: 1px solid #ddd; border-radius: 4px; padding: 16px; margin-bottom: 16px; }
        .folder-list { margin-top: 20px; }
        .folder-item { display: flex; align-items: center; padding: 8px; }
        .folder-icon { margin-right: 12px; color: #0078d7; }
        .folder-info { flex: 1; }
        .action-btn { background: #0078d7; color: white; border: none; padding: 8px 16px; border-radius: 2px; cursor: pointer; }
        .error { color: red; }
        .success { color: green; }
        .folder-actions { display: flex; gap: 8px; }
        .dropdown { position: relative; display: inline-block; }
        .dropdown-content { display: none; position: absolute; background-color: #f9f9f9; min-width: 160px; box-shadow: 0px 8px 16px 0px rgba(0,0,0,0.2); z-index: 1; }
        .dropdown-content a { color: black; padding: 12px 16px; text-decoration: none; display: block; cursor: pointer; }
        .dropdown-content a:hover { background-color: #f1f1f1; }
        .dropdown:hover .dropdown-content { display: block; }
    </style>
</head>
<body>
    <h1>Pixels Python Tester</h1>
    
    <div id="status-message" style="display: none;" class="card"></div>
    
    <div class="card">
        <h2>Add Folder</h2>
        <div>
            <label>Folder Path:</label>
            <input type="text" id="folderPath" placeholder="C:/Users/username/Pictures">
        </div>
        <div>
            <label>Display Name (Optional):</label>
            <input type="text" id="folderName" placeholder="My Pictures">
        </div>
        <button class="action-btn" onclick="addFolder()">Add Folder</button>
    </div>
    
    <div class="card">
        <h2>Scan Options</h2>
        <button class="action-btn" onclick="scanCommonLocations()">Scan Common Photo Locations</button>
        <button class="action-btn" onclick="scanSystem()">Scan Entire System</button>
        <button class="action-btn" onclick="selectFolder()">Select Folder</button>
    </div>
    
    <div class="folder-list card">
        <h2>Folders</h2>
        <button class="action-btn" onclick="loadFolders()">Refresh Folders</button>
        <div id="folders-container">Loading folders...</div>
    </div>

    <script>
        // Load folders on page load
        document.addEventListener('DOMContentLoaded', loadFolders);
        
        // Show status message
        function showStatus(message, isError = false) {
            const statusEl = document.getElementById('status-message');
            statusEl.innerHTML = message;
            statusEl.className = isError ? 'card error' : 'card success';
            statusEl.style.display = 'block';
            setTimeout(() => { statusEl.style.display = 'none'; }, 5000);
        }
        
        // Load folders
        async function loadFolders() {
            const container = document.getElementById('folders-container');
            try {
                const response = await fetch('/folders');
                const folders = await response.json();
                
                if (folders.length === 0) {
                    container.innerHTML = '<p>No folders found.</p>';
                    return;
                }
                
                container.innerHTML = folders.map(folder => `
                    <div class="card folder-item">
                        <div class="folder-icon">📁</div>
                        <div class="folder-info">
                            <div><strong>${folder.name}</strong></div>
                            <div>${folder.photo_count} photos</div>
                            <div><small>${folder.path}</small></div>
                        </div>
                        <div class="folder-actions">
                            <div class="dropdown">
                                <button class="action-btn">⋮</button>
                                <div class="dropdown-content">
                                    <a onclick="scanFolder(${folder.id})">Scan for Photos</a>
                                    <a onclick="removeFolder(${folder.id})">Remove Folder</a>
                                </div>
                            </div>
                        </div>
                    </div>
                `).join('');
            } catch (error) {
                container.innerHTML = `<p class="error">Failed to load folders: ${error.message}</p>`;
            }
        }
        
        // Add folder
        async function addFolder() {
            const path = document.getElementById('folderPath').value.trim();
            const name = document.getElementById('folderName').value.trim();
            
            if (!path) {
                showStatus('Please enter a folder path', true);
                return;
            }
            
            try {
                const params = new URLSearchParams({
                    path: path,
                    is_monitored: true
                });
                
                if (name) {
                    params.append('name', name);
                }
                
                const response = await fetch(`/folders?${params.toString()}`, { method: 'POST' });
                const data = await response.json();
                
                if (response.ok) {
                    showStatus(`Folder added: ${data.name}`);
                    loadFolders();
                } else {
                    showStatus(`Failed to add folder: ${data.detail}`, true);
                }
            } catch (error) {
                showStatus(`Error: ${error.message}`, true);
            }
        }
        
        // Remove folder
        async function removeFolder(id) {
            if (!confirm('Are you sure you want to remove this folder?')) {
                return;
            }
            
            try {
                const response = await fetch(`/folders/${id}`, { method: 'DELETE' });
                const data = await response.json();
                
                if (response.ok) {
                    showStatus('Folder removed successfully');
                    loadFolders();
                } else {
                    showStatus(`Failed to remove folder: ${data.detail}`, true);
                }
            } catch (error) {
                showStatus(`Error: ${error.message}`, true);
            }
        }
        
        // Scan folder
        async function scanFolder(id) {
            try {
                showStatus('Scanning folder...');
                const response = await fetch(`/folders/${id}/scan`, { method: 'POST' });
                const data = await response.json();
                
                if (response.ok) {
                    showStatus(`Folder scanned, found ${data.photo_count} photos`);
                    loadFolders();
                } else {
                    showStatus(`Failed to scan folder: ${data.detail}`, true);
                }
            } catch (error) {
                showStatus(`Error: ${error.message}`, true);
            }
        }
        
        // Scan common locations
        async function scanCommonLocations() {
            try {
                showStatus('Scanning common photo locations...');
                const response = await fetch('/scan/common', { method: 'POST' });
                const data = await response.json();
                
                if (response.ok) {
                    showStatus(data.message);
                    loadFolders();
                } else {
                    showStatus(`Failed to scan: ${data.detail}`, true);
                }
            } catch (error) {
                showStatus(`Error: ${error.message}`, true);
            }
        }
        
        // Scan system
        async function scanSystem() {
            if (!confirm('Scanning your entire system may take a long time. Continue?')) {
                return;
            }
            
            try {
                showStatus('Scanning system drives...');
                const response = await fetch('/scan/system', { method: 'POST' });
                const data = await response.json();
                
                if (response.ok) {
                    showStatus(data.message);
                    loadFolders();
                } else {
                    showStatus(`Failed to scan: ${data.detail}`, true);
                }
            } catch (error) {
                showStatus(`Error: ${error.message}`, true);
            }
        }
        
        // Select folder to scan
        async function selectFolder() {
            const path = prompt('Enter folder path to scan:');
            if (!path) return;
            
            try {
                showStatus('Adding selected folder...');
                const params = new URLSearchParams({
                    path: path
                });
                
                const response = await fetch(`/scan/selected?${params.toString()}`, { method: 'POST' });
                const data = await response.json();
                
                if (response.ok) {
                    showStatus(data.message);
                    loadFolders();
                } else {
                    showStatus(`Failed to add folder: ${data.detail}`, true);
                }
            } catch (error) {
                showStatus(`Error: ${error.message}`, true);
            }
        }
    </script>
</body>
</html>
    """)


@app.get("/")
async def serve_ui(request):
    return templates.TemplateResponse("index.html", {"request": request})


# Run the application
if __name__ == "__main__":
    print("Starting Pixels Python Tester...")
    print("Visit http://127.0.0.1:8000 to test your Python code")
    uvicorn.run("api_test_server:app", host="127.0.0.1", port=8000, reload=True)
