#!/bin/bash

# JSON Language File Comparison Script
# Compares language files against en.json reference and generates a report

set -euo pipefail

# Configuration
FOLDER_PATH="Assets/Translations"
REFERENCE_FILE="en.json"

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if jq is installed
check_dependencies() {
    if ! command -v jq &> /dev/null; then
        print_color $RED "Error: 'jq' is required but not installed. Please install jq first." >&2
        print_color $YELLOW "On Ubuntu/Debian: sudo apt-get install jq" >&2
        print_color $YELLOW "On CentOS/RHEL: sudo yum install jq" >&2
        print_color $YELLOW "On macOS: brew install jq" >&2
        exit 1
    fi
}

# Function to extract all keys from a JSON file recursively
extract_keys() {
    local json_file=$1
    
    if [[ ! -f "$json_file" ]]; then
        echo "Error: File $json_file not found" >&2
        return 1
    fi
    
    # Extract all keys recursively using jq
    jq -r '
        def keys_recursive:
            if type == "object" then
                keys[] as $k |
                if (.[$k] | type) == "object" then
                    ($k + "." + (.[$k] | keys_recursive))
                else
                    $k
                end
            else
                empty
            end;
        keys_recursive
    ' "$json_file" 2>/dev/null | sort
}

# Function to get language files
get_language_files() {
    find "$FOLDER_PATH" -maxdepth 1 -name "*.json" -type f | sort
}

# Function to generate report header
generate_header() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "================================================================================"
    echo "                     LANGUAGE FILE COMPARISON REPORT"
    echo "================================================================================"
    echo "Generated: $timestamp"
    echo "Reference file: $REFERENCE_FILE"
    echo "Folder: $(realpath "$FOLDER_PATH")"
    echo ""
    echo "Notes:"
    echo "- Keys are compared recursively through all nested JSON objects"
    echo "- Missing keys indicate incomplete translations"
    echo "- Extra keys might indicate deprecated keys or translation-specific additions"
    echo "- Translation completion percentage is calculated based on English reference"
    echo "- Results are sorted by descending line numbers for easier editing"
    echo ""
    echo "This report compares all language JSON files against the English reference file"
    echo "and identifies missing keys and extra keys in each language."
    echo ""
}

# Function to find line number of a key in JSON file
find_key_line_number() {
    local json_file=$1
    local key_path=$2
    
    # Extract the final key name (after last dot)
    local key_name="${key_path##*.}"
    
    # Search for the key in the file with line numbers
    # Look for the pattern "key": (with quotes and colon)
    local line_num=$(grep -n "\"$key_name\":" "$json_file" 2>/dev/null | head -1 | cut -d: -f1 || echo "")
    
    if [[ -n "$line_num" ]]; then
        echo "$line_num"
    else
        # If not found with quotes, try without (though less reliable)
        line_num=$(grep -n "$key_name:" "$json_file" 2>/dev/null | head -1 | cut -d: -f1 || echo "")
        if [[ -n "$line_num" ]]; then
            echo "$line_num"
        else
            echo "?"
        fi
    fi
}

# Function to safely count lines
count_non_empty_lines() {
    local content="$1"
    if [[ -z "$content" ]]; then
        echo "0"
    else
        echo "$content" | grep -c -v '^$' || echo "0"
    fi
}

