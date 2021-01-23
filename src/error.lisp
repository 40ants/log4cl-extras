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
   #:placeholder-p))
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
           ((lambda)
            (assert (eql (third call) :in))
            (when (typep (fourth call) 'symbol)
              ;; For top-level lambdas, fourth part
              ;; will be a string with the path to the
              ;; source file. We consider such forms
              ;; as being not in the current package.
              (check-symbol (fourth call))))
           ((flet labels)
            (assert (eql (third call) :in))
            (if (typep (fourth call) 'symbol)
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


(defun get-traceback (&key
                      (depth *max-traceback-depth*))
  (let* ((full-stack (dissect:stack))
         (filtered-stack (remove-if #'from-current-package
                                    full-stack)))
    (subseq filtered-stack
            0 depth)))



(defun traceback-to-string (tb &key (max-call-length *max-call-length*)
                                    (args-filters *args-filters*))
  (handler-case
      (format nil "Traceback (most recent call last):
~{~a
~}" (loop for frame in tb
          for idx upfrom 0
          collect (format-frame idx
                                frame
                                :max-call-length max-call-length
                                :args-filters args-filters)))
    (error (another-condition)
      (format nil "Unable to get traceback because of another error:~%~A"
              another-condition))))


(defun apply-args-filters (func-name args &key (args-filters *args-filters*))
  (loop for filter-func in args-filters
        for (new-func-name new-args) = (multiple-value-list
                                        (funcall filter-func func-name args))
        do (setf func-name new-func-name
                 args new-args)
        finally (return (values func-name
                                args))))


(defun format-frame (idx frame &key (max-call-length *max-call-length*)
                                    (args-filters *args-filters*))
  (flet ((safe-to-string (item)
           (handler-case (format nil "~S" item)
             (error (another-condition)
               (format nil "[unable to format because of ~S]"
                       another-condition)))))
    (multiple-value-bind (call args)
        (apply-args-filters (dissect:call frame)
                            (dissect:args frame)
                            :args-filters args-filters)
      (format nil "~4@A File \"~A\", line ~A
       In ~A
     Args (~{~A~^ ~})"
              idx
              (dissect:file frame)
              (dissect:line frame)
              (limit-length (remove-newlines
                             ;; we need to format, because call will return a symbol or a list
                             (safe-to-string call))
                            max-call-length)
              (mapcar #'safe-to-string
                      args)))))


(defvar *d* nil)

(defun print-backtrace (condition
                        &key
                        (stream *debug-io*)
                        (max-call-length *max-call-length*)
                        (depth *max-traceback-depth*))
  (let ((tb (get-traceback :depth depth)))
    (traceback-to-string tb :max-call-length max-call-length)
    ;; (with-output-to-stream (s stream)
    ;;   )
    ))


(defmacro with-log-unhandled ((&key (depth *max-traceback-depth*)) &body body)
  (alexandria:with-gensyms (tb tb-as-string)
    `(handler-bind
         ((error (lambda (condition)
                   (let* ((,tb (get-traceback :depth ,depth))
                          (,tb-as-string (format nil "~A~2%Condition: ~A"
                                                 (traceback-to-string ,tb)
                                                 condition)))
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
