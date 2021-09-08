(uiop:define-package #:log4cl-extras/secrets
  (:use #:cl)
  (:import-from #:pythonic-string-reader
                #:pythonic-string-syntax)
  (:import-from #:named-readtables
                #:in-readtable)
  (:import-from #:global-vars
                #:define-global-var)
  (:import-from #:log4cl-extras/error
                #:make-placeholder)
  (:import-from #:secret-values
                #:secret-value
                #:reveal-value)
  (:import-from #:40ants-doc
                #:defsection)
  (:export
   #:make-secrets-replacer))
(in-package log4cl-extras/secrets)

(in-readtable pythonic-string-syntax)


(defsection @keeping-secrets (:title "How Keep Secrets Out of Logs"
                              :ignore-words ("LOG4CL-EXTRAS"
                                             "AUTHENTICATE"
                                             "10036CB183"
                                             "PASSWORD"
                                             "POSTGRES"))
  """
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

"""
  (@easy-way section)
  (@hard-way section)
  (make-secrets-replacer function))


(40ants-doc:defsection @easy-way (:title "Easy Way"
                                  :ignore-words ("LOG4CL-EXTRAS/SECRETS"
                                                 "SECRET-VALUES:SECRET-VALUE"))
  """
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

Here is where `LOG4CL-EXTRAS` comes to the resque. It provides a package
[LOG4CL-EXTRAS/SECRETS][package]. It is optional and is not loaded together with the
primary system.

Earlier, I've mentioned :ARGS-FILTERS argument to the LOG4CL-EXTRAS/ERROR:PRINT-BACKTRACE function.
Package [LOG4CL-EXTRAS/SECRETS][package] provides a function MAKE-SECRETS-REPLACER
which can be used to filter secret values.

We can add it into the global variable LOG4CL-EXTRAS/ERROR:*ARGS-FILTERS* like this:

```
CL-USER> (ql:quickload :log4cl-extras/secrets)
(:LOG4CL-EXTRAS/SECRETS)
   
CL-USER> (setf log4cl-extras/error:*args-filters*
               (list (log4cl-extras/secrets:make-secrets-replacer)))
(#<CLOSURE (LABELS LOG4CL-EXTRAS/SECRETS::REMOVE-SECRETS :IN LOG4CL-EXTRAS/SECRETS:MAKE-SECRETS-REPLACER) {1007E4464B}>)
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
""")


(40ants-doc:defsection @hard-way (:title "Hard Way"
                                  :export nil)
  """
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

For such simple case like replacing args matching a predicate, `LOG4CL-EXTRAS` has a small helper LOG4CL-EXTRAS/ERROR:MAKE-ARGS-FILTER:

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
""")


(define-global-var +secret-placeholder+
    (make-placeholder "secret value"))


(defun make-secrets-replacer ()
  "Returns a function which can be used to filter backtrace arguments.

   See LOG4CL-EXTRAS/ERROR:*ARGS-FILTERS*"
  (let ((seen-secrets (make-hash-table :test 'equal
                                       #+sbcl
                                       :synchronized
                                       #+sbcl t)))
    (labels ((already-seen (raw-secret)
               (gethash raw-secret
                        seen-secrets))
             (remember-secret (secret)
               (setf (gethash (reveal-value secret)
                              seen-secrets)
                     t))
             (remove-secrets (func-name args)
               (let ((new-args
                       (loop for arg in args
                             for is-secret-value = (typep arg 'secret-value)
                             if is-secret-value
                             do (remember-secret arg)
                             if (or is-secret-value
                                    (already-seen arg))
                             collect +secret-placeholder+
                             else
                             collect arg)))
                 (values func-name
                         new-args))))
        #'remove-secrets)))
