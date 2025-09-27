#!/bin/bash

# Comprehensive i18n checker for QML files
# Finds hardcoded strings in various QML properties

find . -name "*.qml" -type f | while read -r file; do
    # Skip if file doesn't exist or is not readable
    [[ ! -r "$file" ]] && continue
    
    # Check for hardcoded strings in common properties
    # Matches: property: "text with letters" but excludes I18n.tr calls
    issues=$(grep -n -E '(label|text|title|description|placeholder|tooltipText|tooltip):\s*"[^"]*[a-zA-Z][^"]*"' "$file" | grep -v 'I18n\.tr')
    
    # Also check for template literals with hardcoded text
    template_issues=$(grep -n -E '(label|text|title|description|placeholder|tooltipText|tooltip):\s*`[^`]*[a-zA-Z][^`]*`' "$file" | grep -v 'I18n\.tr')
    
    # Check for property assignments with hardcoded strings
    property_issues=$(grep -n -E 'property\s+string\s+\w+:\s*"[^"]*[a-zA-Z][^"]*"' "$file" | grep -v 'I18n\.tr')
    
    # Check for JavaScript object properties with hardcoded strings (like in arrays/models)
    js_object_issues=$(grep -n -E '"(label|text|title|description|placeholder|name)":\s*"[^"]*[a-zA-Z][^"]*"' "$file" | grep -v 'I18n\.tr')
    
    if [[ -n "$issues" || -n "$template_issues" || -n "$property_issues" || -n "$js_object_issues" ]]; then
        echo "$file"
        [[ -n "$issues" ]] && echo "$issues"
        [[ -n "$template_issues" ]] && echo "$template_issues"
        [[ -n "$property_issues" ]] && echo "$property_issues"
        [[ -n "$js_object_issues" ]] && echo "$js_object_issues"
        echo
    fi
done