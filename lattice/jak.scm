(define-module (lattice jak)
  #:use-module (gnu services)
  #:use-module (gnu services databases)
  #:use-module (gnu home-services ssh)
  #:use-module (rde features ssh)
  #:use-module (rde features base)
  #:use-module (rde features gnupg)
  #:use-module (lattice utils)
  #:use-module (lattice configs)
  #:use-module (lattice features emacs)
  #:use-module (lattice features wayland)
  #:export (%user-features))

(define-public %user-features
  (append
   (list
    (feature-user-info
     #:user-name "jak"
     #:full-name "Jacob Boldman"
     #:email "jacob@boldman.co")
    %lattice-emacs-base-features
    %lattice-base-features)))
