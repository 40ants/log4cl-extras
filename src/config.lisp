(uiop:define-package #:log4cl-extras/config
  (:use #:cl)
  (:import-from #:pythonic-string-reader
                #:pythonic-string-syntax)
  (:import-from #:named-readtables
                #:in-readtable)
  (:import-from #:log4cl-extras/json)
  (:import-from #:log4cl-extras/plain)
  (:import-from #:alexandria
                #:ensure-list)
  (:import-from #:global-vars
                #:define-global-parameter)
  (:import-from #:log4cl-extras/appenders
                #:stable-this-console-appender
                #:stable-daily-file-appender
                #:stable-file-appender)
  (:import-from #:40ants-doc
                #:defsection)
  (:export
   #:setup))
(in-package log4cl-extras/config)

(in-readtable pythonic-string-syntax)


(defsection @configuration (:title "Configuration"
                            :ignore-words (":JSON"
                                           ":PLAIN"
                                           "LOG4CL:THIS-CONSOLE-APPENDER"
                                           "LOG4CL:DAILY-FILE-APPENDER"
                                           "LOG4CL:FILE-APPENDER"))
  """
By default LOG4CL outputs log items like this:

```
CL-USER> (log:info "Hello")
 <INFO> [01:15:37] cl-user () - Hello
```

However logging extra context fields requires a custom "layout".
Layout defines the way how the message will be formatted.

This system defines two layout types:

* :PLAIN - a layout for printing messages to the REPL.
* :JSON - a layout which outputs each message and all it's data
  as a JSON documents. Use it to feed logs to Elastic Search
  or a service like [Datadog](https://www.datadoghq.com/)
  to [Papertrail](https://www.papertrail.com/).

To use these custom layouts, you have to use SETUP function. It also allows to set a log level
for root logger and appenders. Here is a minimal example showing how to configure logger for the REPL:

```
CL-USER> (log4cl-extras/config:setup
          '(:level :debug
            :appenders ((this-console :layout :plain))))
NIL

CL-USER> (log:info "Hello")
<INFO> [2021-05-16T01:16:46.978992+03:00] Hello

CL-USER> (log4cl-extras/context:with-fields (:foo "Bar")
           (log:info "Hello"))
<INFO> [2021-05-16T01:26:30.331849+03:00] Hello
  Fields:
    foo: Bar
```

If you replace :PLAIN with :JSON, you'll get this:

```
CL-USER> (log4cl-extras/config:setup
          '(:level :debug
            :appenders ((this-console :layout :json))))
; No values
CL-USER> (log4cl-extras/context:with-fields (:foo "Bar")
           (log:info "Hello"))
{"fields":{"foo":"Bar"},"level":"INFO","message":"Hello","timestamp":"2021-05-16T01:27:54.879336+03:00"}
```

Appender in terms of log4cl is a target for log output. You can combine multiple appenders
in a single call to SETUP function.

Here is the example of the config, suitable for production. Here we log all messages as JSON records
into the file, rotated on the daily basis. And all errors and warnings will be written to the REPL.

```
(log4cl-extras/config:setup
 '(:level :debug
   :appenders ((this-console :layout :plain
                             :filter :warn)
               (daily :layout :json
                      :name-format "/app/logs/app.log"
                      :backup-name-format "app-%Y%m%d.log"))))
```

Also, SETUP allows to change log levels for different loggers:
"""
  (setup function)

  "## Layouts"

  (log4cl-extras/plain:plain-layout class)
  (log4cl-extras/json:json-layout class))


(define-global-parameter
    *appenders*
    (list (cons "this-console"
                (lambda (&rest args)
                  (apply #'make-instance
                         'stable-this-console-appender
                         args)))
          (cons "daily"
                (lambda (&rest args)
                  (apply #'make-instance
                         'stable-daily-file-appender
                         args)))
          (cons "file"
                (lambda (&rest args)
                  (apply #'make-instance
                         'stable-file-appender
                         args))))
  "A alist of appenders. Maps appender's name to a function which constructs it.")


(define-global-parameter
    *layouts*
    (list (cons "plain"
                (lambda (&rest args)
                  (apply #'make-instance
                         'log4cl-extras/plain:plain-layout
                         args)))
          (cons "json"
                (lambda (&rest args)
                  (apply #'make-instance
                         'log4cl-extras/json:json-layout
                         args))))
  "A alist of layout constructors. Maps layout's name to a function which constructs it.")


(defun make-layout (name args)
  (let* ((name (symbol-name name))
         (constructor (alexandria:assoc-value
                       *layouts*
                       name
                       :test #'string-equal)))
    (unless constructor
      (error "Unknown layout type ~S" name))
    (apply constructor
           args)))


(defun make-appender (name args)
  (let* ((name (symbol-name name))
         (constructor (alexandria:assoc-value
                       *appenders*
                       name
                       :test #'string-equal)))
    (unless constructor
      (error "Unknown appender type ~S" name))
    (let ((layout (ensure-list (getf args :layout))))
      (when layout
        (setf args
              (append (list :layout
                            (make-layout (car layout)
                                         (cdr layout)))
                      args))))
    (let ((filter (getf args :filter)))
      (when (and filter
                 (typep filter 'keyword))
        (setf args
              (append (list :filter
                            (log4cl:make-log-level filter))
                      args))))
    (apply constructor
           args)))


(defun make-logger (categories)
  (log4cl:with-package-naming-configuration (*package*)
    (log4cl::get-logger-internal categories
                                 (log4cl:category-separator)
                                 (log4cl:category-case))))


(defun setup-logger (logger &key appenders loggers level)
  (declare (ignorable loggers))
  (when level
    (log:config logger level))
  (loop for item in appenders
        for appender = (ensure-list item)
        for name = (car appender)
        for args = (cdr appender)
        do (log4cl:add-appender
            logger
            (make-appender name args)))
  (loop for item in loggers
        for subcategory-and-params = (ensure-list item)
        for subcategory = (car subcategory-and-params)
        for params = (cdr subcategory-and-params)
        for all-categories = (append (log4cl:logger-categories logger)
                                     (list subcategory))
        for sub-logger = (make-logger all-categories)
        do (apply #'setup-logger
                  sub-logger
                  params)))


(defun setup (config)
  "Setup loggers and appenders via confg.

   Example:

   ```
   (setup
    '(:level :error
      :appenders
      (this-console
       (file
        :file \"foo.log\"
        :layout json))
      :loggers
      ((log4cl-extras/config
        :loggers
        ((foo :level :debug)
         (bar
          :loggers
          ((some-class
            :level debug))))))))
   ```

   As you can see, SETUP function accepts a plist with keys :LEVEL, :APPENDERS and :LOGGERS.

   :LEVEL key holds a logging level for the root logger. It could be :INFO, :WARN or :ERROR.

   :APPENDERS is a list of list where each sublist should start from the appender type and arguments for it's constructor.

   Supported appenders are:

   * `THIS-CONSOLE` corresponds to LOG4CL:THIS-CONSOLE-APPENDER class.
   * `DAILY` corresponds to LOG4CL:DAILY-FILE-APPENDER class.
   * `FILE` corresponds to LOG4CL:FILE-APPENDER.

   To lookup supported arguments for each appender type, see these classes initargs.
   the only difference is that :LAYOUT argument is processed in a special way:
   :JSON value replaced with LOG4CL-EXTRAS/JSON:JSON-LAYOUT and :PLAIN is replaced
   with LOG4CL-EXTRAS/PLAIN:PLAIN-LAYOUT.

   And finally, you can pass to SETUP a list of loggers. Each item in this list
   should be plist where first item is a symbolic name of a package or a function name
   inside a package and other items are params for a nested SETUP call.

"
  ;; This removes all loggers except ROOT
  (log:config :reset)
  ;; This removes appenders from the root logger.
  (log4cl:remove-all-appenders log4cl:*root-logger*)

  (apply #'setup-logger
         log4cl::*root-logger*
         config)
  (values))
