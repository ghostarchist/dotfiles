;;This file is controlled by /etc/dotfiles/README.org
;;ALL CHANGES ARE FUTILE!
(define-module (lattice systems)
  #:use-module (gnu system)
  #:use-module (gnu system keyboard)
  #:use-module (gnu system file-systems)
  #:use-module (gnu bootloader)
  #:use-module (gnu bootloader grub)
  #:use-module (rde features)
  #:use-module (rde features base)
  #:use-module (rde features system)
  #:use-module (rde features keyboard)
  #:export (
            %lattice-timezone
            %lattice-locale
            %lattice-kernel-arguments
            %lattice-keyboard-layout
            %lattice-initial-os
            %lattice-system-base-features))

(define-public %lattice-timezone "America/Phoenix")
(define-public %lattice-locale "en_US.utf8")

(define-public %lattice-kernel-arguments
  (list "modprobe.blacklist=pcspkr,snd_pcsp"
        "quiet"))

(define-public %lattice-keyboard-layout
  (keyboard-layout "us"
                   #:options
                   '("ctrl:swapcaps")))

(define-public %lattice-initial-os
  (operating-system
   (host-name "hal")
   (locale %lattice-locale)
   (timezone %lattice-timezone)
   (kernel-arguments %lattice-kernel-arguments)
   (keyboard-layout %lattice-keyboard-layout)
   (bootloader (bootloader-configuration
                (bootloader grub-efi-bootloader)
                (targets '("/boot/efi"))))
   (services '())
   (file-systems %base-file-systems)
   (issue "This is the GNU/Lattice system.\n")))

(define-public %lattice-system-base-features
  (list
   (feature-keyboard
    #:keyboard-layout %lattice-keyboard-layout)))
