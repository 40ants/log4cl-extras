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


(defparameter +format-info+
  (make-instance 'log4cl::pattern-category-format-info
                 :case :downcase
                 :precision 1000
                 :separator nil
                 :start nil))


(defun write-plain-item (stream logger log-func level &key (timezone local-time:*default-timezone*))
  (let* ((message (with-output-to-string (s)
                    (funcall log-func s)))
         (filename (log4cl:logger-file-namestring logger))
         (fields (get-fields))
         (level (log4cl:log-level-to-string level))
         (timestamp (get-timestamp :timezone timezone))
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
    (format stream "<~A> [~A] "
            level
            timestamp)

    (funcall (gethash #\g log4cl::*formatters*)
             stream
             +format-info+
             logger
             0
             0)
    
    (format stream " ~A ("
            filename)

    (funcall (gethash #\C log4cl::*formatters*)
             stream
             +format-info+
             logger
             0
             0)
    
    (format stream ") ~A~%"
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
  ((timezone :initform local-time:*default-timezone*
             :initarg :timezone
             :type local-time::timezone
             :reader get-timezone)))


(defmethod log4cl:layout-to-stream ((layout plain-layout)
                                    stream
                                    logger
                                    level
                                    log-func)
  (declare (ignorable layout logger))
  (write-plain-item stream logger log-func level :timezone (get-timezone layout))
  (values))
