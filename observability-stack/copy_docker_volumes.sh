#!/bin/bash

# =============================================================================
# Script: copy_docker_volumes.sh
# Description: Automatically copies data from Docker volumes with a specific
#              prefix to corresponding directories under /mnt/ebs/.
# =============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# =============================================================================
# Configuration Variables
# =============================================================================

# Base directory where Docker volumes are mounted
DOCKER_VOLUMES_BASE_DIR="/var/lib/docker/volumes"

# Destination base directory (EBS mount point)
DEST_BASE_DIR="/mnt/ebs"

# Prefix to filter relevant Docker volumes
VOLUME_PREFIX="observability-stack_"

# Log file for operations
LOG_FILE="/var/log/copy_docker_volumes.log"

# =============================================================================
# Logging Function
# =============================================================================

# Function to log messages with timestamps
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') : $1" | tee -a "$LOG_FILE"
}

# Ensure the log file exists and has appropriate permissions
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

log "=== Starting Docker volumes data copy to $DEST_BASE_DIR ==="

# =============================================================================
# Pre-flight Checks
# =============================================================================

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    log "ERROR: Docker is not installed. Please install Docker and try again."
    exit 1
fi

# Check if Docker daemon is running
if ! docker info > /dev/null 2>&1; then
    log "ERROR: Docker daemon is not running. Please start Docker and try again."
    exit 1
fi

# Check if DEST_BASE_DIR exists and is writable
if [ ! -d "$DEST_BASE_DIR" ]; then
    log "Destination base directory $DEST_BASE_DIR does not exist. Creating it."
    mkdir -p "$DEST_BASE_DIR"
    if [ $? -ne 0 ]; then
        log "ERROR: Failed to create destination base directory $DEST_BASE_DIR. Exiting."
        exit 1
    fi
fi

if [ ! -w "$DEST_BASE_DIR" ]; then
    log "ERROR: Destination base directory $DEST_BASE_DIR is not writable. Check permissions."
    exit 1
fi

# =============================================================================
# Identify and Process Docker Volumes
# =============================================================================

# Retrieve list of Docker volumes with the specified prefix
VOLUMES=$(docker volume ls --filter "name=^${VOLUME_PREFIX}" -q)

if [ -z "$VOLUMES" ]; then
    log "No Docker volumes found with prefix '$VOLUME_PREFIX'. Exiting."
    exit 0
fi

# Iterate over each Docker volume
for VOLUME in $VOLUMES; do
    SOURCE_DIR="$DOCKER_VOLUMES_BASE_DIR/${VOLUME}/_data"
    
    # Extract service name by removing the prefix
    SERVICE_NAME="${VOLUME#${VOLUME_PREFIX}}"
    DEST_DIR="$DEST_BASE_DIR/${SERVICE_NAME}"
    
    log "Processing Docker volume: $VOLUME"
    
    # Check if source directory exists
    if [ ! -d "$SOURCE_DIR" ]; then
        log "WARNING: Source directory $SOURCE_DIR does not exist. Skipping volume $VOLUME."
        continue
    fi
    
    # Create destination directory if it doesn't exist
    if [ ! -d "$DEST_DIR" ]; then
        log "Destination directory $DEST_DIR does not exist. Creating it."
        mkdir -p "$DEST_DIR"
        if [ $? -ne 0 ]; then
            log "ERROR: Failed to create destination directory $DEST_DIR. Skipping volume $VOLUME."
            continue
        fi
    fi
    
    # Copy data using rsync
    log "Copying data from $SOURCE_DIR to $DEST_DIR"
    rsync -av --progress "$SOURCE_DIR/" "$DEST_DIR/"
    if [ $? -eq 0 ]; then
        log "SUCCESS: Copied volume $VOLUME to $DEST_DIR successfully."
    else
        log "ERROR: Failed to copy volume $VOLUME to $DEST_DIR."
    fi
done

log "=== Docker volumes data copy operation completed ==="
