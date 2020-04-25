(defpackage #:log4cl-extras/context
  (:use #:cl)
  ;; (:import-from #:iterate
  ;;               #:iterate
  ;;               #:for)
  (:export #:with-fields
           #:get-fields))
(in-package log4cl-extras/context)


(defvar *fields*
  nil
  "A stack of data fields to be serialized to JSON

Fields are stored as a plist, and transformed into an alist before serialization.")


(defun get-fields ()
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
  `(let ((*fields* (append (list ,@fields) *fields*)))
     (progn ,@body)))
