(defpackage log4cl-json.core
  (:use :cl)
  (:export :setup
           :with-log-unhandled))
(in-package :log4cl-json.core)


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


(defun remove-newlines (text)
  (substitute #\Space #\Newline text))


(defun limit-length (text max-len)
  (if (> (length text)
         (- max-len 1))
      (concatenate 'string
                   (subseq text 0 (- max-len 1))
                   "…")
      text))


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
                   (declare (ignorable condition))
                   
                   (let* ((,tb (get-traceback))
                          (,tb-as-string (traceback-to-string ,tb)))
                     (log4cl-json.appender:with-fields
                         (:|traceback| ,tb-as-string)
                       (log:error "Unhandled exception"))))))
       ,@body)))


(defun setup (&key (stream *standard-output*)
                (remove-all-appenders t)
                (level :info))
  "Setup JSON logger to output data to the stream.

By default, it will send data to STDOUT."
  
  (when remove-all-appenders
    (log4cl:remove-all-appenders log4cl:*root-logger*))

  (log4cl:add-appender log4cl:*root-logger*
                       (make-instance 'log4cl-json.appender:json-appender
                                      :stream stream))

  (log4cl:set-log-level log4cl:*root-logger*
                        level))
