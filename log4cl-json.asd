(defsystem log4cl-json
  :version "0.4.1"
  :author "Alexander Artemenko"
  :license "BSD"
  :depends-on (:log4cl
               :local-time
               :iterate
               :jonathan
               :cl-reexport
               :alexandria
               :cl-strings
               :dissect)
  :components ((:module "src"
                :components
                ((:file "appender")
                 (:file "core")
                 (:file "package"))))
  :description "A JSON appender for log4cl, to stream logs to ElasticSearch."
  :long-description
  #.(with-open-file (stream (merge-pathnames
                             #p"README.rst"
                             (or *load-pathname* *compile-file-pathname*))
                            :if-does-not-exist nil
                            :direction :input
                            :external-format :utf-8)
      (when stream
        (let ((seq (make-array (file-length stream)
                               :element-type 'character
                               :fill-pointer t)))
          (setf (fill-pointer seq)
                (read-sequence seq stream))
          seq)))
  :in-order-to ((test-op (test-op log4cl-json-test))))
