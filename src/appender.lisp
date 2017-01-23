(defpackage log4cl-json.appender
  (:use :cl
        :iterate)
  (:export #:with-fields
           #:json-appender)
  (:import-from #:log4cl
           #:appender-do-append
           #:handle-appender-error
           #:%output-since-flush))

(in-package :log4cl-json.appender)


(defvar *fields*
  nil
  "A stack of data fields to be serialized to JSON

Fields are stored as a plist, and transformed into an a list before serialization.")


(defun get-fields ()
  (let (result)
    (iterate (for (key value) :on *fields* :by #'cddr)
             (unless (assoc key result)
               (push (cons key value)
                     result)))
    result))


(defmacro with-fields (fields &body body)
  `(let ((*fields* (append (list ,@fields) *fields*)))
     (progn ,@body)))


(defun get-timestamp ()
  (let ((now (local-time:now)))
    (local-time:format-rfc3339-timestring
     nil now
     :timezone local-time:+utc-zone+)))


(defclass json-appender (log4cl:fixed-stream-appender)
  ((stream :initarg :stream
           :initform *standard-output*
           :accessor appender-stream))
  (:documentation "Appender which writes JSON items to the stream."))


(defmethod appender-do-append ((this json-appender)
                               logger
			       level
                               log-func)
  (with-slots (layout stream %output-since-flush) this
    (let* ((message (with-output-to-string (s)
                      (funcall log-func s)))
           (fields (get-fields))
           (data (list (cons :|@message| message)
                       (cons :|@timestamp| (get-timestamp)))))

      (push (cons :|level| (log4cl:log-level-to-string level))
            fields)

      (push (cons :|@fields| fields)
            data)
      
      (jonathan:with-output (stream)
        (let ((jonathan:*from* :alist))
          (jonathan:%to-json data))))
    
    (setf %output-since-flush t)
    (log4cl::maybe-flush-appender-stream this stream))
  (values))


(defmethod handle-appender-error ((appender json-appender) condition)
  "Don't disable my lovely appender!"
  :ignore)
