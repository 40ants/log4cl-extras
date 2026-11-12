#!/bin/bash
#
# clear-fasl-cache.sh — Remove stale ASDF fasl caches for a Common Lisp project.
#
# Usage:
#   ./clear-fasl-cache.sh                          # uses current directory
#   ./clear-fasl-cache.sh /path/to/project          # explicit path
#
# The script removes all fasl cache directories under
# ~/.cache/common-lisp/sbcl-*/ that match the given project path.

set -euo pipefail

PROJECT_DIR="${1:-$(pwd)}"

# Resolve to absolute path
PROJECT_DIR="$(cd "$PROJECT_DIR" 2>/dev/null && pwd)" || {
    echo "ERROR: Cannot resolve path: $PROJECT_DIR" >&2
    exit 1
}

if [ "$PROJECT_DIR" = / ]; then
    echo "ERROR: A project directory must not be the filesystem root" >&2
    exit 1
fi

CACHE_BASE="$HOME/.cache/common-lisp"
# Arrays preserve spaces and expand the implementation glob without splitting
# project names. A literal unmatched glob is omitted.
shopt -s nullglob
MATCHES=("$CACHE_BASE"/sbcl-*/"${PROJECT_DIR#/}")
if [ "${#MATCHES[@]}" -eq 0 ]; then
    echo "No fasl cache found for: $PROJECT_DIR"
    exit 0
fi

for dir in "${MATCHES[@]}"; do
    if [ -L "$dir" ]; then
        echo "ERROR: Refusing symbolic-link cache target: $dir" >&2
        exit 1
    fi
    rm -rf -- "$dir"
    echo "Removed: $dir"
done

echo "Done. Rebuild with your tool to recompile from source."
