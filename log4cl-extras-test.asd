(defsystem "log4cl-extras-test"
  :author "Alexander Artemenko"
  :license "BSD"
  :class :package-inferred-system
  :pathname "t"
  :depends-on ("hamcrest"
               "log4cl-extras-test/core"
               "log4cl-extras-test/appender"
               "log4cl-extras-test/error"
               "log4cl-extras-test/secrets")
  :description "Test system for log4cl-extras"

  :perform (test-op (op c)
                    (unless (symbol-call :rove :run c)
                      (error "Tests failed"))))
