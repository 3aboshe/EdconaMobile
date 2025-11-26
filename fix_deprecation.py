#!/usr/bin/env python3
import os
import re

def fix_with_opacity_in_file(file_path):
    """Replace withOpacity with withValues in a single file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Replace pattern: .withOpacity(value) with .withValues(alpha: value)
        original_content = content
        content = re.sub(r'\.withOpacity\(([^)]+)\)', r'.withValues(alpha: \1)', content)
        
        # Only write if changes were made
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        return False
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    lib_dir = 'lib'
    total_files = 0
    modified_files = 0
    
    print("Fixing deprecated .withOpacity() usage in Dart files...")
    
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                total_files += 1
                file_path = os.path.join(root, file)
                if fix_with_opacity_in_file(file_path):
                    modified_files += 1
                    print(f"  ✓ Fixed: {file_path}")
    
    print(f"\nSummary:")
    print(f"  Total Dart files scanned: {total_files}")
    print(f"  Files modified: {modified_files}")
    print(f"  Files unchanged: {total_files - modified_files}")

if __name__ == "__main__":
    main()
