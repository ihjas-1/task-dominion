import os
import fnmatch
import argparse

# --- Configuration ---
DEFAULT_OUTPUT_FILENAME = "project_snapshot.txt"
# Common binary file extensions to skip by default (can be overridden)
DEFAULT_BINARY_EXTENSIONS = {
    # General
    '.png', '.jpg', '.jpeg', '.gif', '.bmp', '.tiff', '.ico',  # Images
    '.mp3', '.wav', '.ogg', '.flac',                           # Audio
    '.mp4', '.avi', '.mov', '.mkv', '.webm',                   # Video
    '.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', # Documents (often binary)
    '.zip', '.tar', '.gz', '.rar', '.7z',                      # Archives
    '.exe', '.dll', '.so', '.dylib', '.app',                   # Executables/Libraries
    '.o', '.a', '.obj', '.lib',                                # Object/static lib
    '.db', '.sqlite', '.sqlite3',                             # Databases
    '.woff', '.woff2', '.ttf', '.otf', '.eot',                 # Fonts
    '.DS_Store',                                              # macOS specific

    # Python specific (less relevant for Flutter but harmless to keep)
    '.pyc', '.pyo',
    '.class','.py',                                                 # Java compiled

    # Flutter/Dart/Mobile specific
    '.aab', '.apk', '.ipa',                                   # App bundles
    '.jar', '.aar',                                           # Java/Android archives
    '.dill', '.kernel',  '.patch','.txt'                                     # Dart compiled outputs
}
# Additional patterns to always ignore, even if not in .gitignore
# These are matched against relative paths from the root_dir
ADDITIONAL_IGNORE_PATTERNS = [
    ".git/",                # Entire .git directory
    ".vscode/",             # VSCode metadata
    ".idea/",               # IntelliJ IDEA metadata
    ".dart_tool/",          # Dart/Flutter tooling artifacts
    "__pycache__/",         # Python cache
    "*.pyc",                # Python compiled files
    "*.pyo",                # Python optimized compiled files
    ".DS_Store",            # macOS specific
    "windows/",
    "macos/",
    "linux/",
    "android/",
    "ios/",
    "ai.txt"
   # The script dynamically adds its own output file to this list later.
    # Note: Rely on project's .gitignore for most build artifacts like 'build/',
    # 'ios/Pods/', 'android/.gradle/' as they can be configured differently.
]

