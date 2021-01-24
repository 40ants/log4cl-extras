(defpackage #:log4cl-extras/error
  (:use #:cl)
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
  (:export
   #:with-log-unhandled
   #:*max-traceback-depth*
   #:*max-call-length*
   #:print-backtrace
   #:*args-filters*
   #:make-placeholder
   #:placeholder-name
   #:placeholder-p
   #:make-args-filter))
(in-package log4cl-extras/error)


(define-global-var *max-traceback-depth* 10)
(define-global-var *max-call-length* 100)

(define-global-var *args-filters* nil
  "Add to this variable functions of two arguments to change arguments before they will be dumped
   as part of the backtrace to the log.

   This is not a special variable, because it should be changed system-wide and can be accessedd
   from multiple threads.")


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
            (check-symbol (second call)))
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
         ;; Somtimes frames can have a call like a string:
         ;; "foreign function: call_into_lisp"
         nil)))))


(defun get-backtrace ()
  (let ((full-stack (dissect:stack)))
    (delete-if #'from-current-package
               full-stack)))


(defun apply-args-filters (func-name args &key (args-filters *args-filters*))
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


(defvar *d* nil)


(defun prepare (frame args-filters)
  (multiple-value-bind (call args)
      (apply-args-filters (dissect:call frame)
                          (dissect:args frame)
                          :args-filters args-filters)
    (list call args
          (dissect:file frame)
          (dissect:line frame))))


(defun print-backtrace (&key
                        (stream *debug-io*)
                        (condition nil)
                        (depth *max-traceback-depth*)
                        (max-call-length *max-call-length*)
                        (args-filters *args-filters*))
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
              (format stream "~%Condition: ~A"
                      condition)))
        (error (another-condition)
          (format stream "Unable to get traceback because of another error during printing:~%~A"
                  another-condition))))))


(defmacro with-log-unhandled ((&key (depth *max-traceback-depth*)) &body body)
  (alexandria:with-gensyms (tb-as-string)
    `(handler-bind
         ((error (lambda (condition)
                   (let ((,tb-as-string
                           (print-backtrace :stream nil
                                            :condition condition
                                            :depth ,depth)))
                     (with-fields (:traceback ,tb-as-string)
                       (log:error "Unhandled exception"))))))
       ,@body)))


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
"
  (check-type name string)
  (make-instance 'placeholder :name name))


(defun placeholder-p (obj)
  (typep obj 'placeholder))


(defun make-args-filter (predicate placeholder)
  "Returns a function, suitable to be used in *ARGS-FILTERS*

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
