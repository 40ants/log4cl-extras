<a id='x-28LOG4CL-EXTRAS-2FDOC-3A-40INDEX-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29'></a>

# LOG4CL-EXTRAS - Addons for Log4CL

## Table of Contents

- [1 LOG4CL-EXTRAS ASDF System Details][d11b]
- [2 Installation][c6fa]
- [3 Configuration][80ae]
- [4 Context Fields][97b1]
- [5 Logging Unhandled Errors][1a30]
    - [5.1 Quickstart][e6e1]
    - [5.2 Printing Backtrace][6eb5]
- [6 How Keep Secrets Out of Logs][b622]
    - [6.1 Easy Way][fe0a]
    - [6.2 Hard Way][f53c]

###### \[in package LOG4CL-EXTRAS/DOC\]
<a id='x-28-23A-28-2813-29-20BASE-CHAR-20-2E-20-22log4cl-extras-22-29-20ASDF-2FSYSTEM-3ASYSTEM-29'></a>

## 1 LOG4CL-EXTRAS ASDF System Details

- Version: 0.5.1
- Description: A bunch of addons to LOG4CL: JSON appender, context fields, cross-finger appender, etc.
- Licence: BSD
- Author: Alexander Artemenko
- Homepage: [https://40ants.com/log4cl-extras](https://40ants.com/log4cl-extras)
- Bug tracker: [https://github.com/40ants/log4cl-extras/issues](https://github.com/40ants/log4cl-extras/issues)
- Source control: [GIT](https://github.com/40ants/log4cl-extras)

[![](https://github-actions.40ants.com/40ants/log4cl-extras/matrix.svg?only=ci.run-tests)](https://github.com/40ants/log4cl-extras/actions)

<a id='x-28LOG4CL-EXTRAS-2FDOC-3A-40INSTALLATION-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29'></a>

## 2 Installation

This library is not available from Quicklisp yet, but you can install it from Ultralisp.org:

```
(ql-dist:install-dist "http://dist.ultralisp.org/"
                      :prompt nil)
(ql:quickload :log4cl-extras)
```


<a id='x-28LOG4CL-EXTRAS-2FCONFIG-3A-40CONFIGURATION-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29'></a>

## 3 Configuration

###### \[in package LOG4CL-EXTRAS/CONFIG\]
Here is the example of the config, suitable for production. Here we log all messages as JSON records
into the file, rotated on the daily basis. And all errors and warnings will be written to the REPL.

```
(log4cl-extras/config:setup
 '(:level :debug
   :appenders ((this-console :layout :plain
                             :filter :warn)
               (daily :layout :json
                      :name-format "/app/logs/app.log"
                      :backup-name-format "app-%Y%m%d.log"))))
```


<a id='x-28LOG4CL-EXTRAS-2FCONTEXT-3A-40CONTEXT-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29'></a>

## 4 Context Fields

###### \[in package LOG4CL-EXTRAS/CONTEXT\]
Macro [`WITH-FIELDS`][5de7] let to to capture some information into the dynamic variable.
All messages logged inside the [`WITH-FIELDS`][5de7] form will have these fields attached:

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

<a id='x-28LOG4CL-EXTRAS-2FCONTEXT-3AWITH-FIELDS-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29'></a>

- [macro] **WITH-FIELDS** *(&REST FIELDS) &BODY BODY*

    Captures content of given fields into a dynamic variable.
    
    These fields will be logged along with any log entry
    inside the [`WITH-FIELDS`][5de7] body.

<a id='x-28LOG4CL-EXTRAS-2FCONTEXT-3AGET-FIELDS-20FUNCTION-29'></a>

- [function] **GET-FIELDS** 

    Returns an alist of all fields defined using [`WITH-FIELDS`][5de7] macro in the current stack.
    
    Keys are returned as downcased strings, prepared for logging.

<a id='x-28LOG4CL-EXTRAS-2FERROR-3A-40ERRORS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29'></a>

## 5 Logging Unhandled Errors

###### \[in package LOG4CL-EXTRAS/ERROR\]
<a id='x-28LOG4CL-EXTRAS-2FERROR-3A-40INTRO-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29'></a>

### 5.1 Quickstart

If you want to log unhandled signals traceback, then use [`WITH-LOG-UNHANDLED`][b1b7] macro.

Usually it is good idea, to use [`WITH-LOG-UNHANDLED`][b1b7] in the main function or in a function which handles
a HTTP request.

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
      (`SB-INT:SIMPLE-EVAL-IN-LEXENV`
       (`LOG4CL-EXTRAS/ERROR:WITH-LOG-UNHANDLED` NIL
         (BAR))
       #<NULL-LEXENV>)
    ...
       #<CLOSURE (LAMBDA () :IN `SLYNK::CALL-WITH-LISTENER`) {100A6B043B}>)
     
     
  Condition: Some error happened
; Debugger entered on #<SIMPLE-ERROR "Some error happened" {100A7A5DB3}>
```

The JSON layout will write such error like this:

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


<a id='x-28LOG4CL-EXTRAS-2FERROR-3A-40PRINTING-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29'></a>

### 5.2 Printing Backtrace

There is a helper function [`PRINT-BACKTRACE`][1cc9] for extracting and printing backtrace, which can be used
separately from logging. One use case is to render backtrace on the web page when a
site is in a debug mode:

```
CL-USER> (log4cl-extras/error:print-backtrace :depth 3)
Traceback (most recent call last):
   0 File "/Users/art/.roswell/src/sbcl-2.0.11/src/code/eval.lisp", line 291
       In `SB-INT:SIMPLE-EVAL-IN-LEXENV`
     Args ((`LOG4CL-EXTRAS/ERROR:PRINT-BACKTRACE` :DEPTH 3) #<NULL-LEXENV>)
   1 File "/Users/art/.roswell/src/sbcl-2.0.11/src/code/eval.lisp", line 311
       In EVAL
     Args ((`LOG4CL-EXTRAS/ERROR:PRINT-BACKTRACE` :DEPTH 3))
   2 File "/Users/art/projects/lisp/sly/contrib/slynk-mrepl.lisp"
       In (LAMBDA () :IN `SLYNK-MREPL::MREPL-EVAL-1`)
     Args ()
```

By default, it prints to the \*DEBUG-IO, but you can pass it a `:STREAM` argument
which has the same semantic as a stream for `FORMAT` function.

Other useful parameters are `:DEPTH` and :MAX-CALL-LENTH. They allow to control how
long and wide backtrace will be.

Also, you might pass `:CONDITION`. If it is given, it will be printed after the backtrace.

And finally, you can pass a list of functions to filter arguments before printing.
This way secret or unnecesary long values can be stripped. See the next section to learn
how to not log secret values.

<a id='x-28LOG4CL-EXTRAS-2FERROR-3A-2AMAX-TRACEBACK-DEPTH-2A-20-28VARIABLE-29-29'></a>

- [variable] **\*MAX-TRACEBACK-DEPTH\*** *10*

    Keeps default value for traceback depth logged by [`WITH-LOG-UNHANDLED`][b1b7] macro

<a id='x-28LOG4CL-EXTRAS-2FERROR-3A-2AMAX-CALL-LENGTH-2A-20-28VARIABLE-29-29'></a>

- [variable] **\*MAX-CALL-LENGTH\*** *100*

<a id='x-28LOG4CL-EXTRAS-2FERROR-3A-2AARGS-FILTERS-2A-20-28VARIABLE-29-29'></a>

- [variable] **\*ARGS-FILTERS\*** *NIL*

    Add to this variable functions of two arguments to change arguments before they will be dumped
    as part of the backtrace to the log.
    
    This is not a special variable, because it should be changed system-wide and can be accessedd
    from multiple threads.

<a id='x-28LOG4CL-EXTRAS-2FERROR-3AWITH-LOG-UNHANDLED-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29'></a>

- [macro] **WITH-LOG-UNHANDLED** *(&KEY (DEPTH \*MAX-TRACEBACK-DEPTH\*)) &BODY BODY*

    Logs any `ERROR` condition signaled from the body. Logged message will have a "traceback" field.

<a id='x-28LOG4CL-EXTRAS-2FERROR-3APRINT-BACKTRACE-20FUNCTION-29'></a>

- [function] **PRINT-BACKTRACE** *&KEY (STREAM \*DEBUG-IO\*) (CONDITION NIL) (DEPTH \*MAX-TRACEBACK-DEPTH\*) (MAX-CALL-LENGTH \*MAX-CALL-LENGTH\*) (ARGS-FILTERS \*ARGS-FILTERS\*)*

    A helper to print backtrace. Could be useful to out backtrace
    at places other than logs, for example at a web page.
    
    This function applies the same filtering rules as [`WITH-LOG-UNHANDLED`][b1b7] macro.

<a id='x-28LOG4CL-EXTRAS-2FERROR-3AMAKE-ARGS-FILTER-20FUNCTION-29'></a>

- [function] **MAKE-ARGS-FILTER** *PREDICATE PLACEHOLDER*

    Returns a function, suitable to be used in [`*ARGS-FILTERS*`][7022]
    
    Function `PREDICATE` will be applied to each argument in the frame
    and if it returns T, then argument will be replaced with `PLACEHOLDER`.

<a id='x-28LOG4CL-EXTRAS-2FERROR-3AMAKE-PLACEHOLDER-20FUNCTION-29'></a>

- [function] **MAKE-PLACEHOLDER** *NAME*

    Creates a placeholder for some secret value or omitted argument.
    
    ```
    CL-USER> (log4cl-extras/error:make-placeholder "secret value")
    
    #<secret value>
    ```


<a id='x-28LOG4CL-EXTRAS-2FSECRETS-3A-40KEEPING-SECRETS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29'></a>

## 6 How Keep Secrets Out of Logs

###### \[in package LOG4CL-EXTRAS/SECRETS\]
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

With `LOG4CL-EXTRAS` you can keep values in secret in two ways.

<a id='x-28LOG4CL-EXTRAS-2FSECRETS-3A-40EASY-WAY-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29'></a>

### 6.1 Easy Way

The easiest way, is two wrap all sensitive data using
[secret-values](https://40ants.com/lisp-project-of-the-day/2020/09/0186-secret-values.html)
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

Here is where `LOG4CL-EXTRAS` comes to the resque. It provides a subsystem
`LOG4CL-EXTRAS/SECRETS`. It is optional and is not loaded together with the
primary system.

Earlier, I've mentioned `:ARGS-FILTERS` argument to the [`LOG4CL-EXTRAS/ERROR:PRINT-BACKTRACE`][1cc9] function.
Package `LOG4CL-EXTRAS/SECRETS` provides a function [`MAKE-SECRETS-REPLACER`][e7b0]
which can be used to filter secret values.

We can add it into the global variable [`LOG4CL-EXTRAS/ERROR:*ARGS-FILTERS*`][7022] like this:

```
CL-USER> (ql:quickload :log4cl-extras/secrets)
(:LOG4CL-EXTRAS/SECRETS)
   
CL-USER> (setf log4cl-extras/error:*args-filters*
               (list (log4cl-extras/secrets:make-secrets-replacer)))
(#<CLOSURE (LABELS `LOG4CL-EXTRAS/SECRETS::REMOVE-SECRETS` :IN `LOG4CL-EXTRAS/SECRETS:MAKE-SECRETS-REPLACER`) {1007E4464B}>)
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

<a id='x-28LOG4CL-EXTRAS-2FSECRETS-3A-40HARD-WAY-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29'></a>

### 6.2 Hard Way

Sometimes it is desireable to remove from tracebacks other kinds of data.
For example I don't want to see [Lack](https://github.com/fukamachi/lack/)'s
environments, because of a few reasons:

- they contain cookies and it is insecure to log them;

- they may contain HTTP header with tokens;

- env objects are list with large amount of data and this makes tracebacks unreadable.

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

- a function's name, which can be a symbol or a list like `(:method foo-bar (...))`

- a list of arguments.

Filter should return two values, which can be the same is inputs or a transformed in some way.

For example, we know that the Lack's env is a plist with :REQUEST-METHOD, :REQUEST-URI and other values.
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
               (list 'remove-lack-env-from-frame
                     ;; We need this too to keep DB password safe, remember?
                     (log4cl-extras/secrets:make-secrets-replacer)))
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

For such simple case like replacing args matching a predicate, `LOG4CL-EXTRAS` has a small helper [`LOG4CL-EXTRAS/ERROR:MAKE-ARGS-FILTER:`][a30d]

```
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
```


<a id='x-28LOG4CL-EXTRAS-2FSECRETS-3AMAKE-SECRETS-REPLACER-20FUNCTION-29'></a>

- [function] **MAKE-SECRETS-REPLACER** 

    Returns a function which can be used to filter backtrace arguments.
    
    See [`LOG4CL-EXTRAS/ERROR:*ARGS-FILTERS*`][7022]

  [1a30]: #x-28LOG4CL-EXTRAS-2FERROR-3A-40ERRORS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29 "Logging Unhandled Errors"
  [1cc9]: #x-28LOG4CL-EXTRAS-2FERROR-3APRINT-BACKTRACE-20FUNCTION-29 "(LOG4CL-EXTRAS/ERROR:PRINT-BACKTRACE FUNCTION)"
  [5de7]: #x-28LOG4CL-EXTRAS-2FCONTEXT-3AWITH-FIELDS-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29 "(LOG4CL-EXTRAS/CONTEXT:WITH-FIELDS (40ANTS-DOC/LOCATIVES:MACRO))"
  [6eb5]: #x-28LOG4CL-EXTRAS-2FERROR-3A-40PRINTING-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29 "Printing Backtrace"
  [7022]: #x-28LOG4CL-EXTRAS-2FERROR-3A-2AARGS-FILTERS-2A-20-28VARIABLE-29-29 "(LOG4CL-EXTRAS/ERROR:*ARGS-FILTERS* (VARIABLE))"
  [80ae]: #x-28LOG4CL-EXTRAS-2FCONFIG-3A-40CONFIGURATION-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29 "Configuration"
  [97b1]: #x-28LOG4CL-EXTRAS-2FCONTEXT-3A-40CONTEXT-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29 "Context Fields"
  [a30d]: #x-28LOG4CL-EXTRAS-2FERROR-3AMAKE-ARGS-FILTER-20FUNCTION-29 "(LOG4CL-EXTRAS/ERROR:MAKE-ARGS-FILTER FUNCTION)"
  [b1b7]: #x-28LOG4CL-EXTRAS-2FERROR-3AWITH-LOG-UNHANDLED-20-2840ANTS-DOC-2FLOCATIVES-3AMACRO-29-29 "(LOG4CL-EXTRAS/ERROR:WITH-LOG-UNHANDLED (40ANTS-DOC/LOCATIVES:MACRO))"
  [b622]: #x-28LOG4CL-EXTRAS-2FSECRETS-3A-40KEEPING-SECRETS-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29 "How Keep Secrets Out of Logs"
  [c6fa]: #x-28LOG4CL-EXTRAS-2FDOC-3A-40INSTALLATION-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29 "Installation"
  [d11b]: #x-28-23A-28-2813-29-20BASE-CHAR-20-2E-20-22log4cl-extras-22-29-20ASDF-2FSYSTEM-3ASYSTEM-29 "(#A((13) BASE-CHAR . \"log4cl-extras\") ASDF/SYSTEM:SYSTEM)"
  [e6e1]: #x-28LOG4CL-EXTRAS-2FERROR-3A-40INTRO-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29 "Quickstart"
  [e7b0]: #x-28LOG4CL-EXTRAS-2FSECRETS-3AMAKE-SECRETS-REPLACER-20FUNCTION-29 "(LOG4CL-EXTRAS/SECRETS:MAKE-SECRETS-REPLACER FUNCTION)"
  [f53c]: #x-28LOG4CL-EXTRAS-2FSECRETS-3A-40HARD-WAY-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29 "Hard Way"
  [fe0a]: #x-28LOG4CL-EXTRAS-2FSECRETS-3A-40EASY-WAY-2040ANTS-DOC-2FLOCATIVES-3ASECTION-29 "Easy Way"

* * *
###### \[generated by [40ANTS-DOC](https://40ants.com/doc)\]
