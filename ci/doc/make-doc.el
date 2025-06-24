#!/usr/bin/env -S emacs -x
;; -*- lexical-binding: t; -*-
(setq enable-local-variables :all user-full-name "")
(require 'ob-dot)
(require 'ox)
(require 'ox-texinfo)
(require 'ox-html)
(require 'ox-latex)
(require 'files)

(setq org-confirm-babel-evaluate nil)


(defun find-this-script-dir  (launch-dir cli-args)
  (let* (
	 (this-file-nondirectory "make-doc.el")
	 (invoked (cl-remove-if-not
		  (lambda (x)
		    (string-equal 
		     (file-name-nondirectory x)
		     this-file-nondirectory))
		  cli-args)))
    (if invoked
	(let ((this-script (car invoked)))
	  (expand-file-name
	   (file-name-directory this-script)
	   launch-dir)))))

(defvar this-script-dir
  (find-this-script-dir default-directory command-line-args))
(defvar project-root-dir
  (expand-file-name
   "../../"
   this-script-dir))

(defun gladiator-notes-file ()
  (expand-file-name
   "notes.org"
   project-root-dir))
;; apply dir-local variables so that we get the proper html highlighting 
(mapc
 (lambda (x)
   (set (car x) (cdr x)))
 (alist-get
	  'org-mode
	  (read (with-current-buffer
		   (find-file-noselect (expand-file-name ".dir-locals.el" project-root-dir )
		 (goto-char (point-min))
		 (current-buffer))
		 ))))


(defun document-project-smart (infile outfile)
  (let* ((outdir (file-name-directory (expand-file-name  outfile)))
	 (backend 
	  (pcase (file-name-extension outfile)
	    ("html" 'html)
	    ("info" 'texinfo)
	    ("pdf" 'latex)
	    (_ (error "Could not determine the backend based on extension of %s" outfile))))
	 (precompile-extension
	  (pcase backend
	    ('latex  "tex")
	    ('texinfo "texinfo")
	    (_ (file-name-extension outfile))))
	 (postprocess-action
	  (pcase backend
	    ('latex #'org-latex-compile)
	    ('texinfo #'org-texinfo-compile)
	    (_ nil)))
	 (get-coding-system (lambda ()
			      (let ((s (format "%s%s%s" "org-" backend "-coding-system")))
			     (if (boundp
				  (intern s))
				 (eval (intern s) t))
			     org-export-coding-system)))
	 (org-export-exclude-tags
	  (if (eq backend 'texinfo) 
	      org-export-exclude-tags
	    (cons "texinfo" org-export-exclude-tags)
	    ;; we exclude the texinfo specific sections (the vindex and cindex)
	    ;; in html/pdf
	     
	    )))
    

      
    (setq infile (expand-file-name infile))
    (let ((default-directory outdir)
	  (org-export-with-broken-links t))
      (with-temp-buffer
	(insert-file-contents infile)

	(let ((default-directory outdir)
	      (org-export-coding-system (funcall get-coding-system)))
	  (org-export-to-file backend
	      (format "%s.%s"
		      (file-name-sans-extension
		       (file-name-nondirectory outfile))
		      precompile-extension)
	    nil
	    nil
	    nil
	    nil
	    nil
	    postprocess-action))))))
(defun export-project-to-html ()
  (with-current-buffer (find-file-noselect (gladiator-notes-file))
    
    (let ((org-export-coding-system org-html-coding-system)
	  ;; so that generated images are placed here
	  (default-directory this-script-dir))
    (org-export-to-file 'html
	(expand-file-name "gladiator.html"
			  this-script-dir)))))

(apply #'document-project-smart command-line-args-left)



