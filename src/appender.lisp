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
           :accessor appender-stream)
   (plain :initarg :plain
          :initform nil
          :documentation "Write plain log (not JSON) for the REPL."
          :accessor appender-plain))
  (:documentation "Appender which writes JSON items to the stream."))


(defmethod initialize-instance :after ((appender json-appender) &rest initargs)
  (declare (ignorable initargs))
  
  (let ((stream (appender-stream appender)))
    ;; If appender was initialized from the REPL, we want
    ;; it to output in a plain format instead of the JSON
    (setf (appender-plain appender)
          (and (find-package :slynk-gray)
               (typep stream
                      (uiop:intern* :sly-output-stream
                                    :slynk-gray))))))


(defun write-json-item (stream log-func level)
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
        (jonathan:%to-json data)))

    (terpri stream)))


(defun print-with-indent (stream prefix text)
  "Prints a prefix to each line of the of the text."
  (loop for line in (cl-strings:split text #\Newline)
        do (format stream "~A~A~%" prefix line)))


(defun write-plain-item (stream log-func level)
  (let* ((message (with-output-to-string (s)
                    (funcall log-func s)))
         (fields (get-fields))
         (level (log4cl:log-level-to-string level))
         (timestamp (get-timestamp))
         (traceback (alexandria:assoc-value fields :|traceback|)))

    ;; Desired output is like that
    ;; <ERROR> [19:01:07] ultralisp/cron cron.lisp (perform-checks h0)
    ;;   Text message.
    ;;   some: field
    ;;   another: field
    ;;   Traceback: Multiline
    ;;   traceback
    ;;   which easy to read.
    (format stream "<~A> [~A]~%  ~A~%"
            level
            timestamp
            message)
    (setf cl-user::*fields* fields)
    (loop for (key . value) in fields
          unless (eql key
                      :|traceback|)
            do (format stream "  ~A: ~A~%"
                       key
                       value))

    (when traceback
      (print-with-indent stream "  " traceback))))


(defmethod appender-do-append ((this json-appender)
                               logger
			       level
                               log-func)
  (declare (ignorable logger))
  
  (with-slots (layout stream %output-since-flush plain) this
    (if plain
        (write-plain-item stream log-func level)
        (write-json-item stream log-func level))
    
    (setf %output-since-flush t)
    (log4cl::maybe-flush-appender-stream this stream))
  (values))


(defmethod handle-appender-error ((appender json-appender) condition)
  "Don't disable my lovely appender!"
  :ignore)
