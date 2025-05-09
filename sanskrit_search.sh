#!/bin/bash

# Ensure script runs with UTF-8 encoding
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Check for correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <directory_path> <search_string>"
    exit 1
fi

DIRECTORY="$1"
SEARCH_STRING="$2"
MATCH_COUNT=0
DOC_COUNT=0
DOCX_COUNT=0

# Verify if the directory exists
if [ ! -d "$DIRECTORY" ]; then
    echo "Error: Directory '$DIRECTORY' does not exist."
    exit 1
fi

echo "Starting search in: $DIRECTORY"
echo "Searching for: '$SEARCH_STRING'"
echo "-----------------------------------"

# Find all .doc and .docx files and count them
DOC_FILES=$(find "$DIRECTORY" -type f -name "*.doc")
DOCX_FILES=$(find "$DIRECTORY" -type f -name "*.docx")
DOC_COUNT=$(echo "$DOC_FILES" | wc -l | tr -d ' ')
DOCX_COUNT=$(echo "$DOCX_FILES" | wc -l | tr -d ' ')

TOTAL_FILES=$((DOC_COUNT + DOCX_COUNT))
if [ "$TOTAL_FILES" -eq 0 ]; then
    echo "No .doc or .docx files found in the directory."
    exit 0
fi

echo "Found $DOC_COUNT .doc files and $DOCX_COUNT .docx files."
echo "Processing files..."
echo "-----------------------------------"

# Process .doc and .docx files
find "$DIRECTORY" \( -name "*.doc" -o -name "*.docx" \) | while IFS= read -r file; do
    echo "Processing: $file"
    
    if [[ "$file" == *.doc ]]; then
        TEXT=$(antiword "$file" 2>/dev/null | iconv -f ISO-8859-1 -t UTF-8)
    elif [[ "$file" == *.docx ]]; then
        TEXT=$(./docx2txt "$file" "-" 2>/dev/null)
    fi

    if [[ -n "$TEXT" ]]; then
        # Search for the string and print the surrounding context if found
        MATCHES=$(echo "$TEXT" | ggrep -i -C 2 --color=always -P "$SEARCH_STRING")
        if [[ -n "$MATCHES" ]]; then
            echo "$MATCHES"
            echo "File: $file"
            echo "-----------------------------------"
            MATCH_COUNT=$((MATCH_COUNT + 1))
        fi
    fi
done

# Final Summary
echo "$MATCH_COUNT"
if [ "$MATCH_COUNT" -eq 0 ]; then
    echo "No matches found for '$SEARCH_STRING'."
else
    echo "Search complete: Found $MATCH_COUNT matches."
fi
