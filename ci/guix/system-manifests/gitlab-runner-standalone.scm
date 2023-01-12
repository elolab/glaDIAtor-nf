(use-modules (gnu packages admin)
	     (gnu packages package-management)
	     (gnu packages base)
             (guix gexp)
	     (guix profiles)
	     (gnu packages certs)
	     (ice-9 popen)
	     )


;; see https://www.systemreboot.net/post/deploy-scripts-using-g-expressions
;; and (info "(guix) Build Environment Setup")
;; (info "(guix) Build Environment Setup")
;; [[info:guix#Build Environment Setup]]
;; [[info:guile#Pipes][guile#Pipes]]
(define guix-daemon-helper-gexp (with-imported-modules '((guix build utils))
    #~(begin
        (use-modules (guix build utils)
		     (ice-9 popen)
		     (ice-9 rdelim)
		     (ice-9 ports))
	(define build-group "guixbuild")
	(define build-comment-pattern "Guix build user ~a")
	(define build-name-pattern "guixbuilder~a")
	(invoke #$(file-append shadow "/sbin/groupadd") "--system" build-group)
	(do ((i 1 (1+ i))) ((>= i 10))
	  (invoke #$(file-append shadow "/sbin/useradd")
		  "-g" build-group
		  "-G" build-group
		  "-d" "/var/empty"
		  "-s" #$(file-append shadow "/sbin/nologin")
		  "-c" (format #f build-comment-pattern i)
		  "--system"
		  (format #f build-name-pattern i)))
	
	;; this file is necessary for the daemon to connect to substitute servers
	;; otherwise you will get the error:
	;; In prpocedure getaddrinfo: Servname not supported for ai_socktype
	;; see: https://lists.gnu.org/archive/html/help-guix/2019-06/msg00122.html
	(copy-file #$(file-append net-base "/etc/services") "/etc/services")

	(setenv "SSL_CERT_DIR"  #$(file-append nss-certs "/etc/ssl/certs"))
	(setenv "SSL_CERT_FILE" #$(file-append nss-certs "/etc/ssl/certs"))
	;; we start the daemon first
	;; so that we can authorize the default keys
	(apply open-pipe* OPEN_READ  #$(file-append guix "/bin/guix-daemon")
	       (cons 
		(format #f "--build-users-group=~a" build-group) (cdr (command-line))))
	;; authorize substitute servers
	(map (lambda (file)
	       (let
		   ((port (open-output-pipe (format #f "~a archive --authorize"
						       #$(file-append guix "/bin/guix")))))
		 
	       (display 
		(with-input-from-file file read-string)
		port)
	       (close-pipe port)))
	     (find-files #$(file-append guix "/share/guix")))
				

	;; (invoke "guix-daemon" (format #f "--build-users-group=~a" build-group))
	)))

	
(concatenate-manifests
 (list
  (specifications->manifest
   '("guix"
     "bash"
     "sed"
     "coreutils"))
 (manifest 
  ;; see (info "(guix) Writing Manifests")
  ;;
  (list
   (let ((guix-daemon-helper (program-file "guix-daemon-helper" guix-daemon-helper-gexp)))
   (manifest-entry
     (name "guix-daemon-helper")
     (version "0.0.1")
     (item
      (computed-file "guix-daemon-helper-directory"
		     #~(let ((bin (string-append #$output "/bin")))
                                   (mkdir #$output) (mkdir bin)
                                    (symlink #$guix-daemon-helper
                                             (string-append bin "/guix-daemon-helper")))))))))))

;; in order to use guix shell in docker; chroot has to be disabled
;; `cloning not permitted`
;; sudo sysctl kernel.unprivileged_userns_clone=1
;; https://github.com/simonmichael/hledger/issues/1030
		     
;; 
;; Local Variables:
;; compile-command: "guix time-machine -C ../channels.scm -- pack -f docker -S/bin=bin -S/etc=etc -m gitlab-runner-standalone.scm"
;; End:
