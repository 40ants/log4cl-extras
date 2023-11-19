(defpackage #:log4cl-extras/appenders
  (:use #:cl)
  (:import-from #:log4cl)
  (:import-from #:global-vars
                #:define-global-var)
  (:import-from #:40ants-doc
                #:defsection)
  (:export
   #:stable-daily-file-appender
   #:stable-this-console-appender
   #:dont-disable-mixin
   #:stable-file-appender
   #:*debug-on-error*))
(in-package log4cl-extras/appenders)


(define-global-var *debug-on-error* nil
  "When T, then INVOKE-DEBUGGER will be called in case of any error during logging the message.")


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
  (when *debug-on-error*
    (invoke-debugger condition))
  :ignore)


(defsection @appenders (:title "Appenders"
                        :ignore-words (list "SOME-ERROR"))
  "In case of errors, LOG4CL removes appender from the logger. After that log message will be lost.

   I don't like this behaviour and prefer to see such errors in logs and to log other
   messages. This library defines a special appender classes which are not removed on errors but
   output this message instead: \"Caught SOME-ERROR: Error description - Unable to log the message.\".

   When you use LOG4CL-EXTRAS/CONFIG:SETUP function it automatically uses these appenders.

   To debug logging errors interactively, you can set *DEBUG-ON-ERROR* variable to T."
  (stable-daily-file-appender class)
  (stable-file-appender class)
  (stable-this-console-appender class)
  (dont-disable-mixin class)
  (*debug-on-error* variable))
