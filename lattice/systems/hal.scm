(define-module (lattice systems hal)
         #:use-module (lattice utils)
         #:use-module (lattice systems)
         #:use-module (rde features system)
         #:use-module (gnu bootloader)
         #:use-module (gnu bootloader grub)
         #:use-module (dwl-guile home-service)
         #:use-module (gnu system file-systems)
         #:use-module (gnu system mapped-devices)
         #:export (
                   %system-features))



       (define-public %system-features
         (list
          (feature-host-info
           #:host-name "hal"
           #:timezone %lattice-timezone
           #:locale %lattice-locale)
          (feature-bootloader)
          (feature-file-systems
           #:file-systems
           (list
            (file-system
             (mount-point "/boot/efi")
             (device (uuid "0351-5D8F" 'fat32))
             (type "vfat"))
            (file-system
             (mount-point "/")
             (device
              (uuid "01ccdad1-366b-4d8d-92e8-30315e87e8b9"))
             (type "ext4"))))))
