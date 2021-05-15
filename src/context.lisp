(uiop:define-package #:log4cl-extras/context
  (:use #:cl)
  (:import-from #:pythonic-string-reader
                #:pythonic-string-syntax)
  (:import-from #:named-readtables
                #:in-readtable)
  (:import-from #:40ants-doc
                #:defsection)
  (:export #:with-fields
           #:get-fields))
(in-package log4cl-extras/context)

(in-readtable pythonic-string-syntax)


(defsection @context (:title "Context Fields")
  """
Macro WITH-FIELDS let to to capture some information into the dynamic variable.
All messages logged inside the WITH-FIELDS form will have these fields attached:

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

"""
  (with-fields macro)
  (get-fields function))


(defvar *fields*
  nil
  "A stack of data fields to be serialized to JSON

Fields are stored as a plist, and transformed into an alist before serialization.")


(defun get-fields ()
  "Returns an alist of all fields defined using WITH-FIELDS macro in the current stack.

   Keys are returned as downcased strings, prepared for logging."
  (loop with result = nil
        for (key value) on *fields* by #'cddr
        ;; Keys are downcased intentionally, to make log messages
        ;; looks nice.
        do (pushnew (cons (string-downcase (string key))
                          value)
                    result
                    :key #'car
                    :test #'string=)
        finally (return result)))


(defmacro with-fields ((&rest fields) &body body)
  "Captures content of given fields into a dynamic variable.

   These fields will be logged along with any log entry
   inside the WITH-FIELDS body."
  `(let ((*fields* (append (list ,@fields) *fields*)))
     (progn ,@body)))
