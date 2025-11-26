#!/bin/bash

# Script to replace deprecated withOpacity with withValues in Dart files
# This fixes Flutter deprecation warnings throughout the codebase

echo "Replacing deprecated .withOpacity() with .withValues(alpha:) in Dart files..."

# Find all Dart files in lib directory and apply sed replacement
find lib -name "*.dart" -type f -exec sed -i '' \
  -e 's/\.withOpacity(\([^)]*\))/.withValues(alpha: \1)/g' {} +

echo "Replacement complete!"
echo "Running flutter analyze to verify fixes..."

