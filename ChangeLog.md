<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-40CHANGELOG-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

# ChangeLog

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E11-2E1-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.11.1 (2025-10-05)

<a id="fixed"></a>

### Fixed

Previously you may encounter this sort of errors when trying to get a backtrace or use [`log4cl-extras/error:with-log-unhandled`][3fd6] macro:

```
Traceback (most recent call last):n[unable to format because of Unable to get traceback because of another error during printing:n#<PRINT-NOT-READABLE {1213990E43}> cannot be printed readably."},"level":"ERROR","message":"Unhandled exception","timestamp":"2025-10-05T16:23:40.869358Z"
```
This error occured when `*print-readably*` variable was bound to `T`.

Now [`log4cl-extras/error:print-backtrace`][6a57] function binds `*print-readably*` to `NIL` when rendering a backtrace. This might change how do your backtraces look like.

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E11-2E0-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.11.0 (2024-03-01)

<a id="changed"></a>

### Changed

Macro [`log4cl-extras/error:with-log-unhandled`][3fd6] now handles `SERIOUS-CONDITION` instead of `ERROR`. This is important, because `ERROR` is not a only subclass of the `SERIOUS-CONDITION`, for example, `SB-EXT:TIMEOUT` is inherited directly from `SERIOUS-CONDITION` and old version of the macro was not able to log such errors.

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E10-2E0-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.10.0 (2023-11-19)

<a id="new"></a>

### New

Variable [`log4cl-extras/appenders:*debug-on-error*`][8400] was added and can be used to debug issues happening when handling log messages.
When this option is `NIL`, appenders defined in log4cl-extras will only output "Unable to log the message" message in case of errors
during the message output.

<a id="fixes"></a>

### Fixes

* Package log4cl-extras now is created when library is loaded. This should fix a warning from `ASDF` about missing package.

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E9-2E0-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.9.0 (2022-12-30)

Function [`log4cl-extras/error:print-backtrace`][6a57] now prints conditions with type like:

```
Condition REBLOCKS-WEBSOCKET:NO-ACTIVE-WEBSOCKETS: No active websockets bound to the current page.
```
instead of:

Condition: No active websockets bound to the current page.

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E8-2E0-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.8.0 (2022-11-04)

* Macro [`log4cl-extras/error:with-log-unhandled`][3fd6] now has `ERRORS-TO-IGNORE` argument.
You can pass a list of class-names of conditions which should not be logged.

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E7-2E2-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.7.2 (2022-10-03)

* Backtrace printer was fixed to work on Clozure`CL`.

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E7-2E1-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.7.1 (2022-08-06)

* Now [`log4cl-extras/secrets:make-secrets-replacer`][bb11] is able to mask secret values even in strings nested in the lists.
  This fixes issue of leaking Authorization tokens when some `HTTP` error is logged.
Previously, backtrace was logged like this:
```
1 File "/Users/art/projects/lisp/cloud-analyzer/.qlot/dists/ultralisp/software/fukamachi-dexador-20220619102143/src/backend/usocket.lisp", line 451
    In DEXADOR.BACKEND.USOCKET:REQUEST
  Args (#<unavailable argument> :METHOD :GET :HEADERS (("Authorization" . "OAuth AQAEA5qgMKaqAAffdZ0Nw7BqTkCTlp6ii80Gdmo")))
```
and oauth token leaked to the log storage.
After this fix, backtrace will be logged like this:
```
1 File "/Users/art/projects/lisp/cloud-analyzer/.qlot/dists/ultralisp/software/fukamachi-dexador-20220619102143/src/backend/usocket.lisp", line 451
    In DEXADOR.BACKEND.USOCKET:REQUEST
  Args (#<unavailable argument> :METHOD :GET :HEADERS (("Authorization" . "OAuth #<secret value>")))
```
* A new variable [`log4cl-extras/error:*args-filter-constructors*`][5c08] was introduced. It should be used together
  with [`log4cl-extras/secrets:make-secrets-replacer`][bb11] to prevent secrets collection during the program life.
Previosly, when you created a secrets replaced and stored in in the [`log4cl-extras/error:*args-filters*`][c7a0] variable,
all secrets from logged backtraces were collected in a closure's state. When
[`log4cl-extras/error:*args-filter-constructors*`][5c08] variable is used, a new secrets replacer will be created
for processing of each backtrace.

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E7-2E0-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.7.0 (2022-07-03)

