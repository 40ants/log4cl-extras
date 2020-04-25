(defpackage #:log4cl-extras/error
  (:use #:cl)
  (:import-from #:dissect)
  (:import-from #:log4cl-extras/context
                #:with-fields)
  (:import-from #:log4cl-extras/utils
                #:remove-newlines
                #:limit-length)
  (:export
   #:with-log-unhandled))
(in-package log4cl-extras/error)


(defvar *default-skip-frames*
  ;; On CCL and SBLC first four frames are from signal handling code.
  #+(or ccl sbcl)
  4
  #-(or ccl sbcl)
  0)


(defun get-traceback (&key
                        (skip *default-skip-frames*)
                        (depth 10))
  (subseq (dissect:stack)
          skip (+ skip depth)))



(defun format-frame (frame &key (max-call-length 10))
  (format nil "  File \"~a\", line ~a, in ~a
    ~S"
          (dissect:file frame)
          (dissect:line frame)
          (limit-length (remove-newlines
                         ;; we need to format, because call will return a symbol or a list
                         (format nil "~a" (dissect:call frame)))
                        max-call-length)
          (list* (dissect:call frame)
                 (dissect:args frame))))


(defun traceback-to-string (tb &key (max-call-length 10))
  (format nil "Traceback (most recent call last):
~{~a
~}" (mapcar (lambda (item)
              (format-frame item
                            :max-call-length max-call-length))
            tb)))


(defmacro with-log-unhandled (() &body body)
  (alexandria:with-gensyms (tb tb-as-string)
    `(handler-bind
         ((error (lambda (condition)
                   (let* ((,tb (get-traceback))
                          (,tb-as-string (format nil "~A~2%Condition: ~A"
                                                 (traceback-to-string ,tb)
                                                 condition)))
                     (with-fields (:traceback ,tb-as-string)
                       (log:error "Unhandled exception"))))))
       ,@body)))

