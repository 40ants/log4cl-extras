(defsystem log4cl-extras-test
  :name "log4cl-extras-test"
  :author "Alexander Artemenko"
  :license "BSD"
  :depends-on (:log4cl-extras
               :hamcrest/prove)
  :components ((:module "t"
                :components
                ((:file "utils")
                 (:test-file "core")
                 (:test-file "appender"))))
  :description "Test system for log4cl-extras"

  :defsystem-depends-on (:prove-asdf)
  :perform (test-op :after (op c)
                    (funcall (intern #.(string :run-test-system) :prove-asdf) c)
                    (asdf:clear-system c)))
