===========
 Changelog
===========

0.5.0 (2021-01-24)
==================

* Function ``traceback-to-string`` was removed and
  replaced with ``print-backtrace`` which is now
  a part of public API.
* Added ability to filter secret and sensitive values.
  Read documentation, to lear more.

0.4.2 (2020-11-26)
==================

Fixed
-----

* Fixed ``with-log-unhandled`` for cases when some function argument's print-object signaled the error.

  Because of this nasty error, sometimes ``with-log-unhandled`` didn't log "Unandled error".


Added
-----

* Now ``with-log-undandled`` accepts key argument ``:depth`` which is 10 by default.

  This argument can be overriden by setting ``log4cl-extras/error:*max-traceback-depth*``.

* Also another variable ``log4cl-extras/error:*max-call-length*`` can be set to control
  how long function or method name can be. By default it is 100, but methods are logged along
  with their specialized arguments and can be longer.

0.4.1 (2019-03-05)
==================

Fixed
-----

* Added missing dependency from cl-strings.

0.4.0 (2019-03-04)
==================

Improved
--------

Now ``setup`` sets appender into a mode when it prints log in a human
readable way if it its called from the SLY's REPL. All logger fields are
printed as well, including a traceback.

0.3.0 (2019-01-07)
==================

Improved
--------

* Now condition's description is added to the end of the backtrace.

0.2.2 (2018-12-08)
==================

Fixed
-----

* Fixed system's loading in environments with ``C`` locale.

  This closes issue reported along with pull request #1.

0.2.1 (2018-11-24)
==================

Fixed
-----

* Previously, macros ``with-log-unhandled`` catched every signal,
  not only signals derived from ``error``. Because of that,
  it logged traceback for non error signals like that:

  .. code:: common-lisp

            (log4cl-json:with-log-unhandled ()
                (signal "foo"))

  Now this bad behavior was fixed and only ``errors`` are logged.


0.2.0 (2017-08-29)
==================

New
---

* Added ability to log tracebacks using ``with-log-unhandled``.


0.1.0 (2017-01-23)
==================

* Initial version.
