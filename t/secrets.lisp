(defpackage #:log4cl-extras-test/secrets
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
  (:import-from #:log4cl-extras/secrets
                #:make-secrets-replacer)
  (:import-from #:log4cl-extras/error
                #:placeholder-name
                #:placeholder-p)
  (:import-from #:secret-values
                #:conceal-value))
(in-package log4cl-extras-test/secrets)

;; Without this settings compiler might
;; not show variables in stack frames
;; and tests will fail:
(declaim (optimize (debug 3)))


(deftest test-secrets-replacer
  (let ((remover (make-secrets-replacer)))
    (testing "Remover should replace SECRET-VALUE with a placeholder"
      (multiple-value-bind (func-name result)
          (funcall remover
                   'foo
                   (list :blah (conceal-value "Passw0rd")))
        (declare (ignore func-name))
        (ok (eql (first result)
                 :blah))
        (ok (placeholder-p (second result)))
        (ok (string= (placeholder-name (second result))
                     "secret value"))))

    (testing "Remover should remember the secret values and replace them in raw form too"
      ;; This is necessary, because traceback can match the situation when DB error occur
      ;; and DB password is already unwrapped in some frames.

      (multiple-value-bind (func-name result)
          (funcall remover
                   'foo
                   (list :blah
                         ;; This is a secret in raw form,
                         ;; and not it should be replaced,
                         ;; because our replacer already
                         ;; learned from the first part of
                         ;; the test, that this value is a
                         ;; secret.
                         "Passw0rd"))
        (declare (ignore func-name))
        (ok (eql (first result)
                 :blah))
        (ok (placeholder-p (second result)))
        (ok (string= (placeholder-name (second result))
                     "secret value"))))))
