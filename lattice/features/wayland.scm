;;This file is controlled by /etc/dotfiles/README.org
;;ALL CHANGES ARE FUTILE!
(define-module (lattice features wayland)
  #:use-module (guix gexp)
  #:use-module (gnu home services)
  #:use-module (srfi srfi-1)
  #:use-module (gnu services)
  #:use-module (gnu services xorg)
  #:use-module (gnu packages wm)
  #:use-module (gnu packages image)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages terminals)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu home services shepherd)
  #:use-module (rde features)
  #:use-module (rde features fontutils)
  #:use-module (rde features predicates)
  #:use-module (rde features wm)
  #:use-module (lattice utils)
  #:use-module (lattice systems)
  #:use-module (dwl-guile utils)
  #:use-module (dwl-guile patches)
  #:use-module (dwl-guile home-service)
  #:use-module (dwl-guile configuration)
  #:use-module (dwl-guile configuration default-config)

  #:export (
            %lattice-dwl-config))


(define %lattice-dwl-guile-patches
  (list %patch-xwayland
        %patch-swallow
        %patch-movestack
        %patch-attachabove))

(define %lattice-dwl-guile-config
  (dwl-config
   (xkb-rules %lattice-keyboard-layout)
   (border-px 2)
   (rules
    (list
     (dwl-rule (id "emacs")
               (title "emacs")
               (alpha 0.9))))
   (keys
    (append
     (list
      (dwl-key
       (key "s-0")
       (action '(dwl:cycle-layout)))
      (dwl-key
       (key "s-<tab>")
       (action '(dwl:view-previous))))
     %dwl-base-keys))
   (colors
    (dwl-colors
     (root "#191919")
     (border "#808080")
     (focus "#FFCC00")))))

;; Checks if SYMBOL corresponds to a patch that is/will
;; be applied to dwl-guile, based on the features values in CONFIG.
;; SYMBOL should be the name of the patch, not including the ".patch" extension.
;; I.E @code{(has-dwl-patch? 'xwayland config)}.
(define (has-dwl-patch? symbol config)
  (let ((patch-name (string-append (symbol->string symbol) ".patch")))
    (find (lambda (p) (equal? patch-name (local-file-name p)))
          (get-value 'dwl-guile-patches config))))

(define* (feature-wayland-dwl-guile
          #:key
          (dwl-guile-configuration (home-dwl-guile-configuration)))
  "Setup dwl-guile."
  (ensure-pred home-dwl-guile-configuration? dwl-guile-configuration)
  (define (get-home-services config)
    "Return a list of home services required by dwl."
    (list
     (service home-dwl-guile-service-type
              dwl-guile-configuration)))

  (feature
   (name 'wayland-dwl-guile)
   (values `((wayland . #t)
             (dwl-guile . #t)
             (dwl-guile-patches
              . ,(home-dwl-guile-configuration-patches dwl-guile-configuration))))
   (home-services-getter get-home-services)))

(define* (feature-wayland-mako
          #:key
          (dismiss-key "C-s-d")
          (dismiss-all-key "C-S-s-d")
          (add-keybindings? #t))
  "Setup mako, a lightweight notification daemon for Wayland"

  (ensure-pred string? dismiss-key)
  (ensure-pred string? dismiss-all-key)
  (ensure-pred boolean? add-keybindings?)

  (define (get-home-services config)
    "Return a list of home services required by mako"
    (require-value 'font-monospace config)
    (make-service-list
     (simple-service
      'add-mako-home-packages-to-profile
      home-profile-service-type
      (pkgs '("mako" "libnotify")))
     (simple-service
      'create-mako-config
      home-files-service-type
      `((".config/mako/config"
         ,(alist->ini "mako-config"
                      `(("font"
                         . ,(font->string 'pango 'font-sans config
                                          #:size 11))
                        ("background-color" . "#252525FF")
                        ("text-color" . "#FFFFFFFF")
                        ("width" . 370)
                        ("height" . 100)
                        ("border-color" . "#555555FF")
                        ("border-size" . 1)
                        ("border-radius" . 0)
                        ("margin" . 5)
                        ("padding" . 10)
                        ("default-timeout" . 15000)
                        ("anchor" . "top-right")
                        ("max-visible" . 2)
                        ("format" . "<b>%s (%a)</b>\\n%b")
                        ("[grouped=true]")
                        ("format" . "<b>%s (%a, %g)</b>\\n%b")
                        ("[hidden]")
                        ("format" . "(%h more notification)"))))))
     (when (and add-keybindings? (get-value 'dwl-guile config))
       (simple-service
        'add-mako-dwl-keybindings
        home-dwl-guile-service-type
        (modify-dwl-guile-config
         (config =>
                 (dwl-config
                  (inherit config)
                  (keys
                   (append
                    (list
                     (dwl-key
                      (key dismiss-key)
                      (action `(system* ,(file-append mako "/bin/makoctl")
                                        "dismiss")))
                     (dwl-key
                      (key dismiss-all-key)
                      (action `(system* ,(file-append mako "/bin/makoctl")
                                        "dismiss" "--all"))))
                    (dwl-config-keys config))))))))))
  (feature
   (name 'wayland-mako)
   (home-services-getter get-home-services)))

(define* (feature-wayland-foot
          #:key
          (package foot)
          (set-default-terminal? #t)
          (window-alpha 0.9)
          (swallow-clients? #t)) ;; TODO: Add swallow patch automatically if #t?
  "Setup foot terminal."

  (ensure-pred package? package)
  (ensure-pred boolean? set-default-terminal?)
  (ensure-pred number? window-alpha)
  (ensure-pred boolean? swallow-clients?)

  (define (get-home-services config)
    "Return a list of home services required by foot."
    (require-value 'font-monospace config)
    (let ((has-dwl-guile? (get-value 'dwl-guile config)))
      (make-service-list
       (simple-service
        'add-foot-home-packages-to-profile
        home-profile-service-type
        (list package))
       (simple-service
        'create-foot-config
        home-files-service-type
        `((".config/foot/foot.ini"
           ,(alist->ini "foot-config"
                        `(("pad" . "5x5")
                          ("font" . "monospace:size=12")
                          ("dpi-aware" . "no")
                          ;; Certain TUI programs prefer "xterm"
                          ("term" . "xterm")

                          ("[key-bindings]")
                          ("scrollback-up-line" . "Mod1+k")
                          ("scrollback-down-line" . "Mod1+j")
                          ("clipboard-copy" . "Mod1+c")
                          ("clipboard-paste" . "Mod1+v")
                          ("search-start" . "Mod1+s")
                          ("font-increase" . "Mod1+Control+k")
                          ("font-decrease" . "Mod1+Control+j")
                          ("font-reset" . "Mod1+Control+0")
                          ;; This should be defined in dwl.
                          ("spawn-terminal" . "Mod1+Shift+Return")
                          ("show-urls-launch" . "Mod1+u")
                          ("show-urls-copy" . "Mod1+Control+u")

                          ("[search-bindings]")
                          ("find-prev" . "Mod1+p")
                          ("find-next" . "Mod1+n")
                          ("cursor-left" . "Mod1+h")
                          ("cursor-right" . "Mod1+l")
                          ("cursor-left-word" . "Mod1+b")
                          ("cursor-right-word" . "Mod1+w")
                          ("cursor-home" . "Mod1+i")
                          ("cursor-end" . "Mod1+a")
                          ("clipboard-paste" . "Mod1+v")

                          ("[mouse-bindings]")
                          ("select-begin-block" . "none")
                          ("select-word-whitespace" . "Mod1+BTN_LEFT-2"))))))
       (when (and set-default-terminal? has-dwl-guile?)
         (simple-service
          'set-foot-as-default-terminal
          home-dwl-guile-service-type
          (modify-dwl-guile-config
           (config =>
                   (dwl-config
                    (inherit config)
                    (rules
                     (append
                      (list
                       (dwl-rule
                        (id "foot")
                        (alpha  window-alpha)
                        (no-swallow (not swallow-clients?))
                        (terminal swallow-clients?)))
                      (dwl-config-rules config)))))))))))
  (feature
   (name 'wayland-foot)
   (home-services-getter get-home-services)))


(define-public %lattice-dwl-config
  (list
   (feature-wayland-dwl-guile
    #:dwl-guile-configuration
    (home-dwl-guile-configuration
     (patches %lattice-dwl-guile-patches)
     (config %lattice-dwl-guile-config)))
   (feature-wayland-mako)
   (feature-wayland-foot)))
