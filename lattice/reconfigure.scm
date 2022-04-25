(define-module (lattice reconfigure)
  #:use-module (ice-9 match)
  #:use-module (ice-9 exceptions)
  #:use-module (ice-9 pretty-print)
  #:use-module (gnu system)
  #:use-module (gnu system accounts)
  #:use-module (rde features)
  #:use-module (rde features predicates)
  #:use-module (lattice systems)
  #:export (make-config))

;; Allows dynamic loading of configuration modules based on file name.
(define* (dynamic-load sub mod var-name #:key (throw? #t))
  (let ((var (module-variable
              (resolve-module `(lattice ,sub ,(string->symbol mod))) var-name)))
    (if (or (not var) (not (variable-bound? var)))
        (when throw?
          (raise-exception
           (make-exception-with-message
            (string-append "reconfigure: could not load module '" mod"'"))))
        (variable-ref var))))

;; Finds a list of needed user supplementary groups for feature with
;; a value of name. Returns an empty list if no groups are found.
(define (get-feature-groups name config)
  (let ((groups (get-value name config)))
    (if groups groups '())))

;; Create a system or home configuration based on some parameters.
;; Generally, you want to call this procedure with no arguments.
(define* (make-config
          #:key
          (user (getenv "USER"))
          (system (gethostname))
          (target (getenv "RDE_TARGET"))
          (initial-os %lattice-initial-os))

  (ensure-pred string? user)
  (ensure-pred string? system)
  (ensure-pred operating-system? initial-os)

  ;; Check if a swap device has been set in the system configuration.
  (define %initial-os
    (if (or (unspecified? %system-swap) (null? %system-swap))
        initial-os
        (operating-system
         (inherit initial-os)
         (swap-devices
          (list %system-swap)))))

  ;; Allis good, create the configuration
  (define %generated-config
    (rde-config
     (initial-os %initial-os)
     (features
      (append
       %user-features
       %lattice-system-base-features
       %system-features))))

  (define %lattice-he
    (rde-config-home-environment %generated-config))

  (define %lattice-system
    (operating-system
     (inherit (rde-config-operating-system %generated-config))
     (issue (operating-system-issue %initial-os))))

  (match target
    ("home" %lattice-he)
    ("system" %lattice-system)
    (_ %lattice-system)))
