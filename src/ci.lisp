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
  :jobs ((linter :asdf-version "3.3.7"
                 :lisp "sbcl-bin/2.5.10")
         (run-tests
          :os ("ubuntu-latest"
               "macos-latest")
          :quicklisp ("ultralisp"
                      "quicklisp")
          :lisp ("sbcl-bin"
                 "ccl-bin"
                 "ecl")
          :exclude '((:os "macos-latest"
                      ;; Not supported platform arm64.
                      :lisp "ccl-bin"))
          :coverage t)))


(defworkflow docs
  :on-push-to "master"
  :on-pull-request t
  :by-cron "0 10 * * 1"
  ;; :cache t 
  :jobs ((build-docs :asdf-system "log4cl-extras/doc")))
