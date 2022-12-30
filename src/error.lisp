(uiop:define-package #:log4cl-extras/error
  (:use #:cl)
  (:import-from #:pythonic-string-reader
                #:pythonic-string-syntax)
  (:import-from #:named-readtables
                #:in-readtable)
  (:import-from #:dissect)
  (:import-from #:log4cl)
  (:import-from #:log4cl-extras/context
                #:with-fields)
  (:import-from #:log4cl-extras/utils
                #:remove-newlines
                #:limit-length)
  (:import-from #:global-vars
                #:define-global-var)
  (:import-from #:with-output-to-stream
                #:with-output-to-stream)
  (:import-from #:alexandria
                #:curry)
  (:export
   #:with-log-unhandled
   #:*max-traceback-depth*
   #:*max-call-length*
   #:print-backtrace
   #:*args-filters*
   #:make-placeholder
   #:placeholder-name
   #:placeholder-p
   #:make-args-filter
   #:placeholder
   #:*args-filter-constructors*))
(in-package log4cl-extras/error)

(in-readtable pythonic-string-syntax)


(40ants-doc:defsection @errors (:title "Logging Unhandled Errors"
                                :ignore-words ("SBCL"))
  (@intro section)
  (@printing section)
  
  "## API"
  
  (*max-traceback-depth* variable)
  (*max-call-length* variable)
  (*args-filters* variable)
  (*args-filter-constructors* variable)
  (with-log-unhandled macro)
  (print-backtrace function)
  (make-args-filter function)
  (placeholder class)
  (make-placeholder function)
  (placeholder-p function)
  (placeholder-name (reader placeholder)))


(40ants-doc:defsection @intro (:title "Quickstart"
                               :export nil)
  """
If you want to log unhandled signals traceback, then use WITH-LOG-UNHANDLED macro.

Usually it is good idea, to use WITH-LOG-UNHANDLED in the main function or in a function which handles
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
      (SB-INT:SIMPLE-EVAL-IN-LEXENV
       (LOG4CL-EXTRAS/ERROR:WITH-LOG-UNHANDLED NIL
         (BAR))
       #<NULL-LEXENV>)
    ...
       #<CLOSURE (LAMBDA () :IN SLYNK::CALL-WITH-LISTENER) {100A6B043B}>)
     
     
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

""")


(40ants-doc:defsection @printing (:title "Printing Backtrace"
                                  :export nil)
  """
There is a helper function PRINT-BACKTRACE for extracting and printing backtrace, which can be used
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

By default, it prints to the *DEBUG-IO*, but you can pass it a :STREAM argument
which has the same semantic as a stream for FORMAT function.

Other useful parameters are :DEPTH and :MAX-CALL-LENGTH. They allow to control how
long and wide backtrace will be.

Also, you might pass :CONDITION. If it is given, it will be printed after the backtrace.

And finally, you can pass a list of functions to filter arguments before printing.
This way secret or unnecesary long values can be stripped. See the next section to learn
how to not log secret values.

""")


(define-global-var *max-traceback-depth* 10
  "Keeps default value for traceback depth logged by WITH-LOG-UNHANDLED macro")

(define-global-var *max-call-length* 100
  "The max length of each line in a traceback. It is useful to limit it because otherwise some log collectors can discard the whole log entry.")

(define-global-var *args-filters* nil
  "Add to this variable functions of two arguments to change arguments before they will be dumped
   as part of the backtrace to the log.

   This is not a special variable, because it should be changed system-wide and can be accessedd
   from multiple threads.")


(define-global-var *args-filter-constructors* nil
  "Add to this variable functions of zero arguments. Each function should return an argument filter
   function suitable for using in the *ARGS-FILTERS* variable.

   These constructors can be used to create argument filters with state suitable for
   processing of a single backtrace only. For example,
   LOG4CL-EXTRAS/SECRETS:MAKE-SECRETS-REPLACER function, keeps tracks every secret value used in
   all frames of the backtrace. We don't want to keep these values forever and to mix secrets
   of different users in the same place. Thus this function should be used as a \"constructor\".
   In this case it will create a new secret replacer for every backtrace to be processed.
 ")


(defun from-current-package (frame)
  (let ((call (dissect:call frame))
        ;; We'll keep here the current package
        ;; on the moment when 'from-current-package
        ;; function was compiled.
        (package #.*package*))
    (flet ((check-symbol (s)
             (eql (symbol-package s)
                  package)))
      (etypecase call
        (symbol (check-symbol call))
        (cons
         (case (car call)
           ((:method)
            (let ((real-call (second call)))
              (etypecase real-call
                (symbol
                 (check-symbol real-call))
                ;; Call might be something like
                ;; (SETF the-function).
                (cons
                 (some #'check-symbol
                       real-call)))))
           ((lambda flet labels)
            (when (and (eql (third call) :in)
                       (typep (fourth call) 'symbol))
              ;; For top-level flets and labels, fourth part
              ;; will be a string with the path to the
              ;; source file. We consider such forms
              ;; as being not in the current package.
              (check-symbol (fourth call))))
           ;; for other types we consider frame not belonging
           ;; to the log4cl-extras package
           (t nil)))
        (string
         ;; Sometimes frames can have a call like a string:
         ;; "foreign function: call_into_lisp"
         nil)
        (function
         ;; On CCL frames can contain lambda functions as a value of CALL
         nil)
        #+ccl
        (standard-method
         (check-symbol
          (ccl:method-name call)))))))


(defun get-backtrace ()
  (let ((full-stack (dissect:stack)))
    (delete-if #'from-current-package
               full-stack)))


(defun get-current-args-filters ()
  (append (mapcar #'funcall
                  *args-filter-constructors*)
          *args-filters*))


(defun apply-args-filters (func-name args &key (args-filters (get-current-args-filters)))
  (loop for filter-func in args-filters
        for (new-func-name new-args) = (multiple-value-list
                                        (funcall filter-func func-name args))
        do (setf func-name new-func-name
                 args new-args)
        finally (return (values func-name
                                args))))


(defun format-frame (stream idx call args file line &key
                                                    (max-call-length *max-call-length*))
  (flet ((safe-to-string (item)
           (handler-case (format nil "~S" item)
             (error (another-condition)
               (format stream "[unable to format because of ~S]"
                       another-condition)))))
    ;; If file is unknown, then we'll output "unknown"
    ;; Line printed only if it is known.
    (format stream "~4@A File \"~A\"~@[, line ~A~]
       In ~A
     Args (~{~A~^ ~})
"
            idx
            (or file
                "unknown")
            line
            (limit-length (remove-newlines
                           ;; we need to format, because call will return a symbol or a list
                           (safe-to-string call))
                          max-call-length)
            (mapcar #'safe-to-string
                    args))))


(defun prepare (frame args-filters)
  (multiple-value-bind (call args)
      (apply-args-filters (dissect:call frame)
                          (dissect:args frame)
                          :args-filters args-filters)
    (list call args
          (dissect:file frame)
          (dissect:line frame))))


(defun format-condition-object (stream condition)
  (format stream "Condition ~S: ~A"
          (type-of condition)
          condition))


(defun print-backtrace (&key
                        (stream *debug-io*)
                        (condition nil)
                        (depth *max-traceback-depth*)
                        (max-call-length *max-call-length*)
                        (args-filters (get-current-args-filters))
                        (format-condition #'format-condition-object))
  "A helper to print backtrace. Could be useful to out backtrace
   at places other than logs, for example at a web page.

   This function applies the same filtering rules as WITH-LOG-UNHANDLED macro.

   By default condition description is printed like this:

   ```
   Condition REBLOCKS-WEBSOCKET:NO-ACTIVE-WEBSOCKETS: No active websockets bound to the current page.
   ```

   But you can change this by providing an argument FORMAT-CONDITION. It should be a
   function of two arguments: `(stream condition)`.
   "
  (let ((frames (get-backtrace)))
    (with-output-to-stream (stream stream)
      (handler-case
          (progn
            (format stream "Traceback (most recent call last):~%")

            (let ((prepared-frames
                    ;; First, we need to apply filters in a backward order.
                    ;; This way, filters will have a chance to learn about
                    ;; secure-values and to remove their raw form in the higher
                    ;; frames.
                    ;; 
                    ;; For the same reason, at at this step we have to apply prepare
                    ;; to all frames whereas call FORMAT-FRAME only on limited number
                    ;; of frames.
                    (loop for frame in (reverse frames)
                          collect (prepare frame args-filters) into result
                          finally (return (nreverse result)))))
             
              (loop for (call args file line) in prepared-frames
                    ;; Here we a limiting our frames to a given depth
                    for idx from 0 below depth
                    do (format-frame stream
                                     idx
                                     call
                                     args
                                     file
                                     line
                                     :max-call-length max-call-length)))
           
           
            (when condition
              (fresh-line stream)
              (funcall format-condition stream condition)
              (fresh-line stream)))
        (error (another-condition)
          (format stream "Unable to get traceback because of another error during printing:~%~A"
                  another-condition))))))


(defun call-with-log-unhandled (thunk &key
                                        (depth *max-traceback-depth*)
                                        (errors-to-ignore nil))
  (handler-bind
      ((error (lambda (condition)
                (when (or (null errors-to-ignore)
                          (notany (curry #'typep condition)
                                  errors-to-ignore))
                  (let ((tb-as-string
                          (print-backtrace :stream nil
                                           :condition condition
                                           :depth depth)))
                    (with-fields (:traceback tb-as-string)
                      (log:error "Unhandled exception")))))))
    (funcall thunk)))


(defmacro with-log-unhandled ((&key
                                 (depth *max-traceback-depth* depth-given-p)
                                 (errors-to-ignore nil errors-to-ignore-given-p))
                              &body body)
  "Logs any ERROR condition signaled from the body. Logged message will have a \"traceback\" field.

You may specify a list of error classes to ignore as ERRORS-TO-IGNORE argument.
Errors matching (typep err <each-of errors-to-ignore>) will not be logged as \"Unhandled\".
"
  (let ((params (append
                 (when depth-given-p
                   (list :depth depth))
                 (when errors-to-ignore-given-p
                   (list :errors-to-ignore errors-to-ignore)))))
    `(call-with-log-unhandled (lambda () ,@body)
                              ,@params)))


(defclass placeholder ()
  ((name :initarg :name
         :type string
         :reader placeholder-name))
  (:documentation "Objects of this class can be used as replacement to arguments in a backtrace.

They are printed like `#<some-name>`.

This form was choosen to match the way how SBCL shows unused arguments: `#<unused argument>`.

Placeholders should be created with MAKE-PLACEHOLDER function.
"))


(defmethod print-object ((obj placeholder) stream)
  (format stream "#<~A>"
          (slot-value obj 'name)))


(defun make-placeholder (name)
  "Creates a placeholder for some secret value or omitted argument.

   ```
   CL-USER> (log4cl-extras/error:make-placeholder \"secret value\")

   #<secret value>
   ```

   See LOG4CL-EXTRAS/SECRETS::@HARD-WAY section to learn, how to use
   placeholders to remove sensitive information from logs."
  (check-type name string)
  (make-instance 'placeholder :name name))


(defun placeholder-p (obj)
  (typep obj 'placeholder))


(defun make-args-filter (predicate placeholder)
  "Returns a function, suitable to be used in *ARGS-FILTERS* variable.

   Function PREDICATE will be applied to each argument in the frame
   and if it returns T, then argument will be replaced with PLACEHOLDER.
"
  (lambda (func-name args)
    (values func-name
            (loop for arg in args
                  if (funcall predicate arg)
                  collect placeholder
                  else
                  collect arg))))
