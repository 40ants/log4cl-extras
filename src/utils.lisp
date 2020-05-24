(defpackage #:log4cl-extras/utils
  (:use #:cl)
  (:import-from #:local-time)
  (:import-from #:cl-strings)
  (:export
   #:print-with-indent
   #:is-sly-stream
   #:get-timestamp
   #:remove-newlines
   #:limit-length))
(in-package log4cl-extras/utils)


(defun get-timestamp (&key (timezone local-time:+utc-zone+))
  (let ((now (local-time:now)))
    (local-time:format-rfc3339-timestring
     nil now
     :timezone timezone)))


(defun is-sly-stream (stream)
  ;; If appender was initialized from the REPL, we might want
  ;; it to output in a plain format instead of the JSON
  (and (find-package :slynk-gray)
       (typep stream
              (uiop:intern* :sly-output-stream
                            :slynk-gray))))


(defun print-with-indent (stream prefix text)
  "Prints a prefix to each line of the of the text."
  (loop for line in (cl-strings:split text #\Newline)
        do (format stream "~A~A~%" prefix line)))


(defun remove-newlines (text)
  (substitute #\Space #\Newline text))


(defun limit-length (text max-len)
  (if (> (length text)
         (- max-len 1))
      (concatenate 'string
                   (subseq text 0 (- max-len 1))
                   "…")
      text))