# Function to compare keys and generate report section
compare_language() {
    local lang_file="$1"
    local lang_name="$2"
    local ref_keys_file="$3"
    local ref_file_path="$FOLDER_PATH/$REFERENCE_FILE"
    
    # Create temporary file for language keys
    local lang_keys_file=$(mktemp)
    extract_keys "$lang_file" > "$lang_keys_file" || {
        echo "Error: Failed to extract keys from $lang_file" >&2
        rm -f "$lang_keys_file"
        return 1
    }
    
    # Get missing and extra keys safely
    local missing_keys=""
    local extra_keys=""
    
    missing_keys=$(comm -23 "$ref_keys_file" "$lang_keys_file" 2>/dev/null || echo "")
    extra_keys=$(comm -13 "$ref_keys_file" "$lang_keys_file" 2>/dev/null || echo "")
    
    # Count lines safely
    local missing_count=$(count_non_empty_lines "$missing_keys")
    local extra_count=$(count_non_empty_lines "$extra_keys")
    local total_ref_keys=$(wc -l < "$ref_keys_file" 2>/dev/null || echo "0")
    local total_lang_keys=$(wc -l < "$lang_keys_file" 2>/dev/null || echo "0")
    
    # Calculate completion percentage safely
    local completion_percentage=0
    if [[ $total_ref_keys -gt 0 ]]; then
        completion_percentage=$(( (total_ref_keys - missing_count) * 100 / total_ref_keys ))
    fi
    
    print_color $YELLOW "================================================================================"
    print_color $YELLOW "LANGUAGE: $lang_name"
    print_color $YELLOW "================================================================================"
    echo "File: $lang_file"
    echo "Total keys in reference (en): $total_ref_keys"
    echo "Total keys in $lang_name: $total_lang_keys"
    
    # Color code the completion percentage
    if [[ $completion_percentage -eq 100 ]]; then
        echo -e "Translation completion: ${GREEN}${completion_percentage}%${NC}"
    else
        echo -e "Translation completion: ${RED}${completion_percentage}%${NC}"
    fi
    
    echo ""
    echo "SUMMARY:"
    echo "- Missing keys (exist in English but not in $lang_name): $missing_count"
    echo "- Extra keys (exist in $lang_name but not in English): $extra_count"
    echo ""

    # Handle missing keys
    if [[ $missing_count -gt 0 && -n "$missing_keys" ]]; then
        echo "MISSING KEYS IN $lang_name:"
        
        # Collect keys with line numbers and sort by line number (descending)
        local temp_missing=$(mktemp)
        while IFS= read -r key; do
            if [[ -n "$key" ]]; then
                local ref_line=$(find_key_line_number "$ref_file_path" "$key")
                # Use numeric sort padding for proper sorting
                if [[ "$ref_line" =~ ^[0-9]+$ ]]; then
                    printf "%06d|%s|en.json:%s\n" "$ref_line" "$key" "$ref_line" >> "$temp_missing"
                else
                    printf "999999|%s|en.json:%s\n" "$key" "$ref_line" >> "$temp_missing"
                fi
            fi
        done <<< "$missing_keys"
        
        # Sort by line number (descending) and display
        local counter=1
        sort -t'|' -k1,1nr "$temp_missing" | while IFS='|' read -r sort_key key location; do
            printf "  %3d. %s (%s)\n" "$counter" "$key" "$location"
            counter=$((counter + 1))
        done
        rm -f "$temp_missing"
        echo ""
    else
        echo "✅ No missing keys in $lang_name"
        echo ""
    fi
    
    # Handle extra keys
    if [[ $extra_count -gt 0 && -n "$extra_keys" ]]; then
        echo "EXTRA KEYS IN $lang_name (not in English):"
        
        # Collect keys with line numbers and sort by line number (descending)
        local temp_extra=$(mktemp)
        while IFS= read -r key; do
            if [[ -n "$key" ]]; then
                local lang_line=$(find_key_line_number "$lang_file" "$key")
                # Use numeric sort padding for proper sorting
                if [[ "$lang_line" =~ ^[0-9]+$ ]]; then
                    printf "%06d|%s|%s:%s\n" "$lang_line" "$key" "$(basename "$lang_file")" "$lang_line" >> "$temp_extra"
                else
                    printf "999999|%s|%s:%s\n" "$key" "$(basename "$lang_file")" "$lang_line" >> "$temp_extra"
                fi
            fi
        done <<< "$extra_keys"
        
        # Sort by line number (descending) and display
        local counter=1
        sort -t'|' -k1,1nr "$temp_extra" | while IFS='|' read -r sort_key key location; do
            printf "  %3d. %s (%s)\n" "$counter" "$key" "$location"
            counter=$((counter + 1))
        done
        rm -f "$temp_extra"
        echo ""
    else
        echo "✅ No extra keys in $lang_name"
        echo ""
    fi
    
    # Clean up
    rm -f "$lang_keys_file"
}

