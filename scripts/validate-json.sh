#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: 'jq' is not installed. Please install it to use this script."
    exit 1
fi

# Find all JSON files in the repository
JSON_FILES=$(find . -type f -name "*.json")

# Check if any JSON files were found
if [ -z "$JSON_FILES" ]; then
    echo "No JSON files found in the repository."
    exit 0
fi

# Validate each JSON file
echo "Starting JSON validation..."
for file in $JSON_FILES; do
    echo "Validating: $file"
    if ! jq empty "$file" &> /dev/null; then
        echo "Invalid JSON detected in file: $file"
        exit 1
    fi
done

echo "All JSON files are valid."