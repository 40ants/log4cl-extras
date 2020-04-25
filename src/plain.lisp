(defpackage #:log4cl-extras/plain
  (:use #:cl)
  (:import-from #:log4cl-extras/context
                #:get-fields)
  (:import-from #:log4cl-extras/utils
                #:print-with-indent
                #:get-timestamp)
  (:export
   #:plain-layout))
(in-package log4cl-extras/plain)


(defun write-plain-item (stream log-func level)
  (let* ((message (with-output-to-string (s)
                    (funcall log-func s)))
         (fields (get-fields))
         (level (log4cl:log-level-to-string level))
         (timestamp (get-timestamp))
         (traceback (alexandria:assoc-value fields "traceback"
                                            :test #'string=)))

    ;; Desired output is like that
    ;; <ERROR> [19:01:07] ultralisp/cron cron.lisp (perform-checks h0)
    ;;   Text message.
    ;;   some: field
    ;;   another: field
    ;;   Traceback: Multiline
    ;;   traceback
    ;;   which easy to read.
    (format stream "<~A> [~A] ~A~%"
            level
            timestamp
            message)

    (when fields
      (format stream "  Fields:~%")
      (loop for (key . value) in fields
            unless (string-equal key
                                 "traceback")
            do (format stream "    ~A: ~A~%"
                       key
                       value)))

    ;; (format stream "DEBUG: ~S~%" fields)
    (when traceback
      (print-with-indent stream "  " traceback))))


(defclass plain-layout (log4cl:layout)
  ())


(defmethod log4cl:layout-to-stream ((layout plain-layout)
                                    stream
                                    logger
                                    level
                                    log-func)
  (declare (ignorable layout logger))
  (write-plain-item stream log-func level)
  (values))
