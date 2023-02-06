(defsystem log4cl-extras
  :name "log4cl-extras"
  :author "Alexander Artemenko"
  :license "BSD"
  :class :40ants-asdf-system
  :path-to-changelog "src/changelog.lisp"
  :pathname "src"
  :defsystem-depends-on ("40ants-asdf-system")
  :depends-on (;; This component intentionally
               ;; not listed, because it requires
               ;; additional dependency system :secret-values
               ;;
               ;; "log4cl-extras/secrets"
               "log4cl-extras/config"
               "log4cl-extras/error")
  :description "A bunch of addons to LOG4CL: JSON appender, context fields, cross-finger appender, etc."
  :long-description "

This library extends LOG4CL system in a few ways:

* It helps with configuration of multiple appenders and layouts.
* Has a facility to catch context fields and to log them.
* Has a macro to log unhandled errors.
* Adds a layout to write messages as JSON, which is useful for production as makes easier to parse and process such logs.
* Uses the appenders which are not disabled in case of some error which again, should be useful for production.

"
  :homepage "https://40ants.com/log4cl-extras/"
  :bug-tracker "https://github.com/40ants/log4cl-extras/issues"
  :source-control (:git "https://github.com/40ants/log4cl-extras")
  :in-order-to ((test-op (test-op log4cl-extras-test))))
