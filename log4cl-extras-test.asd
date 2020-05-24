(defsystem log4cl-json-test
  :name "log4cl-json-test"
  :author "Alexander Artemenko"
  :license "BSD"
  :depends-on (:log4cl-json
               :hamcrest-prove)
  :components ((:module "t"
                :components
                ((:file "utils")
                 (:test-file "core")
                 (:test-file "appender"))))
  :description "Test system for log4cl-json"

  :defsystem-depends-on (:prove-asdf)
  :perform (test-op :after (op c)
                    (funcall (intern #.(string :run-test-system) :prove-asdf) c)
                    (asdf:clear-system c)))
