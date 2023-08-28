;; manifest for usage together with the emacs manifest
;; to generate the html documentation
(use-modules (guix transformations))
(packages->manifest
 (map
  (compose
   ;; https://github.com/lkk7/pydot/tree/pyparsing_fix
   ;; python-pydot has python-pyparsing@2.4.7 requirement 2.4.7, others require 3.0.6
   ;; we're not gonna do graphviz things here, so it might be okay to have a broken python-pydot here?
   (options->transformation
    `((with-input . "python-pyparsing@2.4.7=python-pyparsing")
      (without-tests . "python-pydot")
      ;; tests require threads
      (without-tests . "python-keras")
      ))
   specification->package)
 
 '("python-deepdia"
   ;; because nextflow requires bash to be present
   "bash" )))
    
