(in-package :cl-user)
(defpackage log4cl-json.t.core
  (:use :cl
        :log4cl-json.core
        :prove))
(in-package :log4cl-json.t.core)


(plan 1)

(subtest
    "Log unhandled."
  (labels ((foo ()
             (error "Blah minor"))
           (bar ()
             (foo)))
    
    (multiple-value-bind (line data)
        (with-log-unhandled
            (bar)))))
