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
  (:export
   #:with-log-unhandled
   #:*max-traceback-depth*
   #:*max-call-length*))
(in-package log4cl-extras/error)


(defvar *default-skip-frames*
  ;; On CCL and SBLC first four frames are from signal handling code.
  #+(or ccl sbcl)
  4
  #-(or ccl sbcl)
  0)



(define-global-var *max-traceback-depth* 10)
(define-global-var *max-call-length* 100)


(defun get-traceback (&key
                      (skip *default-skip-frames*)
                      (depth *max-traceback-depth*))
  (subseq (dissect:stack)
          skip (+ skip depth)))



(defun format-frame (frame &key (max-call-length *max-call-length*))
  (flet ((safe-to-string (item)
           (handler-case (format nil "~S" item)
             (error (another-condition)
               (format nil "[unable to format because of ~S]"
                       another-condition)))))
    (format nil "  File \"~A\", line ~A, in ~A
    (~{~A~^ ~})"
            (dissect:file frame)
            (dissect:line frame)
            (limit-length (remove-newlines
                           ;; we need to format, because call will return a symbol or a list
                           (safe-to-string (dissect:call frame)))
                          max-call-length)
            (mapcar #'safe-to-string
                    (dissect:args frame)))))


(defun traceback-to-string (tb &key (max-call-length *max-call-length*))
  (handler-case
      (format nil "Traceback (most recent call last):
~{~a
~}" (mapcar (lambda (item)
              (format-frame item
                            :max-call-length max-call-length))
            tb))
    (error (another-condition)
      (format nil "Unable to get traceback because of another error:~%~A"
              another-condition))))


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
