---
name: clearing-asdf-fasl-cache
description: Use when ASDF fasl cache is stale and build tools (build-docs, qlot exec sbcl, etc.) do not pick up source changes — typically after modifying docstrings, adding defgeneric forms, or renaming exported symbols. Apply when recompilation shows no effect or warnings persist after source fixes.
---

# Clearing ASDF Fasl Cache

## Overview

ASDF compiles `.lisp` sources to `.fasl` (Fast-Load) files and caches them in `~/.cache/common-lisp/`. When source files change but tools use stale fasls, changes appear to have no effect. The fix is to delete the cache for the project using the `clear-fasl-cache.sh` script.

## When to Use

- Modified docstrings but `build-docs` still reports them as undocumented
- Added `defgeneric` forms but "No source location found" warnings persist
- Renamed or re-exported symbols but old names still referenced
- Build tools use a different SBCL image (standalone ros binary vs `qlot exec sbcl`)
- ASDF does not detect source changes after git operations (checkout, rebase)

## Identify the cache to clear

Use the project's configured ASDF output translations. `~/.cache/common-lisp/`
is only the default; an explicit project cache root takes precedence. Keep HOME
unchanged. If the task already supplies the target cache paths, use that inventory
rather than investigating the contents or trying to load stale fasls.

Remove **only entries belonging to the requested project**, across implementation
versions and architectures. Paths belonging to other projects are a preservation
list, never additional cleanup targets. Do not clear an entire implementation
cache or shared cache root. Quote each path, including paths containing spaces.
A missing target cache is a successful no-op; do not create or rebuild it unless
requested.

## Clear and verify

Run shell commands through `qlot exec` in the project environment.

For the default layout, use the bundled `clear-fasl-cache.sh` from the actual
skill directory reported by the agent's skill loader:

```sh
qlot exec bash /actual/skill/directory/clear-fasl-cache.sh /path/to/project
```

The helper assumes the default cache root. For custom output translations,
read the helper, then adapt the **target paths**, rather than changing HOME or
creating a general replacement script. For example, when two exact stale files
have been identified:

```sh
qlot exec rm -f -- 'cache/implementation-a/target/file.fasl' 'cache/implementation-b/target/file.fasl'
```

Use the supplied paths, not these example names. Check that the target entries
are gone and other projects' entries remain unchanged. Rebuild only when asked:
configure the requested output translations in the same Lisp process that calls
`asdf:load-system` with force, then check the requested program value. Successful
output is sufficient; do not investigate unrelated installed implementations,
inspect every environment variable, or repeat builds without a failure to resolve.
Keep project sources unchanged during cache maintenance.
