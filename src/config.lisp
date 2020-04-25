(defpackage #:log4cl-extras/config
  (:use #:cl)
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
  (:export
   #:setup))
(in-package log4cl-extras/config)


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
"
  ;; This removes all loggers except ROOT
  (log:config :reset)
  ;; This removes appenders from the root logger.
  (log4cl:remove-all-appenders log4cl:*root-logger*)

  (apply #'setup-logger
         log4cl::*root-logger*
         config))
