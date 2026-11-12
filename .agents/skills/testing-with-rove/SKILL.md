---
name: testing-with-rove
description: Load before adding, changing, or running Common Lisp Rove DEFTEST tests, including one small test, a signals assertion, a single REPL test run, or ASDF test-op wiring. Explains condition assertions, test discovery, and failure exit status.
---

# Testing with Rove

## Overview
Rove uses `ok` to record assertions. Its `signals` predicate takes the form first
and the condition type second; wrap that predicate in `ok`.

## When to Use
- Writing a new test or `deftest`
- A `signals` test passes or fails for the wrong reason
- Wiring an ASDF `test-op`, or running a single test from the REPL

## The `signals` signature (read this first)
```lisp
(defmacro signals (form &optional (condition ''error)))
```
**The form under test is the FIRST argument; the condition type is the OPTIONAL SECOND (defaults to `'error`).**
`signals` returns a boolean; a bare call does not record a Rove assertion.

```lisp
;; CORRECT — (do-thing) is evaluated, expected to signal my-error
(ok (signals (do-thing) 'my-error))
(ok (signals (do-thing)))             ; defaults to 'error

;; WRONG — 'my-error becomes the form (never signals); (do-thing) is read as the type
(ok (signals 'my-error (do-thing)))
```
Reversing the arguments does not test the intended call. Use the specific condition
type when an unrelated error must not count as success.

## Running tests
```lisp
(asdf:test-system :myapp-test)                                ; whole system
(rove:run :myapp-test/models/foo)                            ; one module
(rove:run-test 'myapp-test/models/foo::adding-foo)      ; one test
```

### Connect Rove to ASDF without losing failures

Keep the project's existing system layout. For package-inferred systems, connect
the main system's existing definition to its test system with:

```lisp
;; A property inside the existing MYAPP system definition:
:in-order-to ((asdf:test-op (asdf:test-op "myapp-tests")))
```

A separate test system can load inferred test modules and propagate Rove's result:

```lisp
(asdf:defsystem "myapp-tests"
  :class :package-inferred-system
  :pathname "tests"
  :depends-on ("myapp" "myapp-tests/core-test")
  :perform (asdf:test-op (operation system)
             (declare (ignore operation))
             (unless (uiop:symbol-call :rove :run system)
               (error "Rove tests failed for ~A" (asdf:component-name system)))))
```

The package in `tests/core-test.lisp` is `myapp-tests/core-test`; declare Rove and
source-package imports there with `uiop:define-package`. Keep each `deftest`
registered in its test package. For an existing non-inferred test system, retain
its component list and use the same failure propagation in its test-op.

ASDF does not treat a returned `nil` as an error: explicitly signal an error when
`rove:run` returns false. Verify through the real command:

```bash
qlot exec sbcl --non-interactive --eval '(asdf:test-system "myapp")'
```

Confirm that the intended tests actually ran. A report of `0 tests completed`
does not validate newly added tests. A deliberately broken implementation must
make the test command exit nonzero; a dependency/load failure is a different
problem and does not prove the assertions caught that broken behavior.

### Capturing per-assertion output from the REPL
`rove:run-test` prints its report to `*standard-output*` and returns a different value. Wrap it to see the per-assertion output:
```lisp
(with-output-to-string (*standard-output*)
  (rove:run-test 'myapp-test/models/foo::adding-foo))
```

## Test file conventions
- Tests live in `tests/` mirroring `src/`, named `*-test.lisp`.
- Structure: `(deftest <unit> ... (testing "<aspect>" ...))`. Preserve an explicitly requested test name: `rove:run-test` resolves the exact `deftest` symbol; prepending `test-` creates a different test.
- Keep test names local to the test package. If a test has the same name as a source function, declare an empty source-package import and call that function with its package prefix instead of importing its name into the test package.
- Add brand-new test files to the test system's ASDF components when not auto-inferred.
- Write the failing test before the implementation.

## Resetting global state safely
If the code under test uses `global-vars:define-global-var`, do **not** try to rebind it with `let`. Save the old value, `setf` the test value, and restore it with `unwind-protect`:
```lisp
(let ((old-value *some-global*))
  (unwind-protect
       (progn
         (setf *some-global* :test-value)
         ...)
    (setf *some-global* old-value)))
```
This matters for logging/configuration code where tests need temporary global hooks or appenders.

## Reloading tests in a live image
After editing a test file in the REPL workflow, force just that test file instead of recompiling the whole system:
```lisp
(asdf:load-system "myapp-tests" :force '("myapp-tests/core"))
```

## Strict schema and CLOS regression check
For a changed CLOS class or schema class, add a test that constructs every
optional-slot combination relevant to the public constructor, especially the
case where the argument is omitted. Then run the complete suite after the
strict compilation check from **using-common-lisp-repl**; this catches a slot
whose `:initform` does not satisfy its declared CLOS type.

## Testing internal (`%`-prefixed) functions
A `%` prefix is a naming convention, not an access restriction. Tests can refer
to an unexported symbol as `myapp/foo::%helper`; use an empty
`(:import-from #:myapp/foo)` clause to declare that package dependency in an
inferred test module. Preserve the project's API boundary rather than exporting
a private helper solely to make single-colon syntax work.

If the project deliberately exports internal helpers for tests, follow that
convention with an explicit import.

## Common Mistakes
| Symptom | Fix |
|---|---|
| `(ok (signals 'my-error (do-thing)))` — test passes/fails for the wrong reason | Use `(ok (signals (do-thing) 'my-error))` — form first, type second |
| `LET` on a `define-global-var` global fails or behaves strangely | Use `setf` + `unwind-protect`, not dynamic rebinding |
| `rove:run-test` output not visible | Wrap in `(with-output-to-string (*standard-output*) ...)` |
| Cannot reference `%helper` from tests | Use `myapp/foo::%helper` and declare the source package dependency; follow explicit project export conventions |
| New test file not picked up | Add it to the test system's ASDF components |

## Related skills
For running these from a live image: **using-common-lisp-repl**. For test-code style: **writing-common-lisp**.
