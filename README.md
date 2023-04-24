<a id="x-28LOG4CL-EXTRAS-2FDOC-3A-40README-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

# LOG4CL-EXTRAS - Addons for Log4CL

<a id="log4-cl-extras-asdf-system-details"></a>

## LOG4CL-EXTRAS ASDF System Details

* Version: 0.9.0

* Description: A bunch of addons to `LOG4CL`: `JSON` appender, context fields, cross-finger appender, etc.

* Licence: `BSD`

* Author: Alexander Artemenko

* Homepage: [https://40ants.com/log4cl-extras/][2906]

* Bug tracker: [https://github.com/40ants/log4cl-extras/issues][d7d4]

* Source control: [GIT][8f00]

* Depends on: [40ants-doc][2c00], [alexandria][8236], [cl-strings][2ecb], [dissect][70a8], [global-vars][07be], [jonathan][6dd8], [local-time][46a1], [log4cl][7f8b], [named-readtables][d0a9], [pythonic-string-reader][c01d], [with-output-to-stream][9201]

[![](https://github-actions.40ants.com/40ants/log4cl-extras/matrix.svg?only=ci.run-tests)][b509]

<a id="x-28LOG4CL-EXTRAS-2FDOC-3A-3A-40INSTALLATION-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## Installation

You can install this library from Quicklisp, but you want to receive updates quickly, then install it from Ultralisp.org:

```
(ql-dist:install-dist "http://dist.ultralisp.org/"
                      :prompt nil)
(ql:quickload :log4cl-extras)
```
<a id="x-28LOG4CL-EXTRAS-2FCONFIG-3A-3A-40CONFIGURATION-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## Configuration

By default `LOG4CL` outputs log items like this:

```
CL-USER> (log:info "Hello")
 <INFO> [01:15:37] cl-user () - Hello
```
However logging extra context fields requires a custom "layout".
Layout defines the way how the message will be formatted.

This system defines two layout types:

* `:PLAIN` - a layout for printing messages to the `REPL`.

* `:JSON` - a layout which outputs each message and all it's data
  as a `JSON` documents. Use it to feed logs to Elastic Search
  or a service like [Datadog][646b]
  to [Papertrail][ee55].

To use these custom layouts, you have to use [`setup`][74de] function. It also allows to set a log level
for root logger and appenders. Here is a minimal example showing how to configure logger for the `REPL`:

```
CL-USER> (log4cl-extras/config:setup
          '(:level :debug
            :appenders ((this-console :layout :plain))))
NIL

CL-USER> (log:info "Hello")
<INFO> [2021-05-16T01:16:46.978992+03:00] Hello

CL-USER> (log4cl-extras/context:with-fields (:foo "Bar")
           (log:info "Hello"))
<INFO> [2021-05-16T01:26:30.331849+03:00] Hello
  Fields:
    foo: Bar
```
If you replace `:PLAIN` with `:JSON`, you'll get this:

```
CL-USER> (log4cl-extras/config:setup
          '(:level :debug
            :appenders ((this-console :layout :json))))
; No values
CL-USER> (log4cl-extras/context:with-fields (:foo "Bar")
           (log:info "Hello"))
{"fields":{"foo":"Bar"},"level":"INFO","message":"Hello","timestamp":"2021-05-16T01:27:54.879336+03:00"}
```
Appender in terms of log4cl is a target for log output. You can combine multiple appenders
in a single call to [`setup`][74de] function.

Here is the example of the config, suitable for production. Here we log all messages as `JSON` records
into the file, rotated on the daily basis. And all errors and warnings will be written to the `REPL`.

```
(log4cl-extras/config:setup
 '(:level :debug
   :appenders ((this-console :layout :plain
                             :filter :warn)
               (daily :layout :json
                      :name-format "/app/logs/app.log"
                      :backup-name-format "app-%Y%m%d.log"))))
```
Also, [`setup`][74de] allows to change log levels for different loggers:

<a id="x-28LOG4CL-EXTRAS-2FCONFIG-3ASETUP-20FUNCTION-29"></a>

### [function](90a7) `log4cl-extras/config:setup` config

Setup loggers and appenders via confg.

Example:

```
(setup
 '(:level :error
   :appenders
   (this-console
    (file
     :file "foo.log"
     :layout json))
   :loggers
   ((log4cl-extras/config
     :loggers
     ((foo :level :debug)
      (bar
       :loggers
       ((some-class
         :level debug))))))))
```
As you can see, [`setup`][74de] function accepts a plist with keys `:LEVEL`, `:APPENDERS` and `:LOGGERS`.

`:LEVEL` key holds a logging level for the root logger. It could be `:INFO`, `:WARN` or `:ERROR`.

`:APPENDERS` is a list of list where each sublist should start from the appender type and arguments for it's constructor.

Supported appenders are:

* `THIS-CONSOLE` corresponds to `LOG4CL:THIS-CONSOLE-APPENDER` class.

* `DAILY` corresponds to `LOG4CL:DAILY-FILE-APPENDER` class.

* `FILE` corresponds to `LOG4CL:FILE-APPENDER`.

To lookup supported arguments for each appender type, see these classes initargs.
the only difference is that `:LAYOUT` argument is processed in a special way:
`:JSON` value replaced with [`log4cl-extras/json:json-layout`][f356] and `:PLAIN` is replaced
with [`log4cl-extras/plain:plain-layout`][f2d0].

And finally, you can pass to [`setup`][74de] a list of loggers. Each item in this list
should be plist where first item is a symbolic name of a package or a function name
inside a package and other items are params for a nested [`setup`][74de] call.

<a id="layouts"></a>

### Layouts

<a id="x-28LOG4CL-EXTRAS-2FPLAIN-3APLAIN-LAYOUT-20CLASS-29"></a>

### [class](e441) `log4cl-extras/plain:plain-layout` (layout)

<a id="x-28LOG4CL-EXTRAS-2FJSON-3AJSON-LAYOUT-20CLASS-29"></a>

### [class](f152) `log4cl-extras/json:json-layout` (layout)

<a id="x-28LOG4CL-EXTRAS-2FCONTEXT-3A-3A-40CONTEXT-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## Context Fields

Macro [`with-fields`][b464] let to to capture some information into the dynamic variable.
All messages logged inside the [`with-fields`][b464] form will have these fields attached:

```
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
```
**Beware!**, catching context fields costs some time even if they are not logged.

<a id="x-28LOG4CL-EXTRAS-2FCONTEXT-3AWITH-FIELDS-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29"></a>

### [macro](c98a) `log4cl-extras/context:with-fields` (&rest fields) &body body

Captures content of given fields into a dynamic variable.

These fields will be logged along with any log entry
inside the [`with-fields`][b464] body.

<a id="x-28LOG4CL-EXTRAS-2FCONTEXT-3AGET-FIELDS-20FUNCTION-29"></a>

### [function](f9dc) `log4cl-extras/context:get-fields`

Returns an alist of all fields defined using [`with-fields`][b464] macro in the current stack.

Keys are returned as downcased strings, prepared for logging.

<a id="x-28LOG4CL-EXTRAS-2FERROR-3A-3A-40ERRORS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## Logging Unhandled Errors

<a id="x-28LOG4CL-EXTRAS-2FERROR-3A-3A-40INTRO-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### Quickstart

If you want to log unhandled signals traceback, then use [`with-log-unhandled`][3fd6] macro.

Usually it is good idea, to use [`with-log-unhandled`][3fd6] in the main function or in a function which handles
a `HTTP` request.

If some error condition will be signaled by the body, it will be logged as an error with "traceback"
field like this:

```
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
```
The `JSON` layout will write such error like this:

```
{
  "fields": {
    "traceback": "Traceback (most recent call last):\n  File \"NIL\", line NIL, in FOO\n    (FOO)\n  File \"NIL\", line NIL, in BAR\n    (BAR)\n...\nCondition: Some error happened"
  },
  "level": "ERROR",
  "message": "Unhandled exception",
  "timestamp": "2020-07-19T10:21:33.557418Z"
}
```
<a id="x-28LOG4CL-EXTRAS-2FERROR-3A-3A-40PRINTING-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### Printing Backtrace

There is a helper function [`print-backtrace`][6a57] for extracting and printing backtrace, which can be used
separately from logging. One use case is to render backtrace on the web page when a
site is in a debug mode:

```
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
```
By default, it prints to the `*DEBUG-IO*`, but you can pass it a `:STREAM` argument
which has the same semantic as a stream for `FORMAT` function.

Other useful parameters are `:DEPTH` and `:MAX-CALL-LENGTH`. They allow to control how
long and wide backtrace will be.

Also, you might pass `:CONDITION`. If it is given, it will be printed after the backtrace.

And finally, you can pass a list of functions to filter arguments before printing.
This way secret or unnecesary long values can be stripped. See the next section to learn
how to not log secret values.

<a id="api"></a>

### API

<a id="x-28LOG4CL-EXTRAS-2FERROR-3A-2AMAX-TRACEBACK-DEPTH-2A-20-28VARIABLE-29-29"></a>

### [variable](4ec7) `log4cl-extras/error:*max-traceback-depth*` 10

Keeps default value for traceback depth logged by [`with-log-unhandled`][3fd6] macro

<a id="x-28LOG4CL-EXTRAS-2FERROR-3A-2AMAX-CALL-LENGTH-2A-20-28VARIABLE-29-29"></a>

### [variable](72d3) `log4cl-extras/error:*max-call-length*` 100

The max length of each line in a traceback. It is useful to limit it because otherwise some log collectors can discard the whole log entry.

<a id="x-28LOG4CL-EXTRAS-2FERROR-3A-2AARGS-FILTERS-2A-20-28VARIABLE-29-29"></a>

### [variable](ec5e) `log4cl-extras/error:*args-filters*` nil

Add to this variable functions of two arguments to change arguments before they will be dumped
as part of the backtrace to the log.

This is not a special variable, because it should be changed system-wide and can be accessedd
from multiple threads.

<a id="x-28LOG4CL-EXTRAS-2FERROR-3A-2AARGS-FILTER-CONSTRUCTORS-2A-20-28VARIABLE-29-29"></a>

### [variable](7e6d) `log4cl-extras/error:*args-filter-constructors*` nil

Add to this variable functions of zero arguments. Each function should return an argument filter
function suitable for using in the [`*args-filters*`][c7a0] variable.

These constructors can be used to create argument filters with state suitable for
processing of a single backtrace only. For example,
[`log4cl-extras/secrets:make-secrets-replacer`][bb11] function, keeps tracks every secret value used in
all frames of the backtrace. We don't want to keep these values forever and to mix secrets
of different users in the same place. Thus this function should be used as a "constructor".
In this case it will create a new secret replacer for every backtrace to be processed.

<a id="x-28LOG4CL-EXTRAS-2FERROR-3AWITH-LOG-UNHANDLED-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29"></a>

### [macro](ae08) `log4cl-extras/error:with-log-unhandled` (&key (depth \*max-traceback-depth\*) (errors-to-ignore nil)) &body body

Logs any `ERROR` condition signaled from the body. Logged message will have a "traceback" field.

You may specify a list of error classes to ignore as `ERRORS-TO-IGNORE` argument.
Errors matching (typep err <each-of errors-to-ignore>) will not be logged as "Unhandled".

<a id="x-28LOG4CL-EXTRAS-2FERROR-3APRINT-BACKTRACE-20FUNCTION-29"></a>

### [function](9aea) `log4cl-extras/error:print-backtrace` &key (stream \*debug-io\*) (condition nil) (depth \*max-traceback-depth\*) (max-call-length \*max-call-length\*) (args-filters (get-current-args-filters)) (format-condition #'format-condition-object)

A helper to print backtrace. Could be useful to out backtrace
at places other than logs, for example at a web page.

This function applies the same filtering rules as [`with-log-unhandled`][3fd6] macro.

By default condition description is printed like this:

```
Condition REBLOCKS-WEBSOCKET:NO-ACTIVE-WEBSOCKETS: No active websockets bound to the current page.
```
But you can change this by providing an argument `FORMAT-CONDITION`. It should be a
function of two arguments: `(stream condition)`.

<a id="x-28LOG4CL-EXTRAS-2FERROR-3AMAKE-ARGS-FILTER-20FUNCTION-29"></a>

### [function](f41a) `log4cl-extras/error:make-args-filter` predicate placeholder

Returns a function, suitable to be used in [`*args-filters*`][c7a0] variable.

Function `PREDICATE` will be applied to each argument in the frame
and if it returns T, then argument will be replaced with `PLACEHOLDER`.

<a id="x-28LOG4CL-EXTRAS-2FERROR-3APLACEHOLDER-20CLASS-29"></a>

### [class](d6ba) `log4cl-extras/error:placeholder` ()

Objects of this class can be used as replacement to arguments in a backtrace.

They are printed like `#<some-name>`.

This form was choosen to match the way how `SBCL` shows unused arguments: `#<unused argument>`.

Placeholders should be created with [`make-placeholder`][de65] function.

<a id="x-28LOG4CL-EXTRAS-2FERROR-3AMAKE-PLACEHOLDER-20FUNCTION-29"></a>

### [function](e472) `log4cl-extras/error:make-placeholder` name

Creates a placeholder for some secret value or omitted argument.

```
CL-USER> (log4cl-extras/error:make-placeholder "secret value")

#<secret value>
```
See [`Hard Way`][2087] section to learn, how to use
placeholders to remove sensitive information from logs.

<a id="x-28LOG4CL-EXTRAS-2FERROR-3APLACEHOLDER-P-20FUNCTION-29"></a>

### [function](894d) `log4cl-extras/error:placeholder-p` obj

<a id="x-28LOG4CL-EXTRAS-2FERROR-3APLACEHOLDER-NAME-20-2840ANTS-DOC-2FLOCATIVES-3AREADER-20LOG4CL-EXTRAS-2FERROR-3APLACEHOLDER-29-29"></a>

### [reader](3299) `log4cl-extras/error:placeholder-name` (placeholder) (:name)

<a id="x-28LOG4CL-EXTRAS-2FSECRETS-3A-3A-40KEEPING-SECRETS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

## How Keep Secrets Out of Logs

When backtrace is printed to log files it is good idea to omit passwords, tokens, cookies,
and other potentially sensitive values.

Here is a potential situation where you have a password and trying to create a new connection
to the database. But because of some network error, an unhandled error along with a backtrace
will be logged. Pay attention to our secret password in the log:

```
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
```
With [`log4cl-extras`][1395] you can keep values in secret in two ways.

<a id="x-28LOG4CL-EXTRAS-2FSECRETS-3A-3A-40EASY-WAY-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### Easy Way

The easiest way, is to wrap all sensitive data using
[secret-values][ee75]
library as soon as possible and unwrap them only before usage.

Lets see what will happen if we'll use a wrapped password.

First, we need to teach `AUTHENTICATE` function, how to unwrap
the password, before passing it to the driver:

```
CL-USER> (defun authenticate (password)
           "This function is in our app's codebase.
  It is calling a third-party DB driver."
           (connect
            (secret-values:ensure-value-revealed
             password)))
```
Next, we need to wrap password into a special object. It is better to
do this as soon as possible. In production code you'll probably have
something like `(secret-values:conceal-value (uiop:getenv "POSTGRES_PASSWORD"))`:

```
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
```
Pay attention to the fourth stack frame. `AUTHENTICATE` function has
`#<SECRET-VALUES:SECRET-VALUE {10036CB183}>` as the first argument.
But why do we see `"The Secret Password"` in the third frame anyway?

It is because we have to pass a raw version of the password to the libraries
we don't control.

Here is where [`log4cl-extras`][1395] comes to the resque. It provides a package
`LOG4CL-EXTRAS/SECRETS`. It is optional and is not loaded together with the
primary system.

Earlier, I've mentioned `:ARGS-FILTERS` argument to the [`log4cl-extras/error:print-backtrace`][6a57] function.
Package `LOG4CL-EXTRAS/SECRETS` provides a function [`make-secrets-replacer`][bb11]
which can be used to filter secret values.

We can add it into the global variable [`log4cl-extras/error:*args-filter-constructors*`][5c08] like this:

```
CL-USER> (ql:quickload :log4cl-extras/secrets)
(:LOG4CL-EXTRAS/SECRETS)
   
CL-USER> (setf log4cl-extras/error:*args-filter-constructors*
               (list 'log4cl-extras/secrets:make-secrets-replacer))
(#<FUNCTION LOG4CL-EXTRAS/SECRETS:MAKE-SECRETS-REPLACER>)
```
Now let's try to connect to our fake database again:

```
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
```
Now both third and fourth frames show `#<secret value>` instead of the password.
This is because `(log4cl-extras/secrets:make-secrets-replacer)` call returns a closure
which remembers and replaces raw values of the secrets too!

<a id="x-28LOG4CL-EXTRAS-2FSECRETS-3A-3A-40HARD-WAY-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29"></a>

### Hard Way

Sometimes it is desireable to remove from tracebacks other kinds of data.
For example I don't want to see [Lack][d1aa]'s
environments, because of a few reasons:

* they contain cookies and it is insecure to log them;

* they may contain `HTTP` header with tokens;

* env objects are list with large amount of data and this makes tracebacks unreadable.

Let's create a filter for arguments, which will replace Lack's environments
with a placeholder.

First, we need to create a placeholder object:

```
CL-USER> (defvar +lack-env-placeholder+
           (log4cl-extras/error:make-placeholder "lack env"))
+LACK-ENV-PLACEHOLDER+
```
Next, we need to define a filter function. Each filter function should accept
two arguments:

* a function's name, which can be a symbol or a list like `(:method foo-bar (...))`

* a list of arguments.

Filter should return two values, which can be the same is inputs or a transformed in some way.

For example, we know that the Lack's env is a plist with `:REQUEST-METHOD`, `:REQUEST-URI` and other values.
We can to write a predicate like this:

```
CL-USER> (defun lack-env-p (arg)
           (and (listp arg)
                (member :request-method arg)
                (member :request-uri arg)))
```
And to use it in our filter:

```
CL-USER> (defun remove-lack-env-from-frame (func-name args)
           "Removes Lack's env from stackframes to make backtrace concise."
           (values func-name
                   (loop for arg in args
                         if (lack-env-p arg)
                           collect +lack-env-placeholder+
                         else
                           collect arg)))
```
Now let's try to use it:

```
CL-USER> (defun request-handler (app env)
           (authenticate (secret-values:conceal-value
                          "Secret password"))
           (pass-further app env))
   
CL-USER> (setf log4cl-extras/error:*args-filters*
               (list 'remove-lack-env-from-frame)
               log4cl-extras/error:*args-filter-constructors*
               ;; We need this too to keep DB password safe, remember?
               (list 'log4cl-extras/secrets:make-secrets-replacer))
```
Now pay attention to the fifth frame, where second argument is replaced
with `#<lack env>`!!!

```
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
```
For such simple case like replacing args matching a predicate, [`log4cl-extras`][1395] has a small helper [`log4cl-extras/error:make-args-filter`][9b0c]:

```
CL-USER> (setf log4cl-extras/error:*args-filters*
               (list (log4cl-extras/error:make-args-filter
                      'lack-env-p
                      (log4cl-extras/error:make-placeholder "LACK ENV BEING HERE")))
               log4cl-extras/error:*args-filter-constructors*
               ;; We need this too to keep DB password safe, remember?
               (list 'log4cl-extras/secrets:make-secrets-replacer))
   
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
```
<a id="x-28LOG4CL-EXTRAS-2FSECRETS-3AMAKE-SECRETS-REPLACER-20FUNCTION-29"></a>

### [function](0dd4) `log4cl-extras/secrets:make-secrets-replacer`

Returns a function which can be used to filter backtrace arguments.

Beware, don't add result of the call to [`make-secrets-replacer`][bb11] to
the [`log4cl-extras/error:*args-filters*`][c7a0] variable, because it will
collect all secrets and keep them in memory until the end of the program.

Use [`log4cl-extras/error:*args-filter-constructors*`][5c08] instead, to keep
secrets only during the backtrace processing.


[ee75]: https://40ants.com/lisp-project-of-the-day/2020/09/0186-secret-values.html
[2906]: https://40ants.com/log4cl-extras/
[1395]: https://40ants.com/log4cl-extras/#x-28-23A-28-2813-29-20BASE-CHAR-20-2E-20-22log4cl-extras-22-29-20ASDF-2FSYSTEM-3ASYSTEM-29
[74de]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FCONFIG-3ASETUP-20FUNCTION-29
[b464]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FCONTEXT-3AWITH-FIELDS-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29
[5c08]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FERROR-3A-2AARGS-FILTER-CONSTRUCTORS-2A-20-28VARIABLE-29-29
[c7a0]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FERROR-3A-2AARGS-FILTERS-2A-20-28VARIABLE-29-29
[9b0c]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FERROR-3AMAKE-ARGS-FILTER-20FUNCTION-29
[de65]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FERROR-3AMAKE-PLACEHOLDER-20FUNCTION-29
[6a57]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FERROR-3APRINT-BACKTRACE-20FUNCTION-29
[3fd6]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FERROR-3AWITH-LOG-UNHANDLED-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29
[f356]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FJSON-3AJSON-LAYOUT-20CLASS-29
[f2d0]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FPLAIN-3APLAIN-LAYOUT-20CLASS-29
[2087]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FSECRETS-3A-3A-40HARD-WAY-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29
[bb11]: https://40ants.com/log4cl-extras/#x-28LOG4CL-EXTRAS-2FSECRETS-3AMAKE-SECRETS-REPLACER-20FUNCTION-29
[8f00]: https://github.com/40ants/log4cl-extras
[b509]: https://github.com/40ants/log4cl-extras/actions
[90a7]: https://github.com/40ants/log4cl-extras/blob/06e7d9d1a192a2799b1f95f4c4416aab6bba1484/src/config.lisp#L211
[f9dc]: https://github.com/40ants/log4cl-extras/blob/06e7d9d1a192a2799b1f95f4c4416aab6bba1484/src/context.lisp#L62
[c98a]: https://github.com/40ants/log4cl-extras/blob/06e7d9d1a192a2799b1f95f4c4416aab6bba1484/src/context.lisp#L78
[4ec7]: https://github.com/40ants/log4cl-extras/blob/06e7d9d1a192a2799b1f95f4c4416aab6bba1484/src/error.lisp#L152
[72d3]: https://github.com/40ants/log4cl-extras/blob/06e7d9d1a192a2799b1f95f4c4416aab6bba1484/src/error.lisp#L155
[ec5e]: https://github.com/40ants/log4cl-extras/blob/06e7d9d1a192a2799b1f95f4c4416aab6bba1484/src/error.lisp#L158
[7e6d]: https://github.com/40ants/log4cl-extras/blob/06e7d9d1a192a2799b1f95f4c4416aab6bba1484/src/error.lisp#L166
[9aea]: https://github.com/40ants/log4cl-extras/blob/06e7d9d1a192a2799b1f95f4c4416aab6bba1484/src/error.lisp#L289
[ae08]: https://github.com/40ants/log4cl-extras/blob/06e7d9d1a192a2799b1f95f4c4416aab6bba1484/src/error.lisp#L367
[d6ba]: https://github.com/40ants/log4cl-extras/blob/06e7d9d1a192a2799b1f95f4c4416aab6bba1484/src/error.lisp#L385
[3299]: https://github.com/40ants/log4cl-extras/blob/06e7d9d1a192a2799b1f95f4c4416aab6bba1484/src/error.lisp#L386
[e472]: https://github.com/40ants/log4cl-extras/blob/06e7d9d1a192a2799b1f95f4c4416aab6bba1484/src/error.lisp#L404
[894d]: https://github.com/40ants/log4cl-extras/blob/06e7d9d1a192a2799b1f95f4c4416aab6bba1484/src/error.lisp#L419
[f41a]: https://github.com/40ants/log4cl-extras/blob/06e7d9d1a192a2799b1f95f4c4416aab6bba1484/src/error.lisp#L423
[f152]: https://github.com/40ants/log4cl-extras/blob/06e7d9d1a192a2799b1f95f4c4416aab6bba1484/src/json.lisp#L54
[e441]: https://github.com/40ants/log4cl-extras/blob/06e7d9d1a192a2799b1f95f4c4416aab6bba1484/src/plain.lisp#L77
[0dd4]: https://github.com/40ants/log4cl-extras/blob/06e7d9d1a192a2799b1f95f4c4416aab6bba1484/src/secrets.lisp#L357
[d7d4]: https://github.com/40ants/log4cl-extras/issues
[d1aa]: https://github.com/fukamachi/lack/
[2c00]: https://quickdocs.org/40ants-doc
[8236]: https://quickdocs.org/alexandria
[2ecb]: https://quickdocs.org/cl-strings
[70a8]: https://quickdocs.org/dissect
[07be]: https://quickdocs.org/global-vars
[6dd8]: https://quickdocs.org/jonathan
[46a1]: https://quickdocs.org/local-time
[7f8b]: https://quickdocs.org/log4cl
[d0a9]: https://quickdocs.org/named-readtables
[c01d]: https://quickdocs.org/pythonic-string-reader
[9201]: https://quickdocs.org/with-output-to-stream
[646b]: https://www.datadoghq.com/
[ee55]: https://www.papertrail.com/

* * *
###### [generated by [40ANTS-DOC](https://40ants.com/doc/)]
