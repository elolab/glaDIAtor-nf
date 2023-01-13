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
(use-modules (gnu packages admin)
	     (gnu packages package-management)
	     (gnu packages base)
             (guix gexp)
	     (guix profiles)
	     (gnu packages certs)
	     (ice-9 popen))


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

	;; The following groupadd / usedadd invocation might
	;; be better as computed-file for /etc/passwd
	;; and /etc/group
	;; check how guix system does it?
	;; see (gnu build accounts) and (gnu system accounts)
	;; and esp. `create-user-database' in (gnu installer final)
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
	;; because guix time-machine calls (getpw (getuid))
	;; we need to have an entry for uid

	(invoke #$(file-append shadow "/sbin/useradd")
		"-d" "/var/empty"
		"-u" (format #f "~a" (getuid))
		"root")
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
	     (find-files #$(file-append guix "/share/guix"))))))

	
(concatenate-manifests
 (list
  (specifications->manifest
   '("guix"
     "bash"
     "coreutils"
     "sed"
     ;; so that guix-time-machine is happy with regards to pulling from git
     "nss-certs"))
 (manifest 
  ;; see (info "(guix) Writing Manifests")
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
