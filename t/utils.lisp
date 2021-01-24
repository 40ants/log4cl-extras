(defpackage log4cl-extras-test/utils
  (:use #:cl
        #:log4cl-extras/appenders)
  (:import-from #:jonathan)
  (:export #:log-message))
(in-package :log4cl-extras-test/utils)


(defun log-message (message &key (level log4cl:+log-level-debug+))
  "Pass message through appender and return resulting JSON as a string and parsed alist."
  (let ((result
         (with-output-to-string (stream)
           (let ((appender (make-instance 'json-appender
                                          :stream stream)))
             (log4cl:appender-do-append appender
                                        log4cl:*root-logger*
                                        level
                                        (lambda (s)
                                          (princ message
                                                 s)))))))
    (values result
            (jonathan:parse result))))
