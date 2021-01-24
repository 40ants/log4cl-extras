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


Printing backtrace
==================

There is a helper function for extracting and printing backtrace, which can be used
separately from logging. One use case is to render backtrace on the web page when a
site is in a debug mode:

.. code:: common-lisp

   CL-USER> (log4cl-extras/error:print-backtrace :depth 3)
   Traceback (most recent call last):
      0 File "/Users/art/.roswell/src/sbcl-2.0.11/src/code/eval.lisp", line 291
          In SB-INT:SIMPLE-EVAL-IN-LEXENV
        Args ((LOG4CL-EXTRAS/ERROR:PRINT-BACKTRACE :DEPTH 3) #<NULL-LEXENV>)
      1 File "/Users/art/.roswell/src/sbcl-2.0.11/src/code/eval.lisp", line 311
          In EVAL
        Args ((LOG4CL-EXTRAS/ERROR:PRINT-BACKTRACE :DEPTH 3))
      2 File "/Users/art/projects/lisp/sly/contrib/slynk-mrepl.lisp"
          In (LAMBDA () :IN SLYNK-MREPL::MREPL-EVAL-1)
        Args ()

By default, it prints to the ``*debug-io``, but you can pass it a ``:STREAM`` argument
which has the same semantic as a stream for ``FORMAT`` function.

Other useful parameters are ``:DEPTH`` and ``:MAX-CALL-LENTH``. They allow to control how
long and wide backtrace will be.

Also, you might pass ``:CONDITION``. If it is given, it will be printed after the backtrace.

And finally, you can pass a list of functions to filter arguments before printing.
This way secret or unnecesary long values can be stripped. See the next section to learn
how to not log secret values.

How Keep Secrets Out of Logs
============================

When backtrace is printed to log files it is good idea to omit passwords, tokens, cookies,
and other potentially sensitive values.

Here is a potential situation where you have a password and trying to create a new connection
to the database. But because of some network error, an unhandled error along with a backtrace
will be logged. Pay attention to our secret password in the log:


.. code:: common-lisp

   CL-USER> (log4cl-extras/config:setup
              '(:level :error
                :appenders ((this-console :layout plain))))
   
   CL-USER> (defun connect (password)
              "Normally, we don't control this function's code
               because it is from the third-party library."
              (check-type password string)
              (error "Network timeout"))
   
   CL-USER> (defun authenticate (password)
              "This function is in our app's codebase.
               It is calling a third-party DB driver."     
              (connect password))
   
   CL-USER> (defun bar (password)
              (authenticate password))
   
   CL-USER> (log4cl-extras/error:with-log-unhandled (:depth 5)
              (bar "The Secret Password"))
   <ERROR> [2021-01-24T14:13:24.460890+03:00] Unhandled exception
     Fields:
     Traceback (most recent call last):
        0 File "unknown"
            In (FLET "H0")
          Args (#<SIMPLE-ERROR "Network timeout" {100F065533}>)
        1 File "/Users/art/.roswell/src/sbcl-2.0.11/src/code/cold-error.lisp", line 81
            In SB-KERNEL::%SIGNAL
          Args (#<SIMPLE-ERROR "Network timeout" {100F065533}>)
        2 File "/Users/art/.roswell/src/sbcl-2.0.11/src/code/cold-error.lisp", line 154
            In ERROR
          Args ("Network timeout")
        3 File "unknown"
            In CONNECT
          Args ("The Secret Password")
        4 File "unknown"
            In AUTHENTICATE
          Args ("The Secret Password")
     
     Condition: Network timeout


With ``log4cl-extras`` you can keep values in secret in two ways.


The Easy Way to Keep Secrets
============================

The easiest way, is two wrap all sensitive data using `secret-values <https://40ants.com/lisp-project-of-the-day/2020/09/0186-secret-values.html>`_
library as soon as possible and unwrap them only before usage.

Lets see what will happen if we'll use a wrapped password.

First, we need to learn ``authenticate`` function, how to unwrap
the password, before passing it to the driver:


.. code:: common-lisp

   CL-USER> (defun authenticate (password)
              "This function is in our app's codebase.
               It is calling a third-party DB driver."
              (connect
               (secret-values:ensure-value-revealed
                password)))

Next, we need to wrap password into a special object. It is better to
do this as soon as possible. In production code you'll probably have
something like ``(secret-values:conceal-value (uiop:getenv "POSTGRES_PASSWORD"))``:


.. code:: common-lisp

   CL-USER> (log4cl-extras/error:with-log-unhandled (:depth 5)
              (bar (secret-values:conceal-value
                    "The Secret Password")))
   <ERROR> [2021-01-24T14:16:01.667651+03:00] Unhandled exception
     Fields:
     Traceback (most recent call last):
        0 File "unknown"
            In (FLET "H0")
          Args (#<SIMPLE-ERROR "Network timeout" {10036CB1A3}>)
        1 File "/Users/art/.roswell/src/sbcl-2.0.11/src/code/cold-error.lisp", line 81
            In SB-KERNEL::%SIGNAL
          Args (#<SIMPLE-ERROR "Network timeout" {10036CB1A3}>)
        2 File "/Users/art/.roswell/src/sbcl-2.0.11/src/code/cold-error.lisp", line 154
            In ERROR
          Args ("Network timeout")
        3 File "unknown"
            In CONNECT
          Args ("The Secret Password")
        4 File "unknown"
            In AUTHENTICATE
          Args (#<SECRET-VALUES:SECRET-VALUE {10036CB183}>)
     
     Condition: Network timeout

Pay attention to the fourth stack frame. ``AUTHENTICATE`` function has
``#<SECRET-VALUES:SECRET-VALUE {10036CB183}>`` as the first argument.
But why do we see ``"The Secret Password"`` in the third frame anyway?

It is because we have to pass a raw version of the password to the libraries
we don't control.

Here is where ``log4cl-extras`` comes to the resque. It providess a subsystem
``LOG4CL-EXTRAS/SECRETS``. It is optional and is not loaded together with the
primary system.

Earlier, I've mentioned ``:ARGS-FILTERS`` argument to the ``PRINT-BACKTRACE``
function. Package ``LOG4CL-EXTRAS/SECRETS`` provides a function ``MAKE-SECRETS-REPLACER``
which can be used to filter secret values.

We can add it into the global variable ``LOG4CL-EXTRAS/ERROR:*ARGS-FILTERS*`` like this:


.. code:: common-lisp

   CL-USER> (ql:quickload :log4cl-extras/secrets)
   (:LOG4CL-EXTRAS/SECRETS)
   
   CL-USER> (setf log4cl-extras/error:*args-filters*
                  (list (log4cl-extras/secrets:make-secrets-replacer)))
   (#<CLOSURE (LABELS LOG4CL-EXTRAS/SECRETS::REMOVE-SECRETS :IN LOG4CL-EXTRAS/SECRETS:MAKE-SECRETS-REPLACER) {1007E4464B}>)

Now let's try to connect to our fake database again:


.. code:: common-lisp

   CL-USER> (log4cl-extras/error:with-log-unhandled (:depth 5)
              (bar (secret-values:conceal-value
                    "The Secret Password")))
   <ERROR> [2021-01-24T14:27:17.851716+03:00] Unhandled exception
     Fields:
     Traceback (most recent call last):
        0 File "unknown"
            In (FLET "H0")
          Args (#<SIMPLE-ERROR "Network timeout" {100800F723}>)
        1 File "/Users/art/.roswell/src/sbcl-2.0.11/src/code/cold-error.lisp", line 81
            In SB-KERNEL::%SIGNAL
          Args (#<SIMPLE-ERROR "Network timeout" {100800F723}>)
        2 File "/Users/art/.roswell/src/sbcl-2.0.11/src/code/cold-error.lisp", line 154
            In ERROR
          Args ("Network timeout")
        3 File "unknown"
            In CONNECT
          Args (#<secret value>)
        4 File "unknown"
            In AUTHENTICATE
          Args (#<secret value>)
     
     Condition: Network timeout


Now both third and fourth frames show ``#<secret value>`` instead of the password.
This is because ``(log4cl-extras/secrets:make-secrets-replacer)`` call returns a closure
which remembers and replaces raw values of the secrets too!


The Hard Way to Keep Secrets
============================

Sometimes it is desireable to remove from tracebacks other kinds of data.
For example I don't want to see `Lack <https://github.com/fukamachi/lack/>`_'s
environments, because of a few reasons:

- they contain cookies and it is insecure to log them;
- they may contain HTTP header with tokens;
- env objects are list with large amount of data and this makes tracebacks unreadable.

Let's create a filter for arguments, which will replace Lack's environments
with a placeholder.

First, we need to create a placeholder object:


.. code:: common-lisp
          
CL-USER> (defvar +lack-env-placeholder+
           (log4cl-extras/error:make-placeholder "lack env"))
+LACK-ENV-PLACEHOLDER+

Next, we need to define a filter function. Each filter function should accept
two arguments:

- a function's name, which can be a symbol or a list like ``(:method foo-bar (...))``
- a list of arguments.

Filter should return two values, which can be the same is inputs or a transformed in some way.

For example, we know that the Lack's env is a plist with ``:REQUEST-METHOD``, ``:REQUEST-URI`` and other values.
We can to write a predicate like this:


.. code:: common-lisp
          
   CL-USER> (defun lack-env-p (arg)
              (and (listp arg)
                   (member :request-method arg)
                   (member :request-uri arg)))

And to use it in our filter:


.. code:: common-lisp
          
   CL-USER> (defun remove-lack-env-from-frame (func-name args)
              "Removes Lack's env from stackframes to make backtrace concise."
              (values func-name
                      (loop for arg in args
                            if (lack-env-p arg)
                              collect +lack-env-placeholder+
                            else
                              collect arg)))
   
Now let's try to use it:


.. code:: common-lisp
          
   CL-USER> (defun request-handler (app env)
              (authenticate (secret-values:conceal-value
                             "Secret password"))
              (pass-further app env))
   
   CL-USER> (setf log4cl-extras/error:*args-filters*
                  (list 'remove-lack-env-from-frame
                        ;; We need this too to keep DB password safe, remember?
                        (log4cl-extras/secrets:make-secrets-replacer)))

Now pay attention to the fifth frame, where second argument is replaced
with ``#<lack env>``!!!


.. code:: common-lisp

   CL-USER> (log4cl-extras/error:with-log-unhandled (:depth 7)
              (request-handler 42
                               (list :request-method :post
                                     :request-uri "/login/"
                                     :cookies "Session hash, and other secrets.")))
   <ERROR> [2021-01-24T14:56:45.502656+03:00] Unhandled exception
     Fields:
     Traceback (most recent call last):
        0 File "unknown"
            In (FLET "H0")
          Args (#<SIMPLE-ERROR "Network timeout" {1004233EB3}>)
        1 File "/Users/art/.roswell/src/sbcl-2.0.11/src/code/cold-error.lisp", line 81
            In SB-KERNEL::%SIGNAL
          Args (#<SIMPLE-ERROR "Network timeout" {1004233EB3}>)
        2 File "/Users/art/.roswell/src/sbcl-2.0.11/src/code/cold-error.lisp", line 154
            In ERROR
          Args ("Network timeout")
        3 File "unknown"
            In CONNECT
          Args (#<secret value>)
        4 File "unknown"
            In AUTHENTICATE
          Args (#<secret value>)
        5 File "unknown"
            In REQUEST-HANDLER
          Args (42 #<lack env>)
        6 File "unknown"
            In (LAMBDA ())
          Args ()
     
     Condition: Network timeout


For such simple case like replacing args matching a predicate, ``LOG4CL-EXTRAS`` has a small helper ``LOG4CL-EXTRAS/ERROR:MAKE-ARGS-FILTER``:


.. code:: common-lisp

   CL-USER> (setf log4cl-extras/error:*args-filters*
                  (list (log4cl-extras/error:make-args-filter
                         'lack-env-p
                         (log4cl-extras/error:make-placeholder "LACK ENV BEING HERE"))
                        ;; We need this too to keep DB password safe, remember?
                        (log4cl-extras/secrets:make-secrets-replacer)))
   
   <ERROR> [2021-01-24T15:09:48.839513+03:00] Unhandled exception
     Fields:
     Traceback (most recent call last):
        0 File "unknown"
            In (FLET "H0")
          Args (#<SIMPLE-ERROR "Network timeout" {1003112243}>)
        1 File "/Users/art/.roswell/src/sbcl-2.0.11/src/code/cold-error.lisp", line 81
            In SB-KERNEL::%SIGNAL
          Args (#<SIMPLE-ERROR "Network timeout" {1003112243}>)
        2 File "/Users/art/.roswell/src/sbcl-2.0.11/src/code/cold-error.lisp", line 154
            In ERROR
          Args ("Network timeout")
        3 File "unknown"
            In CONNECT
          Args (#<secret value>)
        4 File "unknown"
            In AUTHENTICATE
          Args (#<secret value>)
        5 File "unknown"
            In REQUEST-HANDLER
          Args (42 #<LACK ENV BEING HERE>)
        6 File "unknown"
            In (LAMBDA ())
          Args ()
     
     Condition: Network timeout
