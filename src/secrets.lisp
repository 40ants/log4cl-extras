(defpackage #:log4cl-extras/secrets
  (:use #:cl)
  (:import-from #:global-vars
                #:define-global-var)
  (:import-from #:log4cl-extras/error
                #:make-placeholder)
  (:import-from #:secret-values
                #:secret-value
                #:reveal-value)
  (:export
   #:make-secrets-replacer))
(in-package log4cl-extras/secrets)


(define-global-var +secret-placeholder+
    (make-placeholder "secret value"))


(defun make-secrets-replacer ()
  "Returns a function which can be used to filter backtrace arguments.

   See LOG4CL-EXTRAS/ERROR:*ARGS-FILTERS*"
  (let ((seen-secrets (make-hash-table :test 'equal
                                       #+sbcl
                                       :synchronized
                                       #+sbcl t)))
    (labels ((already-seen (raw-secret)
               (gethash raw-secret
                        seen-secrets))
             (remember-secret (secret)
               (setf (gethash (reveal-value secret)
                              seen-secrets)
                     t))
             (remove-secrets (func-name args)
               (let ((new-args
                       (loop for arg in args
                             for is-secret-value = (typep arg 'secret-value)
                             if is-secret-value
                             do (remember-secret arg)
                             if (or is-secret-value
                                    (already-seen arg))
                             collect +secret-placeholder+
                             else
                             collect arg)))
                 (values func-name
                         new-args))))
        #'remove-secrets)))
