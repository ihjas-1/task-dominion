import re
import os

def normalize_whitespace(text):
    """Replaces all sequences of whitespace with a single space and strips."""
    if text is None:
        return ""
    return ' '.join(text.split())

def create_regex_pattern_from_find_text(find_text):
    """
    Creates a regex pattern from the find_text that is tolerant to
    variations in whitespace.
    """
    # Escape regex special characters in the find_text
    escaped_find_text = re.escape(find_text.strip())
    # Replace literal spaces (and other whitespace that became spaces after re.escape)
    # with \s+ to match one or more whitespace characters.
    # This makes it flexible regarding newlines, tabs, multiple spaces.
    whitespace_tolerant_pattern = re.sub(r'\\ ', r'\\s+', escaped_find_text) # Handles escaped spaces
    whitespace_tolerant_pattern = re.sub(r'\s+', r'\\s+', whitespace_tolerant_pattern) # Handles actual whitespace

    # A more robust way for general whitespace, accounting for newlines being part of the find block
    # Split by any whitespace, filter empty strings, escape parts, then join with \s+
    parts = [re.escape(part) for part in re.split(r'\s+', find_text.strip()) if part]
    if not parts:
        return r'' # Avoid creating 's+' from empty find text
    return r'\s+'.join(parts)


def apply_patch(patch_file_path):
    if not os.path.exists(patch_file_path):
        print(f"Error: Patch file '{patch_file_path}' not found.")
        return

    with open(patch_file_path, 'r', encoding='utf-8') as f:
        patch_content = f.readlines()

    current_file_path = None
    current_file_content_lines = []
    original_file_content_str = ""

    find_block = []
    replace_block = []
    in_find_block = False
    in_replace_block = False
    changes_applied_to_current_file = False

    line_number = 0

    def process_file_changes(file_path, original_content, find_ops):
        nonlocal changes_applied_to_current_file
        modified_content = original_content
        operation_count = 0
        for i, (find_str, replace_str) in enumerate(find_ops):
            if not find_str.strip(): # Skip if find_str is only whitespace
                print(f"  Skipping empty find block for operation {i+1} in {file_path}")
                continue

            # Create a whitespace-tolerant regex pattern from the find_str
            pattern_str = create_regex_pattern_from_find_text(find_str)
            try:
                pattern = re.compile(pattern_str, re.DOTALL) # DOTALL so . matches newlines
            except re.error as e:
                print(f"  Error compiling regex for find block in {file_path} (operation {i+1}): {e}")
                print(f"  Pattern was: {pattern_str}")
                print(f"  Original find_str: '{find_str[:100]}...'")
                continue

            # Perform the replacement
            new_content, num_replacements = pattern.subn(replace_str, modified_content, count=1)

            if num_replacements > 0:
                modified_content = new_content
                print(f"  Applied change {i+1} in '{file_path}'.")
                operation_count +=1
                changes_applied_to_current_file = True
            else:
                print(f"  Warning: Pattern for change {i+1} not found in '{file_path}'.")
                print(f"    Expected to find (normalized): '{normalize_whitespace(find_str)[:100]}...'")
                print(f"    Regex pattern used: '{pattern_str[:100]}...'")
                # For debugging, you can print parts of the file content
                # print(f"    File content (normalized, first 200 chars): '{normalize_whitespace(modified_content)[:200]}...'")


        if changes_applied_to_current_file and operation_count > 0:
            try:
                with open(file_path, 'w', encoding='utf-8') as wf:
                    wf.write(modified_content)
                print(f"Successfully patched '{file_path}'.")
            except IOError as e:
                print(f"Error writing to file '{file_path}': {e}")
        elif operation_count == 0 and find_ops: # find_ops was not empty, but no changes made
             print(f"No changes applied to '{file_path}' as no patterns were matched.")
        # If no find_ops for the file, nothing to print here.

    file_operations = []

    for i, line_content in enumerate(patch_content):
        line_number = i + 1 # For error reporting in patch file
        stripped_line = line_content.strip()

        if stripped_line.startswith("--- START OF FILE "):
            if current_file_path and file_operations:
                process_file_changes(current_file_path, original_file_content_str, file_operations)
                file_operations = []
                changes_applied_to_current_file = False

            current_file_path = stripped_line.split("--- START OF FILE ", 1)[1].split(" ---", 1)[0]
            if not os.path.exists(current_file_path):
                print(f"Warning: Target file '{current_file_path}' not found. Skipping.")
                current_file_path = None # Skip this file block
                continue
            try:
                with open(current_file_path, 'r', encoding='utf-8') as cf:
                    original_file_content_str = cf.read()
                print(f"\nProcessing file: {current_file_path}")
            except IOError as e:
                print(f"Error reading file '{current_file_path}': {e}. Skipping.")
                current_file_path = None
            continue

        if current_file_path is None: # If target file was skipped
            continue

        if stripped_line == "@@ -FIND- @@":
            in_find_block = True
            in_replace_block = False
            find_block = []
            continue
        elif stripped_line == "@@ +REPLACE+ @@":
            in_find_block = False
            in_replace_block = True
            replace_block = []
            continue
        elif stripped_line == "@@ -END OF BLOCK- @@":
            if find_block or replace_block: # Only process if there's something
                file_operations.append(("".join(find_block), "".join(replace_block)))
            find_block = []
            replace_block = []
            in_find_block = False
            in_replace_block = False
            continue
        elif stripped_line.startswith("--- END OF FILE "):
            if current_file_path and file_operations: # Process any pending operations for the file
                process_file_changes(current_file_path, original_file_content_str, file_operations)
            current_file_path = None
            original_file_content_str = ""
            file_operations = []
            changes_applied_to_current_file = False
            continue

        if in_find_block:
            find_block.append(line_content)
        elif in_replace_block:
            replace_block.append(line_content)

    # Process the last file if patch doesn't end with END OF FILE
    if current_file_path and file_operations:
        process_file_changes(current_file_path, original_file_content_str, file_operations)

if __name__ == "__main__":
    patch_file = "patch.txt" # Or make it a command-line argument
    apply_patch(patch_file)