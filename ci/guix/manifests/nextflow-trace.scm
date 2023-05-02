;;; this defines the list of packages that are needed to
;;; run with nextflow -trace options
(specifications->manifest
 (cdr
  (quote 
    ("trace"
     "procps"
     "grep"
     ;; core-utils are needed for touch, kill, test,head, tr ...
     ;; see the nxf_trace_linux() function in a nextflow jobs .command.run file
     "coreutils"
     "gawk"
     "sed"))))
