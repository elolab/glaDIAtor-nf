(use-modules (gnu))
(use-modules (gnu packages))
(use-package-modules bootloaders)
(use-service-modules base)

(operating-system
  (host-name "faker")
  (bootloader (bootloader-configuration
               (bootloader grub-bootloader)
               (targets '("/dev/vda"))
               (terminal-outputs '(console))))
  (packages (append (map specification->package
			 '("bash-minimal"
			   "guix"
			   "sed"
			   "coreutils"
			   ))
		    %base-packages))
  (services
   (modify-services %base-services
     (guix-service-type config =>
			(guix-configuration
			 (inherit config)
			 ;; save some time at startup to not need to generate a key
			 (generate-substitute-key? #f)
			 ;; in docker cannot chroot unless priviliged
			 (extra-options '("--disable-chroot"))))))
  (file-systems %base-file-systems))



;; Local Variables:
;; compile-command: "guix time-machine -C ../channels.scm -- system image --image-type=docker gitlab-runner-system.scm"
;; End:
