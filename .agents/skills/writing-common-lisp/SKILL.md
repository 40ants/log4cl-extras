---
name: writing-common-lisp
description: Use when creating or editing Common Lisp source files (.lisp/.asd) — setting up packages, declaring function types, choosing iteration/control-flow/condition constructs, or applying naming and formatting conventions in a Common Lisp project.
---

# Writing Common Lisp

## Overview
Conventions for new `.lisp`/`.asd` source in **package-inferred ASDF systems**: package definition, type declarations, control flow, conditions, and formatting. Apply across all CL projects in this workspace.

## When to Use
- Creating a new `.lisp` file or a `defpackage`/`uiop:define-package` form
- Adding a function, generic function, method, or condition to an existing file
- Reviewing CL code for style consistency

**When NOT to use:** a project's own `AGENTS.md`/`ai/cl-style.md` may override these — read it first. Never edit files under `.qlot/` (third-party dependencies).

## Package definition (package-inferred systems)
Each file is its own package, named after its full filesystem path:
`src/models/foo.lisp` under system `myapp` → package `myapp/src/models/foo`.

```lisp
(uiop:define-package #:myapp/src/models/foo
  (:use #:cl)
  (:import-from #:serapeum
                #:->
                #:dict)
  (:export #:bar))
(in-package #:myapp/src/models/foo)
```

Rules:
- `uiop:define-package`, **not** `defpackage`.
- Package name **must match every path segment** including `src/` (most common baseline mistake: dropping it).
- `#:` prefix on every package and symbol name.
- `(:use #:cl)` only. For external libraries, **prefer `:local-nicknames` or targeted `:import-from`** — never `(:use #:some-lib)`, which floods your namespace and causes symbol clashes.
- Explicit `:export`; do not export internals.

`:local-nicknames` form:
```lisp
(:local-nicknames (#:ser #:serapeum))
```

## File layout
`;;;;` file comment → `(in-package ...)` as the **first executable form** → optional file-specific `declaim` → definitions. One blank line between top-level forms.

## Commands and verification
Run every shell command for this skill through `qlot exec` from the project
directory, including source inspection, Lisp, builds, tests and linters.
For pipelines, wrap the whole command: `qlot exec sh -c '...'`, and keep
`qlot exec` on Lisp invocations inside it as well. Use the
project's existing Qlot environment; do not search personal Quicklisp trees
or `/nix/store`, or create a new dependency installation.

Verify a standalone file by loading its dependencies and then the file:

```sh
qlot exec sbcl --non-interactive \
  --eval '(asdf:load-system "serapeum")' \
  --load path/to/module.lisp
```

When the task concerns an existing ASDF project, use its actual system and
entry point. A package-inferred root system loads only its declared
dependencies; loading the root does not load every module. Do not create
ASDF scaffolding merely to verify a standalone source file.

## Types
Every newly added function **must have a `serapeum:->` signature**, including
non-exported helper functions. Place the signature immediately before its
`defun`; for a generic function, place it before `defgeneric` so its methods
share the declared contract. Describe all argument types and returned values.
Put the return-value type on a separate line, indented by four spaces, even for
short signatures.

```lisp
(serapeum:-> bar (number)
    (values number &optional))
(defun bar (x)
  "Return twice X."
  (* 2 x))
```

Use the fully qualified `serapeum:->`, or `->` with an explicit
`(:import-from #:serapeum #:->)` in the package definition. A raw
`(declaim (ftype ...))`, parameter `(declare (type ...))` forms, inferred types,
and type descriptions in docstrings do **not** satisfy this convention.

Write each signature and its function together, rather than adding signatures
as a final cleanup. Declare the Serapeum dependency in `uiop:define-package`
with `(:import-from #:serapeum #:->)` even when calling `serapeum:->` by its
full name: package-inferred ASDF uses package dependencies to load libraries.

"Do not install dependencies" prohibits downloading or installing libraries;
it does not prohibit loading a library already provisioned by the project.
An empty source directory or `(find-package :serapeum)` returning `nil` does
not establish that Serapeum is unavailable: a fresh image has not loaded its
packages yet. Use `qlot exec sbcl` (or `qlot exec ros`) from the project,
then check `(asdf:find-system "serapeum" nil)` and load the
available system with `(asdf:load-system "serapeum")` before loading the new
source. This needs no new `.asd` file and no dependency installation. Keep
this bootstrap in the verification command, not in the source module.

If Serapeum really cannot be found after the project bootstrap, report the
missing prerequisite instead of silently replacing `->` with `declaim`,
omitting the signature, or defining a substitute macro. Preserve explicit
project overrides from `AGENTS.md` or `ai/cl-style.md` as described above.

Before finishing, inspect the actual source: every added function must have
its adjacent `->` signature, a return-value form on its own four-space-indented
line, and an explicit Serapeum package dependency. Verify loading with the
project's installed dependencies. Use `(declare (ignore var))` for unused
parameters.

## Control flow and iteration
- `loop` **without** keyword style — write `(loop for x in list while (...) do ...)`; do **not** use `:for`, `:do`, `:while`.
- `ecase` / `etypecase` for exhaustive dispatch; the error form uses `format`: `(ecase kind (... ...))`.

## Conditions and errors
```lisp
(define-condition my-error (error)
  ((reason :initarg :reason :reader my-error-reason))
  (:report (lambda (c s) (format s "My error: ~A" (my-error-reason c)))))
```
- `(error "format ~A" val)` with arguments — never a bare literal string.
- Prefer restarts over `signal`. **Never** runtime `eval`, `intern`, or `unintern`.

## Formatting
Google Common Lisp Style Guide: 2-space indent, ≤100 columns, no tabs, lower-case `lisp-case`. Predicates end in `-p`; specials are `*earmuffs*`; constants are `+plus+`. Docstrings are required on public APIs.

For exported variables and public extension points, the docstring should state the behavioral contract, not just the type. If a public hook list ignores non-funcallable elements, say so explicitly in the variable docstring.

## Common Mistakes
| Symptom | Fix |
|---|---|
| `defpackage` used | Switch to `uiop:define-package` |
| Package name misses a path segment (e.g. `myapp/models/foo` for file `src/models/foo.lisp`) | Include every segment: `myapp/src/models/foo` |
| `(:use #:serapeum)` or `(:use #:some-lib)` | Replace with `:local-nicknames` or `:import-from` of only the symbols used |
| Keyword-style `loop` (`:for`, `:do`, `:while`) | Drop the keywords: `(loop for x ... while ... do ...)` |
| New function has no `serapeum:->`, or only a raw `declaim`/parameter type declaration | Add its `serapeum:->` signature immediately before the definition, including for internal helpers |
| `(error "boom")` bare string | `(error "boom: ~A" val)` with format args |
| Exported variable lacks a docstring or behavior contract | Add a docstring describing semantics, especially for hooks/configuration variables |

## Related skills
For CLOS classes and constructors: **defining-clos-classes**. For subtle language gotchas when writing new or large code: **avoiding-common-lisp-pitfalls**. For interactive reload after edits: **using-common-lisp-repl**.
