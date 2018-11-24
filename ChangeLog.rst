===========
 Changelog
===========

0.2.1 - 2018-11-24
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


0.2.0 - 2017-08-29
==================

New
---

* Added ability to log tracebacks using ``with-log-unhandled``.


0.1.0 - 2017-01-23
==================

* Initial version.
