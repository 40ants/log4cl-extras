(in-package :cl-user)
(defpackage log4cl-json.t.appender
  (:use :cl
        :log4cl-json.appender
        :prove
        :hamcrest.prove))
(in-package :log4cl-json.t.appender)


;; NOTE: To run this test file, execute `(asdf:test-system :log4cl-json)' in your Lisp.

(plan 2)


(subtest
    "Basic output without fields."
  (flet ((log-message (message &key (level log4cl:+log-level-debug+))
           "Pass message through appender and return resulting JSON as a string."
           (with-output-to-string (stream)
             (let ((appender (make-instance 'json-appender
                                            :stream stream)))
               (log4cl:appender-do-append appender
                                          log4cl:*root-logger*
                                          level
                                          (lambda (s)
                                            (princ message
                                                   s)))))))
    (subtest
        "When there is no fields, key '@fields' should have
only :|level| field and @message and @timestamp keys should be in the log item."
      (let* ((line (log-message "Some"))
             (data (jonathan:parse line)))

        (assert-that
         data
         (has-plist-entries :|@message| "Some"
                            :|@timestamp| _
                            :|@fields| (has-plist-entries
                                        :|level| "DEBUG")))))))


(subtest
    "Adding fields with \"with-fields\" macro."
  (flet ((log-message (message &key (level log4cl:+log-level-debug+))
           "Pass message through appender and return resulting JSON as a string."
           (with-output-to-string (stream)
             (let ((appender (make-instance 'json-appender
                                            :stream stream)))
               (log4cl:appender-do-append appender
                                          log4cl:*root-logger*
                                          level
                                          (lambda (s)
                                            (princ message
                                                   s)))))))
    (subtest
        "\"with-fields\" macro can add one field."
      (let* ((line (with-fields (:|request-id| 100500)
                     (log-message "Some")))
             (data (jonathan:parse line)))

        (assert-that
         data
         (has-plist-entries :|@message| "Some"
                            :|@timestamp| _
                            :|@fields| (has-plist-entries
                                        :|request-id| 100500
                                        :|level| "DEBUG")))))

    (subtest
        "\"with-fields\" macro can add many fields."
      (let* ((line (with-fields (:|request-id| 100500
                                 :|org-id| 42 )
                     (log-message "Some")))
             (data (jonathan:parse line)))

        (assert-that
         data
         (has-plist-entries :|@message| "Some"
                            :|@timestamp| _
                            :|@fields| (has-plist-entries
                                        :|request-id| 100500
                                        :|org-id| 42
                                        :|level| "DEBUG")))))))


(finalize)
