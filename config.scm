;;This file is controlled by /etc/dotfiles/README.org
;;ALL CHANGES ARE FUTILE!
(define-module (config)
  #:use-module (rde features)
  #:use-module (rde features base)
  #:use-module (rde features gnupg)
  #:use-module (rde features keyboard)
  #:use-module (rde features system)
  #:use-module (rde features wm)
  #:use-module (rde features xdisorg)
  #:use-module (rde features xdg)
  #:use-module (rde features password-utils)
  #:use-module (rde features version-control)
  #:use-module (rde features fontutils)
  #:use-module (rde features terminals)
  #:use-module (rde features tmux)
  #:use-module (rde features shells)
  #:use-module (rde features ssh)
  #:use-module (rde features emacs)
  #:use-module (rde features linux)
  #:use-module (rde features bittorrent)
  #:use-module (rde features mail)
  #:use-module (rde features docker)
  #:use-module (rde features video)
  #:use-module (rde features markup)
  #:use-module (rde features networking)
  #:use-module (gnu services)
  #:use-module (gnu system)
  #:use-module (gnu system keyboard)
  #:use-module (gnu system file-systems)
  #:use-module (gnu system mapped-devices)
  #:use-module (gnu packages)
  #:use-module (rde packages emacs)
  #:use-module (rde packages emacs-xyz)
  #:use-module (gnu packages fonts)
  #:use-module (guix gexp)
  #:use-module (guix inferior)
  #:use-module (guix channels)
  #:use-module (lattice systems)
  #:use-module (lattice features emacs)
  #:use-module (lattice features wayland)
  #:use-module (lattice systems)
  #:use-module (lattice users jak)
  #:use-module (ice-9 match))


;; User-specific features

(define %jak-features
  (list
   (feature-user-info
    #:user-name "jak"
    #:full-name "Jacob Boldman"
    #:email "jacob@boldman.co")))

;;; Generic features should be applicable for various hosts/users/etc

(define* (pkgs #:rest lst)
  (map specification->package+output lst))

(define* (pkgs-vanilla #:rest lst)
  "Packages from guix channel."
  (define channel-guix
    (list (channel
           (name 'guix)
           (url "https://git.savannah.gnu.org/git/guix.git")
           (commit
            "2b6af630d61dd5b16424be55088de2b079e9fbaf"))))
  (define inferior (inferior-for-channels channel-guix))
  (define (get-inferior-pkg pkg-name)
    (car (lookup-inferior-pkg pkg-name)))

  (map get-inferior-pkg lst))

;;; WARNING: The order can be important for features extending
;;; service of other features. Be careful changing it.
(define %main-features
  (append
   (list
    (feature-base-services)
    (feature-desktop-services)
    (feature-docker)
    (feature-pipewire)
    (feature-backlight #:step 5)

    (feature-fonts
     #:font-monospace (font "Iosevka" #:size 11 #:weight 'regular)
     #:font-packages (list font-iosevka font-fira-mono))

    (feature-markdown)
    (feature-transmission #:auto-start? #f)
    (feature-ssh)
    (feature-zsh)

    (feature-base-packages
     #:home-packages
     (append
      (pkgs
       "nyxt"
       "ungoogled-chromium-wayland" "ublock-origin-chromium"

       "jami"

       "alsa-utils" "youtube-dl" "imv"
       "pavucontrol" "wev"
       "hicolor-icon-theme" "adwaita-icon-theme" "gnome-themes-standard"
       "papirus-icon-theme" "arc-theme"
       "ffmpeg"
       "ripgrep" "curl"))))

   %lattice-system-base-features
   %lattice-emacs-base-features
   %lattice-dwl-config))

;;; Hardware/host specific features

(define hal-file-systems
  (list (file-system
          (mount-point "/boot/efi")
          (device (uuid "0351-5D8F" 'fat32))
          (type "vfat"))
         (file-system
          (mount-point "/")
          (device
           (uuid "01ccdad1-366b-4d8d-92e8-30315e87e8b9"))
          (type "ext4"))))

(define %hal-features
  (list
   (feature-host-info
    #:host-name "hal"
    #:timezone %lattice-timezone)
   ;;Setup bootloader
   ;;(feature-bootloader)
   (feature-file-systems
    #:file-systems hal-file-systems)))

;;; rde-config and helpers for generating home-environment and
;;; operating-system records.

(define-public hal-config
  (rde-config
   (features
    (append
     %user-features
     %main-features
     %hal-features))))

(define-public hal-os
  (rde-config-operating-system hal-config))

(define hal-he
  (rde-config-home-environment hal-config))

(define (dispatcher)
  (let ((rde-target (getenv "RDE_TARGET")))
    (match rde-target
      ("hal-home" (rde-config-home-environment hal-config))
      ("hal-system" (rde-config-operating-system hal-config)))))

(dispatcher)
