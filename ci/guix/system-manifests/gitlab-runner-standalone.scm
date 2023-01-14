;;; a profile for running guix in a docker
;;; This is _not_ part of GNU Guix
;;; This program is free software: you can redistribute it and/or modify
;;; it under the terms of the GNU General Public License as published by
;;; the Free Software Foundation, either version 3 of the License, or
;;; (at your option) any later version.
;;; 
;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;; 
;;; You should have received a copy of the GNU General Public License
;;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;; 
;;; when entering a container (assuming you're root in container) run
;;; # guix-daemon-helper [args to pass do guix daemon]
;;; and then you can guix things
;;; you might want to add --disable-chroot
;;; otherwise you cannot guix shell.
;;; havent found a way to make it work singularity yet.
;;; fakeroot doesnt work on our cluster
(use-modules  (gnu packages package-management)
	      (gnu packages admin)
              (guix gexp)
	      (guix profiles)
	      (gnu packages certs)
	      (ice-9 popen)
	      (srfi srfi-1)
	      (srfi srfi-26)
	      (gnu services base)
	      (guix modules))

(define (construct-users)
  (fold (cut <> <>) 10
	(list
	 ;; create 10 guix build accounts
	 (@@ (gnu services base) guix-build-accounts)
	 ;; add the root account
	 (cute
	  cons*
	  (user-account
	   (name "root")
	   (group "root")
	   (uid 0)
	   (home-directory "/var/empty")) <>)
	 ;; turn it all into gexps so that the
	 ;; gexp that uses these is happy
	 (cute map (@@ (gnu system shadow) user-account->gexp) <>))))


;; This gexp files /etc/passwd /etc/shadow /etc/group with the right
;; stuff

(define user+group-databases-gexp
  (with-imported-modules (source-module-closure
			  '((gnu build accounts)
			    ((gnu system accounts))))
    #~(begin
	(use-modules ((gnu build accounts)))
	((lambda ()
	   (define-values (group password shadow)
	     (user+group-databases (map (@ (gnu system accounts) sexp->user-account)
					(list #$@(construct-users)))
				   (cons 
				    ((@ (gnu system accounts)  user-group)
				     (name "guixbuild"))
				    (map
				     (@ (gnu system accounts) sexp->user-group)
				     (list #$@(map (@@ (gnu system shadow)
						       user-group->gexp)
						   %base-groups))))
				   #:current-passwd '()
				   #:current-groups '()
				   #:current-shadow '()))
	   (let* ((etc-dir (string-append #$output "/etc"))
		  (password-file (string-append etc-dir "/passwd"))
		  (shadow-file (string-append etc-dir "/shadow"))
		  (group-file (string-append etc-dir "/group")))
	     (mkdir #$output)
	     (mkdir etc-dir)
	     (write-passwd password password-file)
	     (write-shadow shadow shadow-file)
	     (write-group group group-file)))))))

(define user+group-databases 
  (computed-file "user+group-databases"
		 user+group-databases-gexp))


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
		     (ice-9 ports)
		     (ice-9 ftw))

	;; `docker run` seems to overwrite /etc/ to write resolv.conf
	;; https://docs.docker.com/engine/reference/run/
	;; so here we put things back
	;; actually if we guix pack --symlink /etc/group=etc/group
	;; that works,
	;; so is there a way to make only the children symlinks?
	;; 
	;; how about we only symlink /etc/ of #$user+group-databases here
	;; and #$net-base, because those are the only ones we need.
	;; then we dont need the ugle /guix-etc/ hack
	;; and we dont even need to pass any symlink flags.
	
	(define (symlink-dir-contents  source-dir target-dir)
	  (when (and (access? source-dir R_OK)
		     (access? target-dir W_OK))
	    (map
	     (lambda (f)
	       (let ((target (string-append target-dir f)))
		 (unless (file-exists? target)
		   (symlink (string-append source-dir f) target))))
	     (scandir source-dir))))
	
	(symlink-dir-contents
	 #$(file-append user+group-databases "/etc/")
	 "/etc/")
	;; net-base suppplies /etc/services
	;; this file is necessary for the daemon to connect to substitute servers
	;; otherwise you will get the error:
	;; In prpocedure getaddrinfo: Servname not supported for ai_socktype
	;; see: https://lists.gnu.org/archive/html/help-guix/2019-06/msg00122.html
	(symlink-dir-contents
	 #$(file-append net-base "/etc/")
	 "/etc/")

	(define build-group "guixbuild")
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
	     (find-files #$(file-append guix "/share/guix"))))))

	
(concatenate-manifests
 (list
  (specifications->manifest
   '("guix"
     "bash"
     "coreutils"
     "sed"
     "net-base"
     ;; so that guix-time-machine is happy with regards to pulling from git
     "nss-certs"))
  (manifest 
   ;; see (info "(guix) Writing Manifests")
   (list
    (manifest-entry
      (name "user+group-databases")
      (version "0.0.1")
      (item user+group-databases))
    (manifest-entry
      (name "guix-daemon-helper")
      (version "0.0.1")
      (item
       (file-union
	"guix-daemon-helper"
	`(("bin"	   
	   ,(file-union
	     "bin"
	     `(("guix-daemon-helper" ,(program-file "guix-daemon-helper" guix-daemon-helper-gexp)))))))))))))


;; in order to use guix shell in docker; chroot has to be disabled
;; `cloning not permitted`
;; sudo sysctl kernel.unprivileged_userns_clone=1
;; https://github.com/simonmichael/hledger/issues/1030
		     
;; 
;; Local Variables:
;; compile-command: "guix time-machine -C ../channels.scm -- pack -f docker -S/bin/sh=bin/sh  -m gitlab-runner-standalone.scm"
;; End:
