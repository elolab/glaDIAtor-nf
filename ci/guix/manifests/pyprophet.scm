(define-module (pyprophet)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system python)
  #:use-module (gnu packages)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages machine-learning)
  #:use-module (gnu packages python-science)
  #:use-module (gnu packages python-xyz)
  #:use-module (guix build utils)
  #:use-module (guix profiles)
  #:use-module (gnu packages python)
  #:use-module (gnu packages pdf)
  #:use-module (guix gexp)
  #:use-module (gnu packages statistics)
  #:use-module ((guix licenses) #:prefix license:))


;; so commit 972a1911e513003289e88df7d6d6af2ac938ead1 fixes that the PyProphetWeightApplier class
;; is calling its super incrorectly
;; but the commit before that (6802b26) changesPdfFileMerger,PdfFileReader to PdfMerger, PdfReader
;; pypdf2 in guix does not yet have those; so we substitute
(define-public python-pyprophet
  (package
    (name "python-pyprophet")
    (version "2.2.5")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "pyprophet" version))
              (sha256
               (base32
		"1cyspbj5czv9580v6sdccp5hl9pi63c8m4z646n0q36c7sjjpm7i"))))
    (arguments
     (list
      #:phases
      #~(modify-phases %standard-phases
	   (add-after 'unpack 'patch-for-pypdf2-compat
	     (lambda _
	       (substitute* "pyprophet/report.py"
		 (("PdfMerger") "PdfFileMerger")
		 (("PdfReader")
		   "PdfFileReader")))))))
    (build-system python-build-system)
    (propagated-inputs (list python-click
                             python-cython
                             python-hyperopt
                             python-matplotlib
                             python-numexpr
                             python-numpy
                             python-pandas
                             python-pypdf2
                             python-scikit-learn
                             python-scipy
                             python-statsmodels
                             python-tabulate
                             python-xgboost))
    (home-page "https://github.com/PyProphet/pyprophet")
    (synopsis
     "PyProphet: Semi-supervised learning and scoring of OpenSWATH results.")
    (description
     "PyProphet: Semi-supervised learning and scoring of OpenSWATH results.")
    (license license:bsd-3)))

(packages->manifest
 (list
  (specification->package "bash")  ;; because nextflow requires bash to be present
  python-pyprophet))

;; Local Variables:
;; compile-command: "guix time-machine -C ../channels.scm -- build -m pyprophet.scm"
;; End:
