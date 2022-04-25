(define-module (lattice configs)
  #:use-module (guix gexp)
  #:use-module (gnu packages fonts)
  #:use-module (rde features)
  #:use-module (rde features xdg)
  #:use-module (rde features ssh)
  #:use-module (rde features base)
  #:use-module (rde features linux)
  #:use-module (rde features fontutils)
  #:use-module (rde features docker)
  #:use-module (rde features bittorrent)
  #:use-module (rde features shells)
  #:use-module (rde features version-control)
  #:use-module (rde features video)
  #:use-module (dwl-guile patches)
  #:use-module (dwl-guile home-service)
  #:use-module (dtao-guile home-service)
  #:use-module (lattice utils)
  #:use-module (lattice systems)
  #:use-module (lattice features emacs)
  #:use-module (lattice features wayland)
  #:use-module (lattice features nix))

(define %lattice-base-system-packages
  (pkgs '("git" "nss-certs")))

(define %lattice-base-home-packages
  (pkgs '("curl" "htop" "ncurses" "adwaita-icon-theme" "gnome-themes-standard" "nyxt" "ungoogled-chromium-wayland" "ublock-origin-chromium" "imv")))

(define %lattice-base-features
  (list
   (feature-base-services)
   (feature-desktop-services)
   (feature-docker)
   (feature-pipewire)
   (feature-backlight #:step 5)

   (feature-fonts
    #:font-monospace (font "Iosevka" #:size 11 #:weight 'regular)
    #:font-packages (list font-iosevka font-fira-mono))

   (feature-transmission #:auto-start? #f)
   (feature-ssh)
   (feature-zsh)

   (feature-base-packages
    #:system-packages %lattice-base-system-packages
    #:home-packages %lattice-base-home-packages)
   (feature-nix)
   (feature-mpv)
   (feature-wayland-mako)
   (feature-wayland-foot)
   (feature-wayland-wlsunset)
   (feature-wayland-dtao-guile)
   (feature-wayland-dwl-guile
    #:dwl-guile-configuration
    (home-dwl-guile-configuration
     (patches %lattice-dwl-guile-patches)
     (config %lattice-dwl-guile-config)))))
