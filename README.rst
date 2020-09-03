=============
log4cl-extras
=============

This library extends log4cl in a few ways:

* It helps with configuration of multiple appenders and layouts.
* Has a facility to catch context fields and to log them.
* Has a macro to log unhandled errors.
* Adds a layout to write messages as ``JSON``, which is useful for production as makes easier to parse and process such logs.
* Uses the appenders which are not disabled in case of some error which again, should be useful for production.


Installation
============

This library is not available from Quicklisp, but you can install it from Ultralisp.org:

.. code:: common-lisp

   (ql-dist:install-dist "http://dist.ultralisp.org/"
                         :prompt nil)
   (ql:quickload :log4cl-extras)


Configuration
=============

Here is the example of the config, suitable for production. Here we log all messages as ``JSON`` records
into the file, rotated on the daily basis. And all errors and warnings will be written to the ``REPL``.

.. code:: common-lisp

   (log4cl-extras/config:setup
    '(:level :debug
      :appenders ((this-console :layout :plain
                                :filter :warn)
                  (daily :layout :json
                         :name-format "/app/logs/app.log"
                         :backup-name-format "app-%Y%m%d.log"))))


Context fields
==============

Macro ``log4cl-extras/context:with-fields`` let to to capture some information into the dynamic variable.
All messages logged inside the ``with-fields`` form will have these fields attached:

.. code:: common-lisp


   CL-USER> (log4cl-extras/config:setup
             '(:level :debug
               :appenders ((this-console :layout :plain))))

   CL-USER> (defun process-request ()
              (log:info "Processing request"))

   CL-USER> (log4cl-extras/context:with-fields (:request-id 42)
              (process-request))
   <INFO> [2020-07-19T10:03:21.079636Z] Processing request
     Fields:
       request-id: 42

   ;; Now let's switch to JSON layout:
   CL-USER> (log4cl-extras/config:setup
             '(:level :debug
               :appenders ((this-console :layout :json))))

   CL-USER> (log4cl-extras/context:with-fields (:request-id 42)
              (process-request))
   {"fields": {"request-id": 42},
    "level": "INFO",
    "message": "Processing request",
    "timestamp": "2020-07-19T10:03:32.855593Z"}


.. warning:: Beware, catching context fields costs some time even if they are not logged.


Logging unhandled errors
========================

If you want to log unhandled signals traceback, then use ``log4cl-extras/error:with-log-unhandled`` macro.

Usually it is good idea, to use ``with-log-unhandled`` in the main function or in a function which handles
a HTTP request.

If some error condition will be signaled by the body, it will be logged as an error with ``traceback``
field like this:

.. code:: common-lisp

   CL-USER> (defun foo ()
              (error "Some error happened"))

   CL-USER> (defun bar ()
              (foo))

   CL-USER> (log4cl-extras/error:with-log-unhandled ()
              (bar))

   <ERROR> [2020-07-19T10:14:39.644805Z] Unhandled exception
     Fields:
     Traceback (most recent call last):
       File "NIL", line NIL, in FOO
         (FOO)
       File "NIL", line NIL, in BAR
         (BAR)
       File "NIL", line NIL, in (LAMBDA (…
         ((LAMBDA ()))
       File "NIL", line NIL, in SIMPLE-EV…
         (SB-INT:SIMPLE-EVAL-IN-LEXENV
          (LOG4CL-EXTRAS/ERROR:WITH-LOG-UNHANDLED NIL
            (BAR))
          #<NULL-LEXENV>)
       ...
          #<CLOSURE (LAMBDA () :IN SLYNK::CALL-WITH-LISTENER) {100A6B043B}>)
     
     
     Condition: Some error happened
   ; Debugger entered on #<SIMPLE-ERROR "Some error happened" {100A7A5DB3}>

The ``JSON`` layout will write such error like this:


.. code:: json

   {"fields":{"traceback":"Traceback (most recent call last):\n  File \"NIL\", line NIL, in FOO\n    (FOO)\n  File \"NIL\", line NIL, in BAR\n    (BAR)\n...\nCondition: Some error happened"},"level":"ERROR","message":"Unhandled exception","timestamp":"2020-07-19T10:21:33.557418Z"}
