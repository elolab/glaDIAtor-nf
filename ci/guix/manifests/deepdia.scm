;; manifest for usage together with the emacs manifest
;; to generate the html documentation
(specifications->manifest
 '("python-deepdia"
   ;; because nextflow requires bash to be present
   "bash" ))
    
