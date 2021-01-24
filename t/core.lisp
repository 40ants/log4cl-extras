(defpackage log4cl-extras-test/core
  (:use :cl))
(in-package :log4cl-extras-test/core)


;; (plan 1)

;; (subtest
;;     "Log unhandled."
;;   (labels ((foo ()
;;              (error "Blah minor"))
;;            (bar ()
;;              (foo)))

;;     (multiple-value-bind (line data)
;;         (with-log-unhandled ()
;;             (bar)))))
;; (finalize)
