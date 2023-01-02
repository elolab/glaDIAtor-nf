(define-module 
  (emacs-manifest)
  #:use-module (guix packages)
  #:use-module (guix build-system emacs)
  #:use-module (guix git-download)
  #:use-module (guix profiles)
  #:use-module (gnu packages)
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


(concatenate-manifests
 (list
  (specifications->manifest
   '("emacs-minimal"
     "graphviz"
     "which"))
 (packages->manifest
  (list emacs-nextflow-mode))))
