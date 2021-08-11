(uiop:define-package #:log4cl-extras/doc
  (:use #:cl)
  (:import-from #:pythonic-string-reader
                #:pythonic-string-syntax)
  (:import-from #:named-readtables
                #:in-readtable)
  (:import-from #:40ants-doc
                #:defsection)
  (:import-from #:log4cl-extras/config
                #:@configuration)
  (:import-from #:log4cl-extras/context
                #:@context)
  (:import-from #:log4cl-extras/error
                #:@errors)
  (:import-from #:log4cl-extras/secrets
                #:@keeping-secrets))
(in-package log4cl-extras/doc)

(in-readtable pythonic-string-syntax)


(defsection @index (:title "LOG4CL-EXTRAS - Addons for Log4CL"
                    :ignore-words ("JSON"
                                   "HTTP"
                                   "THIS-CONSOLE"
                                   "DAILY"
                                   "FILE"))
  (log4cl-extras system)
  "
[![](https://github-actions.40ants.com/40ants/log4cl-extras/matrix.svg?only=ci.run-tests)](https://github.com/40ants/log4cl-extras/actions)
"
  (@installation section)
  (@configuration section)
  (@context section)
  (@errors section)
  (@keeping-secrets section))


(defsection @installation (:title "Installation")
  """
You can install this library from Quicklisp, but you want to receive updates quickly, then install it from Ultralisp.org:

```
(ql-dist:install-dist "http://dist.ultralisp.org/"
                      :prompt nil)
(ql:quickload :log4cl-extras)
```
""")



