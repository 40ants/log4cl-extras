(defpackage #:log4cl-extras/ci
  (:use #:cl)
  (:import-from #:40ants-ci/workflow
                #:defworkflow)
  (:import-from #:40ants-ci/jobs/linter
                #:linter)
  (:import-from #:40ants-ci/jobs/run-tests
                #:run-tests)
  (:import-from #:40ants-ci/jobs/docs
                #:build-docs))
(in-package log4cl-extras/ci)


(defworkflow ci
  :on-push-to "master"
  :by-cron "0 10 * * 1"
  :on-pull-request t
  :cache t
  :jobs ((linter)
         (run-tests
          :os ("ubuntu-latest"
               "macos-latest")
          :quicklisp ("ultralisp"
                      "quicklisp")
          :lisp ("sbcl"
                 "ccl"
                 "ecl")
          :coverage t)))


(defworkflow docs
  :on-push-to "master"
  :by-cron "0 10 * * 1"
  :cache t 
  :jobs ((build-docs :asdf-system "log4cl-extras/doc")))
