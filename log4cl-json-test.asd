(in-package :cl-user)
(defpackage log4cl-json-test-asd
  (:use :cl :asdf))
(in-package :log4cl-json-test-asd)


(defsystem log4cl-json-test
  :author "Alexander Artemenko"
  :license "BSD"
  :depends-on (:log4cl-json
               :hamcrest-prove)
  :components ((:module "t"
                :components
                ((:test-file "appender"))))
  :description "Test system for log4cl-json"

  :defsystem-depends-on (:prove-asdf)
  :perform (test-op :after (op c)
                    (funcall (intern #.(string :run-test-system) :prove-asdf) c)
                    (asdf:clear-system c)))
