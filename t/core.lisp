(in-package :cl-user)
(defpackage log4cl-extras.t.core
  (:use :cl
        :log4cl-extras/error
        :prove))
(in-package :log4cl-extras.t.core)


(plan 1)

(subtest
    "Log unhandled."
  (labels ((foo ()
             (error "Blah minor"))
           (bar ()
             (foo)))

    (multiple-value-bind (line data)
        (with-log-unhandled ()
            (bar)))))
(finalize)