def load_gitignore_patterns(root_dir):
    """Loads patterns from .gitignore file in the root directory."""
    gitignore_path = os.path.join(root_dir, ".gitignore")
    patterns = []
    if os.path.exists(gitignore_path):
        try:
            with open(gitignore_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#"):
                        # If pattern starts with '/', it's relative to .gitignore root.
                        # os.path.relpath gives paths without leading '/', so strip it from pattern too.
                        if line.startswith('/'):
                            patterns.append(line[1:])
                        # elif '**/' in line:
                            # fnmatch doesn't support '**' in the same way as git.
                            # For now, pass it as is; fnmatch will treat '*' literally.
                            # More advanced parsing would be needed for full ** support.
                        else:
                            patterns.append(line)
        except Exception as e:
            print(f"Warning: Could not read or parse .gitignore at {gitignore_path}: {e}")
    return patterns

def should_ignore(path_relative_to_root, gitignore_patterns, additional_patterns, is_dir=False):
    """
    Checks if a given path (relative to project root) should be ignored.
    Uses .gitignore style matching (with fnmatch limitations, e.g., for '**').
    """
    # Normalize path for consistent matching (forward slashes)
    path_to_check = path_relative_to_root.replace(os.sep, "/")

    # For directory patterns ending with '/', path_to_check should also end with '/' for exact match
    path_to_check_for_dir_pattern = path_to_check
    if is_dir and not path_to_check.endswith("/"):
        path_to_check_for_dir_pattern = path_to_check + "/"
    # elif not is_dir and path_to_check.endswith("/"): # Should not happen for files
        # This case implies a file path incorrectly ends with a slash. Normalize it.
        # path_to_check = path_to_check[:-1]


    all_patterns = gitignore_patterns + additional_patterns

    for pattern_orig in all_patterns:
        pattern = pattern_orig # Keep original for some checks if needed, work with 'pattern'

        is_negative = False
        if pattern.startswith("!"):
            is_negative = True
            pattern = pattern[1:]

        # If a pattern is empty after stripping '!', skip it.
        if not pattern:
            continue

        # 1. Pattern specifically targets a directory (ends with /)
        #    e.g., "build/", "dist/", "node_modules/"
        if pattern.endswith("/"):
            # This pattern specifically targets directories.
            # If path_to_check_for_dir_pattern is "build/" and pattern is "build/": fnmatch returns True.
            # If path_to_check_for_dir_pattern is "build/file.txt" and pattern is "build/":
            #   fnmatch("build/file.txt", "build/*") returns True.
            if fnmatch.fnmatch(path_to_check_for_dir_pattern, pattern): # Exact dir match
                return not is_negative
            if fnmatch.fnmatch(path_to_check_for_dir_pattern, pattern + "*"): # Path is *within* this dir pattern
                 return not is_negative
            # For patterns like "foo/" (no leading slash initially) that should match "a/foo/" or "a/b/foo/"
            # This is trickier with fnmatch. Git's logic is more nuanced here.
            # The current logic primarily handles patterns relative to root or simple dir name patterns.
            # A pattern like "node_modules/" from .gitignore (without leading slash) will be treated as relative to root
            # or will rely on other rules if it's a basename match.

        # 2. General pattern (could be file or directory if no trailing /)
        #    e.g., "src/main.c", "*.log", "tempfile", "build" (to match dir 'build' or file 'build')
        #    This rule handles patterns with slashes, or exact matches to the full path.
        elif fnmatch.fnmatch(path_to_check, pattern):
            return not is_negative

        # 3. Pattern without slashes, intended to match basenames anywhere (e.g., "*.pyc", "TODO")
        #    or a directory name anywhere (e.g. "node_modules" pattern matching "any/path/node_modules/")
        elif '/' not in pattern:
            # 3a. Match basename of the path_to_check
            #     e.g., pattern "*.pyc", path "src/file.pyc" -> basename "file.pyc" -> match
            #     e.g., pattern "build", path "foo/build" (dir) -> basename "build" -> match
            if fnmatch.fnmatch(os.path.basename(path_to_check), pattern):
                return not is_negative

            # 3b. Match if path is *inside* a directory whose name matches the pattern.
            #     e.g., pattern "build" (no slash), path "foo/build/file.txt"
            #     dirname is "foo/build". We need to check if "build" segment matches "build" pattern.
            #     This helps ignore contents of directories matched by a simple name pattern.
            if not is_dir: # Only applies if path_to_check is a file
                dirname = os.path.dirname(path_to_check)
                if dirname and dirname != ".": # If the file is in some subdirectory
                    dir_segments = dirname.split('/')
                    # Check if any directory segment in the path matches the pattern
                    # e.g. pattern "node_modules", path "project/sub/node_modules/file.js"
                    #      dir_segments: ["project", "sub", "node_modules"]
                    #      "node_modules" segment matches "node_modules" pattern.
                    for seg in dir_segments:
                        if fnmatch.fnmatch(seg, pattern):
                            return not is_negative
            # If is_dir=True, rule 3a (basename match) would have already caught it if the dir's own name matches.
            # e.g., path "foo/build" (dir), pattern "build". os.path.basename("foo/build") is "build", matches.
    return False # If no pattern matched, don't ignore

def is_likely_binary_file(filepath, binary_extensions):
    """Checks if a file is likely binary based on its extension or content."""
    _, ext = os.path.splitext(filepath)
    if ext.lower() in binary_extensions:
        return True
    try:
        # For small files, read a bit more to be sure. For large files, a smaller sniff is fine.
        # Max 4KB sniff. If file is smaller, read all.
        read_size = min(1024 * 4, os.path.getsize(filepath))
        if read_size == 0: # Empty file
            return False 
        with open(filepath, "rb") as f_bin: # Read as binary to check for null bytes
            chunk = f_bin.read(read_size)
            if b'\0' in chunk: # Presence of null byte is a strong indicator of binary
                return True
        # If no null bytes, try to decode as UTF-8 as a final check
        with open(filepath, "r", encoding="utf-8") as f_text:
            f_text.read(1024) # Try to read a chunk as text
        return False
    except UnicodeDecodeError:
        return True
    except Exception: # Other read errors or if file is very small and consists of non-UTF8 chars
        return True # Assume binary or problematic
    return False


def pack_project(root_dir, output_filename, binary_extensions, additional_ignores_config):
    """Packs all relevant files into a single text file."""
    gitignore_patterns = load_gitignore_patterns(root_dir)
    all_packed_content = []
    
    # Determine absolute path of output file. Resolve root_dir to be absolute first.
    abs_root_dir = os.path.abspath(root_dir)
    output_filepath_abs = os.path.join(abs_root_dir, output_filename)

    # Add the output file itself to dynamic additional ignores to prevent packing itself.
    # This needs to be relative to root_dir for matching.
    # If output_filename contains path separators, use it as is.
    # If root_dir is "." and output is "out/foo.txt", rel_output_path is "out/foo.txt".
    # If root_dir is "src" and output is "foo.txt", output_filepath_abs is ".../src/foo.txt".
    # The matching logic uses paths relative to the walked root_dir.
    rel_output_path_for_ignore = os.path.relpath(output_filepath_abs, abs_root_dir)
    
    dynamic_additional_ignores = list(additional_ignores_config) # Make a mutable copy
    dynamic_additional_ignores.append(rel_output_path_for_ignore.replace(os.sep, "/"))

    files_packed_count = 0
    files_ignored_count = 0
    dirs_ignored_count = 0

    print(f"Starting project pack-up from: {abs_root_dir}")
    print(f"Output will be: {output_filepath_abs}")
    print(f"Ignoring output file pattern: {rel_output_path_for_ignore.replace(os.sep, '/')}")

    for dirpath, dirnames, filenames in os.walk(abs_root_dir, topdown=True):
        # Path of current directory relative to the initial root_dir for should_ignore
        current_walk_dir_rel_to_root = os.path.relpath(dirpath, abs_root_dir)
        if current_walk_dir_rel_to_root == ".": # Avoid "./" prefix for root level itself
            current_walk_dir_rel_to_root = ""


        # Modify dirnames in-place to prevent os.walk from descending into ignored dirs
        original_dirnames_len = len(dirnames)
        dirs_to_remove_from_walk = []
        for dname in dirnames:
            # Construct path relative to root_dir for should_ignore
            dir_rel_path = os.path.join(current_walk_dir_rel_to_root, dname)
            if should_ignore(dir_rel_path, gitignore_patterns, dynamic_additional_ignores, is_dir=True):
                dirs_to_remove_from_walk.append(dname)
        
        if dirs_to_remove_from_walk:
            for dname_to_remove in dirs_to_remove_from_walk:
                dirnames.remove(dname_to_remove)
                # Path for logging should be relative to initial root_dir
                log_path = os.path.join(current_walk_dir_rel_to_root, dname_to_remove)
                print(f"  Ignoring directory (and its contents): {log_path.replace(os.sep, '/')}")
                dirs_ignored_count +=1

        for filename in filenames:
            filepath_abs = os.path.join(dirpath, filename)
            # Path relative to root_dir for should_ignore and for header
            filepath_rel_to_root = os.path.join(current_walk_dir_rel_to_root, filename)

            # This specific check for output_filepath_abs is a safeguard,
            # but dynamic_additional_ignores should also catch it via should_ignore.
            if filepath_abs == output_filepath_abs:
                continue

            if should_ignore(filepath_rel_to_root, gitignore_patterns, dynamic_additional_ignores, is_dir=False):
                print(f"  Ignoring file (rule): {filepath_rel_to_root.replace(os.sep, '/')}")
                files_ignored_count += 1
                continue

            if is_likely_binary_file(filepath_abs, binary_extensions):
                print(f"  Ignoring file (binary): {filepath_rel_to_root.replace(os.sep, '/')}")
                files_ignored_count += 1
                continue

            try:
                with open(filepath_abs, "r", encoding="utf-8", errors="replace") as f_in:
                    content = f_in.read()
                
                header_path = filepath_rel_to_root.replace(os.sep, "/")
                all_packed_content.append(f"--- START OF FILE {header_path} ---")
                all_packed_content.append(content)
                all_packed_content.append(f"--- END OF FILE {header_path} ---\n")
                print(f"  Packing file: {header_path}")
                files_packed_count += 1
            except Exception as e:
                print(f"  Error reading file {filepath_rel_to_root.replace(os.sep, '/')}: {e}")
                # Still add a placeholder for files that couldn't be read
                header_path_err = filepath_rel_to_root.replace(os.sep, "/")
                all_packed_content.append(f"--- START OF FILE {header_path_err} ---")
                all_packed_content.append(f"[Error reading file: {e}]")
                all_packed_content.append(f"--- END OF FILE {header_path_err} ---\n")
                files_ignored_count +=1 # Count as ignored due to error

    try:
        # Ensure parent directory for output file exists if specified like "out/snapshot.txt"
        output_dir = os.path.dirname(output_filepath_abs)
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)

        with open(output_filepath_abs, "w", encoding="utf-8") as f_out:
            f_out.write("\n".join(all_packed_content))
        print(f"\nSuccessfully packed project into: {output_filepath_abs}")
        print(f"  Files packed: {files_packed_count}")
        print(f"  Files ignored/skipped: {files_ignored_count}")
        print(f"  Directories ignored (pruned from walk): {dirs_ignored_count}")

    except Exception as e:
        print(f"\nError writing output file {output_filepath_abs}: {e}")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Pack project files into a single text file, respecting .gitignore and skipping binaries.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument("root_dir", nargs="?", default=".",
                        help="The root directory of the project to pack (default: current directory).")
    parser.add_argument("-o", "--output", default=DEFAULT_OUTPUT_FILENAME,
                        help=f"The name of the output file (default: {DEFAULT_OUTPUT_FILENAME}).\n"
                             "Can be a path relative to root_dir (e.g., 'out/snapshot.txt')\n"
                             "or an absolute path.")
    parser.add_argument("--skip-binary-exts", nargs="*", default=None,
                        help="Space-separated list of binary extensions to skip (e.g., .png .jpg).\n"
                             "Overrides default list if provided. Use 'none' for no extension-based skipping.\n"
                             "Default list includes common image, audio, video, archive, and compiled formats.")
    
    args = parser.parse_args()

    # Determine binary extensions to use
    if args.skip_binary_exts is None: # Use default
        binary_extensions_to_use = DEFAULT_BINARY_EXTENSIONS
    elif args.skip_binary_exts == ['none'] or args.skip_binary_exts == []: # User wants no extension based skipping
        binary_extensions_to_use = set()
    else: # User provided custom list
        binary_extensions_to_use = {ext.lower() if ext.startswith('.') else '.' + ext.lower() for ext in args.skip_binary_exts}

    # Determine the root directory for scanning (make it absolute)
    project_root_dir = os.path.abspath(args.root_dir)

    # Determine the final output filename.
    # If args.output is an absolute path, use it. Otherwise, join with project_root_dir.
    output_file_name_or_path = args.output
    # The pack_project function will handle making it absolute based on the (potentially different) root_dir for walking.
    # For now, we just pass the name/relative path. pack_project takes root_dir and output_filename.
    # If args.output is like "my_snapshot.txt", it will be created IN project_root_dir.
    # If args.output is like "../my_snapshot.txt", it will be created relative to project_root_dir.
    # If args.output is absolute, it will be used as is.
    # The pack_project handles this correctly by joining its `abs_root_dir` with `output_filename`
    # only if output_filename is not absolute.

    pack_project(project_root_dir, output_file_name_or_path, binary_extensions_to_use, ADDITIONAL_IGNORE_PATTERNS)