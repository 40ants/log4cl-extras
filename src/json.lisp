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


(defun write-json-item (stream log-func level)
  (let* ((message (with-output-to-string (s)
                    ;; (log4cl:call-user-log-message log-func s)
                    (funcall log-func s)))
         (fields (get-fields))
         (data (list (cons :|message| message)
                     (cons :|timestamp| (get-timestamp)))))

    (push (cons :|level| (log4cl:log-level-to-string level))
          data)

    (push (cons :|fields| fields)
          data)
      
    (jonathan:with-output (stream)
      (let ((jonathan:*from* :alist))
        (jonathan:%to-json data)))

    (terpri stream)))


(defclass json-layout (log4cl:layout)
  ())


(defmethod log4cl:layout-to-stream ((layout json-layout)
                                    stream
                                    logger
                                    level
                                    log-func)
  (declare (ignorable layout logger))
  (write-json-item stream log-func level)
  (values))
