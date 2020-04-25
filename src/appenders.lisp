(defpackage #:log4cl-extras/appenders
  (:use #:cl)
  (:import-from #:log4cl)
  (:export
   #:stable-daily-file-appender
   #:stable-this-console-appender
   #:dont-disable-mixin
   #:stable-file-appender))
(in-package log4cl-extras/appenders)


(defclass dont-disable-mixin ()
  ())


(defclass stable-this-console-appender (dont-disable-mixin log4cl:this-console-appender)
  ())


(defclass stable-daily-file-appender (dont-disable-mixin log4cl:daily-file-appender)
  ())


(defclass stable-file-appender (dont-disable-mixin log4cl:file-appender)
  ())


(defmethod log4cl:handle-appender-error ((a dont-disable-mixin) condition)
  (ignore-errors
   (log4cl:log-error :logger log4cl:+self-meta-logger+
                     "~@<Caught ~S ~:_~A ~_~
                         Unable to log the message.~:>"
                     (type-of condition) condition))
  :ignore)
