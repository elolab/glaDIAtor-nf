(define-module (pyprophet-past)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module (guix build-system python)
  #:use-module (gnu packages)
  #:use-module (gnu packages python-xyz)
  #:use-module (gnu packages machine-learning)
  #:use-module (gnu packages python-science)
  #:use-module (gnu packages python-xyz)
  #:use-module (guix build utils)
  #:use-module (guix profiles)
  #:use-module (gnu packages python)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (past packages python27)
 )

(define (without-tests p)
  ;; python-scikit-learn requires `python-pytest' for its
  ;; its test check (in native-inputs)
  ;; which is the py3 version, 
  ;; this doesnt work so we remove it here
  (package/inherit
	       p
	       (native-inputs
		(modify-inputs (package-native-inputs p)
			       (delete "python-pytest")))
	       (arguments
		(substitute-keyword-arguments (package-arguments p)
		  ((#:tests? _ #f) #f)))))

(define S2
  (compose
   python2-package
   (lambda (p) (if (string? p)
		   (specification->package p)
		   p))))

;; the last version of seaborn to work for python2
(define python2-seaborn
  (python2-package
   (without-tests
    (package/inherit
     python-seaborn
     (name "python2-seaborn")
     (version "0.9.0")
     (arguments
      (substitute-keyword-arguments
	  (package-arguments python-seaborn)
	;; launching the xserver will keep a hanging process in docker images
	;; and thus the build-daemon will not terminate
	((#:phases phases)
	 `(modify-phases ,phases
	    (delete 'start-xserver)))))
     (source (origin
               (method url-fetch)
               (uri (pypi-uri "seaborn" version))
               (sha256
		(base32
		 "0bqysi3fxfjl1866m5jq8z7mynhqbqnikim74dmzn8539iwkzj3n"))
	       (patches '())))))))

;; the last version of scikit-learn to work for python2
(define python2-scikit-learn
  (python2-package
   (without-tests
    (package/inherit
     python-scikit-learn
     (name "python2-scikit-learn")
     (version "0.20.3")
     (source
      (origin
        (method url-fetch)
        (uri (pypi-uri "scikit-learn" version))
        (sha256
	 (base32
	  "0h9czqxwlq2122y3hpv0n52fx59p6rg9y1hdsjsbh66yh4m800y5"))))
     (propagated-inputs (list python-numpy python-scipy))
     (native-inputs '())))))

(define-public python2-pyprophet
  (package
    (name "python2-pyprophet")
    (version "0.24.1")
    (source (origin
              (method url-fetch)
              (uri (pypi-uri "pyprophet" version))
              (sha256
               (base32
                "0bcxjb53azh7lfylnhh7gqpnivvpzc7mzriz6dl7l4nqvdqmsn57"))
	      (modules '((guix build utils)))
	      (snippet
	       `(substitute* "setup.py"
		 (("print \"need.*min_numpy_version")
		  "print(\"minimum numpy version not met\")")))))
    (build-system python-build-system)
    (arguments
     `(#:python ,python-2))
    (propagated-inputs
     (append
      (list python2-seaborn python2-scikit-learn)
      (map S2
	  '("python-matplotlib"
            "python-numexpr"
            "python-numpy"
            "python-pandas"
            "python-scipy"
            ))))
    (home-page "http://github.com/uweschmitt/pyprophet")
    (synopsis "Python reimplementation of mProphet peak scoring")
    (description "Python reimplementation of mProphet peak scoring")
    (license license:bsd-3)))
(packages->manifest
 (list
  (specification->package "bash")
  python2-pyprophet))


;; Local Variables:
;; compile-command: "guix time-machine -C channels.scm -- build -f pyprophet.scm"
;; End:
