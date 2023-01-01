(define-module 
  (workflow-pres)
  #:use-module (guix packages)
  #:use-module (guix build-system emacs)
  #:use-module (guix import elpa)
  #:use-module (guix git-download)
  #:use-module (guix profiles)
  #:use-module (gnu packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module ((guix licenses) #:prefix license:)
   ;; for emacs definitions
  #:use-module (gnu packages emacs-xyz))

(define-public emacs-nextflow-mode
  (let (
	(commit "2c87bec8fcc6f2859d40839093c5e773724b45b5")
	(revision "0"))
  (package
    (name "emacs-nextflow-mode")
    (version (git-version "0.0.1" revision commit))
    (source
     (origin
       (method git-fetch)
       (uri (git-reference
	     (url "https://github.com/Emiller88/nextflow-mode")
	     (commit commit)))
       (file-name (git-file-name name version))
       (sha256 (base32 "0bq3a01n2xkc00g4dddf2lgmvdspn2zz75viil7lmxvqizlygjra"))))
    (build-system emacs-build-system)
    (license license:gpl3)
    (synopsis "Syntax highlighting for NextFlow")
    (home-page "https://github.com/Emiller88/nextflow-mode")
    (description synopsis)
    ;; add this to emacsloadpath 
    (propagated-inputs
     `(("emacs-groovy" ,emacs-groovy-modes))))))

(define-public my-add-env-vars
  (package
    (name "my-add-env-vars")
    (version "0")
    (source #f)
    (synopsis "This pseudo-package adds this package's profile to EMACSLOADPATH")
    (description synopsis)
    (license #f)
    (home-page #f)
    (build-system trivial-build-system)
    (native-search-paths
     (list (search-path-specification
            (variable "EMACSLOADPATH")
            (files '("share/emacs/site-lisp")))))
    (arguments
     `(#:modules  ((guix build utils))
       #:builder
       (begin
	 (use-modules (guix build utils))
	 (mkdir-p %output)
	 #t)))))

;; for if you want to read the org-file with syntax highlighting
(define syntax-highlighting-manifest
  (packages->manifest
   (list
    emacs-nextflow-mode
    my-add-env-vars)))
;; for if you want to compile the org-file
;; and already have latex & emacs
;; if you dont, also add "big-emacs-manifest"
(define report-compilation-manifest
  (specifications->manifest
   '("python-pygments"
     "graphviz"
     "emacs-htmlize"
     "graphviz"
     )))
;; for if you want to execute the source code blocks 
  

(define big-emacs-manifest
  (specifications->manifest
   '("emacs" ;; or another emacs version you'd like, e.g. emacs-native-comp
     ;; so that we also have latex
     "texlive"
     "which"
     "emacs-auctex")))


(concatenate-manifests
 (list
  syntax-highlighting-manifest
  big-emacs-manifest ;; you can disable this if you already have emacs & latex installed
  report-compilation-manifest ;; you can disable this if you dont plan to compile the report
  ))
