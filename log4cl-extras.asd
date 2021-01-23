(defsystem log4cl-extras
  :name "log4cl-extras"
  :version "0.4.2"
  :author "Alexander Artemenko"
  :license "BSD"
  :class :package-inferred-system
  :pathname "src"
  :depends-on (;; This component intentionally
               ;; not listed, because it requires
               ;; additional dependency system :secret-values
               ;;
               ;; "log4cl-extras/secrets"
               "log4cl-extras/config"
               "log4cl-extras/error")
  :description "A bunch of addons to log4cl, JSON appender, context fields, cross-finger appender, etc."
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
  :in-order-to ((test-op (test-op log4cl-extras-test))))