* Macro [`log4cl-extras/error:with-log-unhandled`][3fd6] now uses internal function and you can change backtrace length on the fly by changing [`log4cl-extras/error:*max-traceback-depth*`][c93b] variable.
* Also, [`log4cl-extras/error:*max-call-length*`][6d41] variable was documented.

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E6-2E0-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.6.0 (2021-10-03)

* Now `:PLAIN` and `:JSON` logger will output logger's category, filename and a callable name.

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E5-2E1-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.5.1 (2021-03-02)

* Fixed fail during logging error with `(setf some-func)` in the backtrace.

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E5-2E0-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.5.0 (2021-01-24)

* Function `TRACEBACK-TO-STRING` was removed and
  replaced with [`log4cl-extras/error:print-backtrace`][6a57] which is now
  a part of public `API`.
* Added ability to filter secret and sensitive values.
  Read documentation, to lear more.

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E4-2E2-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.4.2 (2020-11-26)

<a id="fixed"></a>

### Fixed

* Fixed [`with-log-unhandled`][3fd6] for cases when some function argument's print-object signaled the error.

Because of this nasty error, sometimes [`with-log-unhandled`][3fd6] didn't log "Unandled error".

<a id="added"></a>

### Added

* Now [`log4cl-extras/error:with-log-unhandled`][3fd6] macro accepts key argument `DEPTH` which is 10 by default.

This argument can be overriden by setting [`log4cl-extras/error:*max-traceback-depth*`][c93b].

* Also another variable [`log4cl-extras/error:*max-call-length*`][6d41] can be set to control
  how long function or method name can be. By default it is 100, but methods are logged along
  with their specialized arguments and can be longer.

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E4-2E1-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.4.1 (2019-03-05)

<a id="fixed"></a>

### Fixed

* Added missing dependency from `CL-STRINGS` system.

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E4-2E0-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.4.0 (2019-03-04)

<a id="improved"></a>

### Improved

Now [`log4cl-extras/config:setup`][74de] sets appender into a mode when it prints log in a human
readable way if it its called from the `SLY`'s `REPL`. All logger fields are
printed as well, including a traceback.

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E3-2E0-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.3.0 (2019-01-07)

<a id="improved"></a>

### Improved

* Now condition's description is added to the end of the backtrace.

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E2-2E2-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.2.2 (2018-12-08)

<a id="fixed"></a>

### Fixed

* Fixed system's loading in environments with `C` locale.

This closes issue reported along with pull request #1.

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E2-2E1-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.2.1 (2018-11-24)

<a id="fixed"></a>

### Fixed

* Previously, macros [`log4cl-extras/error:with-log-unhandled`][3fd6] catched every signal,
  not only signals derived from `ERROR`. Because of that,
  it logged traceback for non error signals like that:

`lisp
  (log4cl-json/error:with-log-unhandled ()
      (signal "foo"))
`

Now this bad behavior was fixed and only `errors` are logged.

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E2-2E0-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.2.0 (2017-08-29)

<a id="new"></a>

### New

* Added ability to log tracebacks using [`log4cl-extras/error:with-log-unhandled`][3fd6].

<a id="x-28LOG4CL-EXTRAS-2FCHANGELOG-3A-3A-7C0-2E1-2E0-7C-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## 0.1.0 (2017-01-23)

* Initial version.


[8400]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FAPPENDERS-3A-2ADEBUG-ON-ERROR-2A-20-28VARIABLE-29-29
[74de]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FCONFIG-3ASETUP-20FUNCTION-29
[5c08]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FERROR-3A-2AARGS-FILTER-CONSTRUCTORS-2A-20-28VARIABLE-29-29
[c7a0]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FERROR-3A-2AARGS-FILTERS-2A-20-28VARIABLE-29-29
[6d41]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FERROR-3A-2AMAX-CALL-LENGTH-2A-20-28VARIABLE-29-29
[c93b]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FERROR-3A-2AMAX-TRACEBACK-DEPTH-2A-20-28VARIABLE-29-29
[6a57]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FERROR-3APRINT-BACKTRACE-20FUNCTION-29
[3fd6]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FERROR-3AWITH-LOG-UNHANDLED-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29
[bb11]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FSECRETS-3AMAKE-SECRETS-REPLACER-20FUNCTION-29

* * *
###### [generated by [40ANTS-DOC](https://40ants.com/doc/)]
