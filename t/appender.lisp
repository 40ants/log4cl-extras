(defpackage log4cl-extras-test/appender
  (:use #:cl)
  (:import-from #:rove
                #:deftest
                #:testing
                #:ok)
  (:import-from #:hamcrest/rove
                #:assert-that)
  (:import-from #:log4cl-extras-test/utils
                #:log-message)
  (:import-from #:hamcrest/matchers
                #:has-plist-entries
                #:_)
  ;; (:use :cl
  ;;       :log4cl-extras/appenders
  ;;       :log4cl-extras/context
  ;;       :prove
  ;;       :hamcrest/prove
  ;;       :log4cl-extras-test/utils)
  )
(in-package :log4cl-extras-test/appender)


;; NOTE: To run this test file, execute `(asdf:test-system :log4cl-extras)' in your Lisp.

;; (deftest test-default-field-content
;;   (testing "When there is no fields, key '@fields' should have
;; only :|level| field and @message and @timestamp keys should be in the log item."
;;     (multiple-value-bind (line data)
;;         (log-message "Some")
;;       (declare (ignore line))
      
;;       (assert-that data
;;                    (has-plist-entries :|@message| "Some"
;;                                       :|@timestamp| _
;;                                       :|@fields| (has-plist-entries
;;                                                   :|level| "DEBUG"))))))


;; (subtest
;;     "Adding fields with \"with-fields\" macro."
;;   (subtest
;;       "\"with-fields\" macro can add one field."
;;     (multiple-value-bind (line data)
;;         (with-fields (:|request-id| 100500)
;;           (log-message "Some"))
;;       (declare (ignorable line))

;;       (assert-that
;;        data
;;        (has-plist-entries :|@message| "Some"
;;                           :|@timestamp| _
;;                           :|@fields| (has-plist-entries
;;                                       :|request-id| 100500
;;                                       :|level| "DEBUG")))))

;;   (subtest
;;       "\"with-fields\" macro can add many fields."
;;     (multiple-value-bind (line data)
;;         (with-fields (:|request-id| 100500
;;                        :|org-id| 42 )
;;           (log-message "Some"))
;;       (declare (ignorable line))
        
;;       (assert-that
;;        data
;;        (has-plist-entries :|@message| "Some"
;;                           :|@timestamp| _
;;                           :|@fields| (has-plist-entries
;;                                       :|request-id| 100500
;;                                       :|org-id| 42
;;                                       :|level| "DEBUG"))))))


;; (finalize)
