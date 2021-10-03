(defpackage #:log4cl-extras/json
  (:use #:cl)
  (:import-from #:log4cl
                #:%output-since-flush)
  (:import-from #:jonathan)
  (:import-from #:log4cl-extras/context
                #:get-fields)
  (:import-from #:log4cl-extras/utils
                #:get-timestamp)
  (:export
   #:json-layout))
(in-package log4cl-extras/json)


(defparameter +format-info+
  (make-instance 'log4cl::pattern-category-format-info
                 :case :downcase
                 :precision 1000
                 :separator nil
                 :start nil))


(defun write-json-item (stream logger log-func level &key (timezone local-time:*default-timezone*))
  (let* ((message (with-output-to-string (s)
                    ;; (log4cl:call-user-log-message log-func s)
                    (funcall log-func s)))
         (fields (list*
                  (cons :|logger| (with-output-to-string (s)
                                    (funcall (gethash #\g log4cl::*formatters*)
                                             s +format-info+ logger 0 0)))
                  (cons :|func| (with-output-to-string (s)
                                  (funcall (gethash #\C log4cl::*formatters*)
                                           s +format-info+ logger 0 0)))
                  (cons :|file| (log4cl:logger-file-namestring logger))
                  ;; User specified fields:
                  (get-fields)))
         (data (list (cons :|message| message)
                     (cons :|timestamp| (get-timestamp :timezone timezone)))))

    (push (cons :|level| (log4cl:log-level-to-string level))
          data)

    (when fields
      (push (cons :|fields| fields)
            data))
      
    (jonathan:with-output (stream)
      (let ((jonathan:*from* :alist))
        (jonathan:%to-json data)))

    (terpri stream)))


(defclass json-layout (log4cl:layout)
  ((timezone :initform local-time:*default-timezone*
             :initarg :timezone
             :type local-time::timezone
             :reader get-timezone)))


(defmethod log4cl:layout-to-stream ((layout json-layout)
                                    stream
                                    logger
                                    level
                                    log-func)
  (declare (ignorable layout))
  (write-json-item stream logger log-func level :timezone (get-timezone layout))
  (values))
