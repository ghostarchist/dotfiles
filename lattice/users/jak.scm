(define-module (lattice users jak)
  #:use-module (rde features)
  #:use-module (rde features ssh)
  #:use-module (rde features base)
  #:use-module (rde features gnupg)
  #:use-module (gnu services)
  #:use-module (gnu services databases)
  #:use-module (gnu home-services ssh)
  #:use-module (lattice utils)
  #:use-module (lattice configs)
  #:use-module (lattice features emacs)
  #:use-module (lattice features wayland))

(define-public %user-features
  (append
   (list
    (feature-user-info
     #:user-name "jak"
     #:full-name "Jacob Boldman"
     #:email "jacob@boldman.co"))))
