(defpackage #:log4cl-extras-test/error
  (:use #:cl)
  (:import-from #:rove
                #:deftest
                #:testing
                #:ok)
  (:import-from #:hamcrest/rove
                #:assert-that)
  (:import-from #:log4cl-extras-test/utils
                #:log-message)
  (:import-from #:log4cl-extras/error)
  (:import-from #:hamcrest/matchers
                #:has-plist-entries
                #:_))
(in-package log4cl-extras-test/error)

;; Without this settings compiler might
;; not show variables in stack frames
;; and tests will fail:
(declaim (optimize (debug 3)))


(defun return-backtrace ()
  (log4cl-extras/error:print-backtrace :stream nil))


(defun process-request (uri env)
  "Just a test function to have something in the backtrace"
  (format nil "~A ~A"
          uri
          env)
  (return-backtrace))


(defun remove-cookies (function-name args)
  (let ((new-args (copy-tree args)))
    (setf (getf (second new-args) :cookies)
          :hidden)
    (values function-name
            new-args)))


(deftest test-filter-call-arguments-in-traceback
  (let ((env '(:headers (1 2 3)
               :cookies ("some" "secrets")))
        (uri "/index.html"))
    (testing "By default, ENV argument should contain :COOKIES"
      (let ((backtrace
              (process-request "/index.html"
                               env)))
        (ok (search "secrets" backtrace))))

    (testing "But we can write a function for filtering"
      (let ((original-env (copy-tree env)))
        (multiple-value-bind (func-name arguments)
            (remove-cookies 'process-request (list uri env))
          (declare (ignore func-name))
          
          (testing "This function should not change original arguments"
            (ok (equal env original-env)))
          (testing "And it should return a new symbol and arguments as a two values"
            (let ((new-env (second arguments)))
              (ok (equal new-env
                         '(:headers (1 2 3)
                           :cookies :hidden))))))))

    (testing "When function is added to \"log4cl-extras/error:*args-filters*\", it can change arguments in a backtrace"
      (let ((prev-value log4cl-extras/error:*args-filters*))
        (setf log4cl-extras/error:*args-filters*
              (list 'remove-cookies))
        (unwind-protect
             (testing "Now backtrace shouldn't include secret values"
               (let ((backtrace
                       (process-request "/index.html"
                                        env)))
                 (ok (not (search "secrets" backtrace)))))
          (setf log4cl-extras/error:*args-filters*
                prev-value))))))
