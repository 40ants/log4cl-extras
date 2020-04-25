Usage
=====

To turn this handler on, do:

.. code:: common-lisp

   (log4cl-extras:setup)

Then, somewhere in code:

.. code:: common-lisp


   (log4cl-extras:with-fields (:request-id 42)
      (log:info "Processing request")
      ;; All logging in this call and nested calls will have
      ;; "request-id = 42" field.
      (process-request))

If you want to log unhandled signals' traceback, then do:

.. code:: common-lisp

   (log4cl-extras:with-log-unhandled ()
     (foo)
     (bar)))

If some unhandled condition will be signaled in foo or bar, this code
will log an error with ``traceback`` field like this::

  Traceback (most recent call last):
    File "NIL", line NIL, in BAR
      (BAR 1 :BOO "baz")
    File "NIL", line NIL, in FOO
      (FOO)
    File "NIL", line NIL, in HANDLE-RE…
      (HANDLE-REQUEST 42)
    File "NIL", line NIL, in MAIN
      (MAIN)
    File
    "/Users/art/.roswell/impls/x86-64/darwin/ccl-bin/1.11/level-1/l1-aprims.lisp",
    line 90, in APPLY
      (APPLY MAIN NIL)
    File
    "/Users/art/.roswell/impls/x86-64/darwin/ccl-bin/1.11/level-1/l1-readloop.lisp",
    line 827, in CALL-CHEC…
      (CCL::CALL-CHECK-REGS APPLY MAIN NIL)
    File
    "/Users/art/.roswell/impls/x86-64/darwin/ccl-bin/1.11/level-1/l1-readloop.lisp",
    line 706, in CHEAP-EVA…
      (CCL::CHEAP-EVAL-IN-ENVIRONMENT (ROSWELL:QUIT (APPLY 'MAIN
      ROSWELL:*ARGV*)) NIL)
    File
    "/Users/art/.roswell/impls/x86-64/darwin/ccl-bin/1.11/level-1/l1-readloop.lisp",
    line 668, in CHEAP-EVA…
      (CCL::CHEAP-EVAL (ROSWELL:QUIT (APPLY 'MAIN ROSWELL:*ARGV*)))
    File
    "/Users/art/.roswell/impls/x86-64/darwin/ccl-bin/1.11/tools/asdf.lisp",
    line 3947, in (INTERNAL…
      ((:INTERNAL UIOP/STREAM:EVAL-INPUT) #<CONCATENATED-STREAM
      #x302000DA60CD>)
    File "/Users/art/usr/roswell/etc/roswell/init.lisp", line 355, in
    (INTERNAL…
      ((:INTERNAL ROSWELL::BODY ROSWELL:SCRIPT)
      #<BASIC-FILE-CHARACTER-INPUT-STREAM
      ("/Users/art/projects/lisp/log4cl-extras/./example.ros"/4 UTF-8)
      #x302000DA730D>)


Output examples
===============

.. code:: json

   {
       "@fields": {
           "uuid": "c969f594-8c46-454b-a2af-fd5c877ab288",
           "title": "",
           "changelog_id": 57,
           "level": "DEBUG",
           "method": "POST",
           "source": "test+samples/markdown-release-notes",
           "version": "2.6",
           "another_changelog_id": 57,
           "preview_id": 3,
           "path": "/preview/1/",
           "job_name": "update_preview_task",
           "name": "filter_versions"
       },
       "@timestamp": "2016-06-22T06:18:12+00:00",
       "@source_host": "52a8033dfd3a",
       "@message": "Excluded because parent version is 1.0.5"
   }

.. code:: json

   {
       "@fields": {
           "exception": "Traceback (most recent call last):\n  File \"/app/allmychanges/parsing/pipeline.py\", line 1040, in wrapper\n    for item in processor(*args, **kwargs):\n  File \"/app/allmychanges/vcs_extractor.py\", line 467, in get_versions_from_vcs\n    commits, tagged_versions = get_history(path)\n  File \"/app/allmychanges/vcs_extractor.py\", line 69, in git_history_extractor\n    with cd(path):\n  File \"/usr/lib/python2.7/contextlib.py\", line 17, in __enter__\n    return self.gen.next()\n  File \"/app/allmychanges/utils.py\", line 68, in cd\n    os.chdir(path)\nTypeError: coercing to Unicode: need string or buffer, list found\n",
           "uuid": "c969f594-8c46-454b-a2af-fd5c877ab288",
           "job_name": "update_preview_task",
           "level": "ERROR",
           "changelog_id": 57,
           "method": "POST",
           "source": "test+samples/markdown-release-notes",
           "another_changelog_id": 57,
           "preview_id": 3,
           "path": "/preview/1/",
           "processor": "get_versions_from_vcs",
           "name": "processing-pipe"
       },
       "@timestamp": "2016-06-22T06:18:09+00:00",
       "@source_host": "52a8033dfd3a",
       "@message": "Unable to process items"
   }
