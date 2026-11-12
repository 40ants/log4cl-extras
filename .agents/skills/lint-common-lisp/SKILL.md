---
name: lint-common-lisp
description: Lint Common Lisp projects with Mallet and 40ants-linter, including missing and unused imports in package-inferred ASDF systems. Use when reviewing, fixing, or verifying `.lisp` and `.asd` files.
---

# Lint Common Lisp

Use Mallet for source-level findings and 40ants-linter for ASDF system checks,
including missing and unused imports in package-inferred systems. Treat both
tools as bug detectors, not reasons for broad formatting changes.

## Workflow

1. Inspect repository instructions and the working tree. Preserve unrelated
   changes. Check for both commands with `command -v mallet` and
   `command -v 40ants-linter`. If the latter is missing, install it with:

   ```sh
   qlot exec ros install 40ants/40ants-linter
   ```
2. Determine the scope before linting. Prefer tracked project files:

   ```sh
   git ls-files -z -- '*.lisp' '*.asd' | xargs -0 mallet --format line
   ```

   For an untracked project, use `rg --files -g '*.lisp' -g '*.asd'` and pass
   only those project paths to Mallet. Exclude vendored code, generated files,
   dependency directories, and build caches unless the user explicitly asks to
   lint them.
3. For each project ASDF system in scope, also run:

   ```sh
   40ants-linter --imports -s <system-name>
   ```

   Find system names in the project's `.asd` files. The command loads the system
   and runs SBLint as well as import checks. Run it from an environment where
   ASDF can discover the project and its dependencies. If an installed command
   cannot find a local system, set `CL_SOURCE_REGISTRY` to include the project
   directory (for example, `CL_SOURCE_REGISTRY="$PWD//:"`) and retry. If there
   is no ASDF system, report that 40ants-linter could not be applied to those
   files; do not imply its import check passed.
4. Record findings from both tools by file, rule or kind, and severity where
   available. Read the surrounding code
   before changing it. Treat warnings about dynamic bindings, macros, ASDF
   names, or package imports as hypotheses; confirm their runtime role first.
5. Fix one logical issue at a time with the smallest semantics-preserving edit.
   Never use `--fix` without previewing its effect with `--fix-dry-run` and
   confirming that bulk edits are in scope.
6. After each changed file, run the repository's relevant test command before
   editing the next file. Prefer documented project commands. When available:

   ```sh
   qlot exec ros -L sbcl-bin run \
     --eval '(ql:quickload :<project>-tests)' \
     --eval '(asdf:test-system :<project>)' \
     --quit
   ```

   For a Rove test system, use its documented `asdf:test-system` command; do
   not substitute a partial compilation check for the full suite unless the
   user requests a narrower verification.
7. Re-run both lint commands on the same scope. Resolve every actionable
   finding. If a rule is a verified false positive, preserve the working code,
   document why, and disable only that rule where the tool supports a narrow
   suppression. Do not silence unrelated rules or claim a clean default run.

## Safety checks

- Do not remove an import, special-variable binding, declaration, or ASDF
  system merely because it appears unused; verify indirect and runtime use.
- Replace runtime `eval`, `read-from-string`, or similar dynamic input paths
  only after tracing the input contract and adding or retaining adequate tests.
- Keep package-inferred ASDF system names consistent with their component
  namespaces; lint conventions must not break ASDF resolution.
- Report both exact lint commands, any scoped suppression, and test evidence.

## Completion criteria

Finish only when both applicable checks are clean, or when every remaining
finding is explicitly documented and accepted by the user (for example, an
intentional test fixture). Include both final lint outputs and the test result
in the handoff.