# Main function
main() {
    local target_language="$1"
    
    print_color $BLUE "Starting language file comparison..." >&2
    
    # Check dependencies
    check_dependencies
    
    # Validate folder path
    if [[ ! -d "$FOLDER_PATH" ]]; then
        print_color $RED "Error: Folder '$FOLDER_PATH' does not exist" >&2
        exit 1
    fi
    
    # Check if reference file exists
    local ref_file_path="$FOLDER_PATH/$REFERENCE_FILE"
    if [[ ! -f "$ref_file_path" ]]; then
        print_color $RED "Error: Reference file '$ref_file_path' does not exist" >&2
        exit 1
    fi
    
    print_color $GREEN "Reference file found: $ref_file_path" >&2
    
    # Extract keys from reference file
    local ref_keys_file=$(mktemp)
    if ! extract_keys "$ref_file_path" > "$ref_keys_file"; then
        print_color $RED "Error: Failed to extract keys from reference file" >&2
        rm -f "$ref_keys_file"
        exit 1
    fi
    
    local total_ref_keys=$(wc -l < "$ref_keys_file" 2>/dev/null || echo "0")
    
    print_color $BLUE "Extracted $total_ref_keys keys from reference file" >&2
    
    # Get all language files or just the target language
    local -a language_files
    if [[ -n "$target_language" ]]; then
        # Single language mode
        local target_file="$FOLDER_PATH/${target_language}.json"
        if [[ ! -f "$target_file" ]]; then
            print_color $RED "Error: Language file '$target_file' does not exist" >&2
            rm -f "$ref_keys_file"
            exit 1
        fi
        if [[ "$target_language" == "${REFERENCE_FILE%.json}" ]]; then
            print_color $RED "Error: Cannot compare reference file against itself" >&2
            rm -f "$ref_keys_file"
            exit 1
        fi
        language_files=("$target_file")
        print_color $BLUE "Checking single language: $target_language" >&2
    else
        # All languages mode
        while IFS= read -r -d '' file; do
            language_files+=("$file")
        done < <(find "$FOLDER_PATH" -maxdepth 1 -name "*.json" -type f -print0 | sort -z)
        
        if [[ ${#language_files[@]} -eq 0 ]]; then
            print_color $RED "Error: No JSON files found in $FOLDER_PATH" >&2
            rm -f "$ref_keys_file"
            exit 1
        fi
        print_color $BLUE "Found ${#language_files[@]} JSON files to process" >&2
    fi
    
    echo "" >&2
    
    # Generate report header
    generate_header
    
    local processed=0
    for lang_file in "${language_files[@]}"; do
        local filename=$(basename "$lang_file")
        local lang_name="${filename%.json}"
        
        # Skip the reference file in all-languages mode
        if [[ -z "$target_language" && "$filename" == "$REFERENCE_FILE" ]]; then
            continue
        fi
        
        print_color $YELLOW "Processing: $filename" >&2
        
        # Validate JSON syntax
        if ! jq empty "$lang_file" 2>/dev/null; then
            print_color $RED "Warning: $lang_file contains invalid JSON syntax. Skipping..." >&2
            echo "ERROR: $lang_file contains invalid JSON syntax and was skipped."
            echo ""
            continue
        fi
        
        if compare_language "$lang_file" "$lang_name" "$ref_keys_file"; then
            processed=$((processed + 1))
        else
            print_color $RED "Error processing $lang_file" >&2
        fi
    done
    
    # Add summary at the end
    echo "================================================================================"
    echo "SUMMARY"
    echo "================================================================================"
    echo "Total files processed: $processed"
    echo "Reference file: $REFERENCE_FILE (English)"
    if [[ -n "$target_language" ]]; then
        echo "Target language: $target_language"
    fi
    echo "Report generated: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "================================================================================"
    
    # Clean up
    rm -f "$ref_keys_file"
    
    if [[ -n "$target_language" ]]; then
        print_color $GREEN "Comparison completed for language: $target_language" >&2
    else
        print_color $GREEN "Comparison completed: Processed $processed language files against English reference" >&2
    fi
}

# Usage information
show_usage() {
    echo "Usage: $0 [language_code]" >&2
    echo "" >&2
    echo "This script compares JSON language files in '$FOLDER_PATH' against the English reference." >&2
    echo "" >&2
    echo "Arguments:" >&2
    echo "  language_code  Optional. Compare only the specified language (e.g., 'fr', 'es', 'de')" >&2
    echo "                 If not provided, all language files will be compared" >&2
    echo "" >&2
    echo "Configuration:" >&2
    echo "  - Folder path: $FOLDER_PATH (hardcoded)" >&2
    echo "  - Reference file: $REFERENCE_FILE" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  $0              # Compare all languages" >&2
    echo "  $0 fr           # Compare only French (fr.json)" >&2
    echo "  $0 es           # Compare only Spanish (es.json)" >&2
    echo "" >&2
    echo "Requirements:" >&2
    echo "  - jq must be installed" >&2
    echo "  - $REFERENCE_FILE must exist in $FOLDER_PATH" >&2
    echo "  - Target language file must exist if specified" >&2
    echo "" >&2
    echo "Output:" >&2
    echo "  - Comparison report is printed to stdout" >&2
    echo "  - Progress messages are printed to stderr" >&2
    echo "  - Results are sorted by descending line numbers for easier editing" >&2
}

# Handle command line arguments
if [[ $# -gt 1 ]]; then
    echo "Error: Too many arguments. Only one language code is allowed." >&2
    echo "" >&2
    show_usage
    exit 1
fi

if [[ $# -eq 1 ]]; then
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_usage
        exit 0
    else
        # Validate language code format (basic check for reasonable filename)
        if [[ ! "$1" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
            echo "Error: Invalid language code format '$1'. Use alphanumeric characters, hyphens, and underscores only." >&2
            echo "" >&2
            show_usage
            exit 1
        fi
        # Run main function with target language
        main "$1"
    fi
else
    # Run main function for all languages
    main ""
fi