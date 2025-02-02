#!/bin/bash

# Enable debugging (optional)
set -x

# Function to increment the version
increment_version() {
    local version=$1
    local increment_patch=$2
    local major=$(echo "$version" | cut -d '.' -f 1)
    local minor=$(echo "$version" | cut -d '.' -f 2)
    local patch=$(echo "$version" | cut -d '.' -f 3)

    # Increment logic
    if [ "$increment_patch" -eq 1 ]; then
        patch=$((patch + 1))
    else
        minor=$((minor + 1))
        patch=0  # Reset patch version when incrementing minor version
    fi

    echo "${major}.${minor}.${patch}"
}

# Default increment type: minor
increment_patch=0  # 0 = false (increment minor version by default)

# Parse arguments
if [ "$1" == "-p" ]; then
    increment_patch=1  # 1 = true (increment patch version)
    shift  # Remove the '-p' flag from the arguments
fi

# Debugging output for increment_patch
echo "Increment patch flag: $increment_patch"

# If version argument is not passed, auto-increment the highest version in the repo
if [ -z "$1" ]; then
    if [ ! -d "configs" ] || [ -z "$(ls configs)" ]; then
        echo "Error: No existing versions found in 'configs/' to auto-bump."
        exit 1
    fi
    # Get the latest version folder, excluding "current"
    LATEST_VERSION=$(ls configs | grep -v 'current' | sort -V | tail -n 1)
    if [ -z "$LATEST_VERSION" ]; then
        echo "Error: No version folders found in 'configs/'."
        exit 1
    fi
    # Increment the latest version
    NEW_VERSION=$(increment_version "$LATEST_VERSION" "$increment_patch")
    echo "No version provided. Auto-incrementing from latest version: $LATEST_VERSION -> $NEW_VERSION"
else
    NEW_VERSION=$1
    # If a version is provided, increment it based on '-p' flag
    NEW_VERSION=$(increment_version "$NEW_VERSION" "$increment_patch")
fi

# Check if the current folder exists
CONFIG_DIR="configs"
CURRENT_DIR="${CONFIG_DIR}/current"
if [ ! -d "$CURRENT_DIR" ]; then
    echo "Error: '${CURRENT_DIR}/' folder not found. Make sure the current folder exists."
    exit 1
fi

# Get the latest version from the configs directory (excluding the current folder)
LATEST_VERSION=$(ls "$CONFIG_DIR" | grep -v 'current' | sort -V | tail -n 1)

# Increment the version (minor version by default)
NEW_VERSION=$(increment_version "$LATEST_VERSION")

# Increment the version (minor version by default)
CURRENT_VERSION=$(increment_version "$NEW_VERSION")

# New version directory
NEW_VERSION_DIR="${CONFIG_DIR}/${NEW_VERSION}"

# New version directory
CURRENT_VERSION_DIR="${CONFIG_DIR}/${CURRENT_VERSION}"

# Check if the new version folder already exists
if [ -d "$NEW_VERSION_DIR" ]; then
    echo "Error: Version directory '${NEW_VERSION_DIR}' already exists."
    exit 1
fi

# Clone the current folder to the new version folder
echo "Cloning '${CURRENT_DIR}' to '${NEW_VERSION_DIR}'"
cp -r "$CURRENT_DIR" "$NEW_VERSION_DIR"

# Now, rename the latest files to reflect the new version
for file in "${NEW_VERSION_DIR}"/*.json; do
    BASENAME=$(basename "$file")
    PLATFORM=$(echo "$BASENAME" | cut -d '-' -f 1)   # Extract the platform (Android or iOS)
    NEW_FILENAME="${PLATFORM}-${NEW_VERSION}.json"   # Form the new filename with version

    # Rename the file
    mv "$file" "${NEW_VERSION_DIR}/${NEW_FILENAME}"
    echo "Renamed: $BASENAME -> ${NEW_VERSION_DIR}/${NEW_FILENAME}"
done

# Now, rename the latest files to reflect the new version
for file in "${CURRENT_VERSION_DIR}"/*.json; do
    BASENAME=$(basename "$file")
    PLATFORM=$(echo "$BASENAME" | cut -d '-' -f 1)   # Extract the platform (Android or iOS)
    NEW_FILENAME="${PLATFORM}-${CURRENT_VERSION}.json"   # Form the new filename with version

    # Rename the file
    mv "$file" "${NEW_VERSION_DIR}/${NEW_FILENAME}"
    echo "Renamed: $BASENAME -> ${CURRENT_VERSION_DIR}/${NEW_FILENAME}"
done


# Remove the old current folder and create a new one for the latest version
rm -rf "$CURRENT_DIR"
mkdir "$CURRENT_DIR"

# Copy the new version to the current folder
cp -r "$NEW_VERSION_DIR"/* "$CURRENT_DIR"

# Success message
echo "Version bump complete. Cloned folder created as '${NEW_VERSION_DIR}' and 'current/' updated with new version."
