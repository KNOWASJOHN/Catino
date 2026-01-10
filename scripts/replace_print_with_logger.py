#!/usr/bin/env python3
"""
Script to replace all print statements with logger in Dart files.
This script will:
1. Find all .dart files in lib/ directory
2. Add logger import if not present
3. Replace all print() calls with appropriate logger calls
"""

import os
import re
from pathlib import Path

# Base directory
LIB_DIR = r"e:\test\flutter_application_1\lib"

# Files to skip (these have print for output purposes or are already processed)
SKIP_FILES = {
    "utils/logger_config.dart",  # Contains print for output
}

def should_process_file(filepath):
    """Check if file should be processed"""
    rel_path = filepath.relative_to(LIB_DIR)
    return str(rel_path).replace("\\", "/") not in SKIP_FILES

def has_print_statements(content):
    """Check if file has print statements"""
    return "print(" in content

def has_logger_import(content):
    """Check if file has logger import"""
    return "import '../utils/logger_config.dart'" in content or "import '../../utils/logger_config.dart'" in content

def get_logger_import_path(filepath):
    """Get the correct relative import path for logger_config"""
    rel_path = filepath.relative_to(LIB_DIR)
    depth = len(rel_path.parts) - 1
    if depth == 0:
        return "import 'utils/logger_config.dart';"
    else:
        return f"import '{'../' * depth}utils/logger_config.dart';"

def get_logger_name(filepath):
    """Get logger name from file path"""
    return filepath.stem.replace("_", " ").title().replace(" ", "")

def add_logger_import_and_instance(content, filepath):
    """Add logger import and create logger instance"""
    if has_logger_import(content):
        return content
    
    import_path = get_logger_import_path(filepath)
    logger_name = get_logger_name(filepath)
    logger_instance = f"\nfinal _logger = AppLogger.getLogger('{logger_name}');\n"
    
    # Find the last import statement
    lines = content.split('\n')
    last_import_idx = -1
    for i, line in enumerate(lines):
        if line.strip().startswith('import '):
            last_import_idx = i
            
    if last_import_idx >= 0:
        lines.insert(last_import_idx + 1, import_path)
        lines.insert(last_import_idx + 2, logger_instance[1:])  # Remove leading newline
        return '\n'.join(lines)
    else:
        # No imports found, add at the beginning
        return import_path + logger_instance + content

def replace_print_with_logger(content):
    """Replace print statements with logger calls"""
    # Pattern to match print statements
    # This is a simple replacement - real implementation would need better parsing
    
    # Replace print with logger based on context
    # Errors -> logger.severe
    content = re.sub(
        r'''print\(['"](Error|❌|⚠️)([^'"]*):\s*\$([^'"]*)['"]\);''',
        r"_logger.severe('\2', \3);",
        content
    )
    
    content = re.sub(
        r'''print\(['"](Error|❌)([^'"]*)['"]\);''',
        r"_logger.warning('\2');",
        content
    )
    
    # Info messages
    content = re.sub(
        r'''print\(['"]([^'"]*)['"]\);''',
        r"_logger.info('\1');",
        content
    )
    
    return content

def process_file(filepath):
    """Process a single file"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        if not has_print_statements(content):
            return False
        
        print(f"Processing: {filepath.relative_to(LIB_DIR)}")
        
        # Add logger import and instance if needed
        content = add_logger_import_and_instance(content, filepath)
        
        # Replace print statements
        content = replace_print_with_logger(content)
        
        # Write back
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        
        return True
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return False

def main():
    """Main function"""
    lib_path = Path(LIB_DIR)
    dart_files = list(lib_path.rglob("*.dart"))
    
    processed = 0
    for filepath in dart_files:
        if should_process_file(filepath):
            if process_file(filepath):
                processed += 1
    
    print(f"\nProcessed {processed} files")

if __name__ == "__main__":
    main()
