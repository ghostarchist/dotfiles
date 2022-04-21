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
  #:use-module (dtao-guile home-service)

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


(define* (feature-wayland-wlsunset
          #:key
          (package wlsunset)
          (auto-start? #t)
          (toggle-key "s-<end>")
          (latitude 33.3)
          (longitude -111.7)
          (gamma-low 2000)
          (gamma-high 6500)
          (add-keybindings? #t))
  "Setup wlsunset for adjusting day/night gamma for Wayland compositors."

  (ensure-pred package? wlsunset)
  (ensure-pred boolean? auto-start?)
  (ensure-pred string? toggle-key)
  (ensure-pred number? latitude)
  (ensure-pred number? longitude)
  (ensure-pred number? gamma-low)
  (ensure-pred number? gamma-high)
  (ensure-pred boolean? add-keybindings?)

  (define (get-home-services config)
    "Return a list of home services required by wlsunset"
    (let ((has-dwl-guile? (get-value 'dwl-guile config)))
      (make-service-list
       (simple-service
        'add-wlsunset-home-packages-to-profile
        home-profile-service-type
        (list package))
       (simple-service
        'add-wlsunset-shepherd-service
        home-shepherd-service-type
        (list
         (shepherd-service
          (documentation "Run wlsunset.")
          (provision '(wlsunset))
          (requirement (if has-dwl-guile? '(dwl-guile) '()))
          (auto-start? auto-start?)
          (respawn? #t)
          (start
           #~(make-forkexec-constructor
              (list
               #$(file-append wlsunset "/bin/wlsunset")
               #$(string-append "-l" (number->string latitude))
               #$(string-append "-L" (number->string longitude))
               #$(string-append "-t" (number->string gamma-low))
               #$(string-append "-T" (number->string gamma-high)))
              #:log-file #$(make-log-file "wlsunset")))
          (actions
           (list
            (shepherd-action
             (name 'toggle)
             (documentation "Toggles the wlsunset service on/off.")
             (procedure #~(lambda (running?)
                            (if running?
                                (stop 'wlsunset)
                                (start 'wlsunset))
                            #t)))))
          (stop #~(make-kill-destructor)))))
       (when (and add-keybindings? has-dwl-guile?)
         (simple-service
          'add-wlsunset-dwl-keybindings
          home-dwl-guile-service-type
          (modify-dwl-guile-config
           (config =>
                   (dwl-config
                    (inherit config)
                    (keys
                     (append
                      (list
                       (dwl-key
                        (key toggle-key)
                        (action `(system* ,(file-append shepherd "/bin/herd")
                                          "toggle"
                                          "wlsunset"))))
                      (dwl-config-keys config)))))))))))

  (feature
   (name 'wayland-wlsunset)
   (home-services-getter get-home-services)))

(define lattice-dtao-guile-left-blocks
  (append
   (map
    (lambda (tag)
      (let ((str (string-append "^p(8)" (number->string tag) "^p(8)"))
            (index (- tag 1)))
        (dtao-block
         (interval 0)
         (events? #t)
         (click `(match button
                   (0 (dtao:view ,index))))
         (render `(cond
                   ((dtao:selected-tag? ,index)
                    ,(string-append "^bg(#ffcc00)^fg(#191919)" str "^fg()^bg()"))
                   ((dtao:urgent-tag? ,index)
                    ,(string-append "^bg(#ff0000)^fg(#ffffff)" str "^fg()^bg()"))
                   ((dtao:active-tag? ,index)
                    ,(string-append "^bg(#323232)^fg(#ffffff)" str "^fg()^bg()"))
                   (else ,str))))))
    (iota 9 1))
   (list
    (dtao-block
     (events? #t)
     (click `(dtao:next-layout))
     (render `(string-append "^p(4)" (dtao:get-layout)))))))

(define lattice-dtao-guile-center-blocks
  (list
   (dtao-block
    (events? #t)
    (render `(dtao:title)))))

(define lattice-dtao-guile-right-blocks
  (list
   (dtao-block
    (interval 1)
    (render `(strftime "%A, %d %b (w.%V) %T" (localtime (current-time)))))))

(define* (feature-wayland-dtao-guile)
  "Install and configure dtao-guile"

  (define height 25)

  (define (get-home-services config)
    "Return a list of home services required by dtao-guile."
    (require-value 'font-monospace config)
    (list
     (service home-dtao-guile-service-type
              (home-dtao-guile-configuration
               (config
                (dtao-config
                 (font(font->string 'fcft 'font-monospace config
                                    #:bold? #t))
                 (block-spacing 0)
                 (use-dwl-guile-colorscheme? #t)
                 (modules '((ice-9 match)
                            (ice-9 popen)
                            (ice-9 rdelim)
                            (srfi srfi-1)))
                 (padding-left 0)
                 (padding-top 0)
                 (padding-bottom 0)
                 (height height)
                 (left-blocks lattice-dtao-guile-left-blocks)
                 (center-blocks lattice-dtao-guile-center-blocks)
                 (right-blocks lattice-dtao-guile-right-blocks)))))))

  (feature
   (name 'wayland-dtao-guile)
   (values `((statusbar? . #t)
             (statusbar-height . ,height)
             (dtao-guile . #t)))
   (home-services-getter get-home-services)))

(define* (feature-wayland-bemenu
          #:key
          (set-default-menu? #t))
  "Setup bemenu."

  (ensure-pred boolean? set-default-menu?)

  (define (get-home-services config)
    "Return a list of home services required by bemenu."
    (require-value 'font-monospace config)
    (make-service-list
     (simple-service
      'add-bemenu-home-package-to-profile
      home-profile-service-type
      (list bemenu))
     (when (and set-default-menu? (get-value 'dwl-guile config))
       (simple-service
        'set-bemenu-as-default-menu
        home-dwl-guile-service-type
        (modify-dwl-guile-config
         (config =>
                 (dwl-config
                  (inherit config)
                  (menu `(,(file-append bemenu "/bin/bemenu-run"))))))))
     (simple-service
      'bemenu-options
      home-environment-variables-service-type
      (alist->environment-variable
       "BEMENU_OPTS"
       `(("ignorecase" . #t)
         ("line-height"
          . ,(get-value 'statusbar-height config 25))
         ("filter" . #f)
         ("wrap" . #f)
         ("list" . #f)
         ("prompt" #f)
         ("prefix" . #f)
         ("index" . #f)
         ("password" . #f)
         ("scrollbar" . #f)
         ("ifne" . #f)
         ("fork" . #f)
         ("no-exec" . #f)
         ("bottom" . #f)
         ("grab" . #f)
         ("no-overlap" . #f)
         ("monitor" . #f)
         ("fn"
          . ,(font->string 'pango 'font-monospace config
                           #:bold? #t
                           #:size 10))
         ("tb" . "#FFCC00")
         ("tf" . "#000000")
         ("fb" . "#1A1A1A")
         ("ff" . "#FFFFFF")
         ("nb" . "#1A1A1A")
         ("nf" . "#FFFFFF")
         ("hb" . "#1A1A1A")
         ("hf" . "#FFCC00")
         ("sb" . #f)
         ("sf" . #f)
         ("scb" . #f)
         ("scf" . #f))))))
  (feature
   (name 'wayland-bemenu)
   (home-service-getter get-home-services)))

(define-public %lattice-dwl-config
  (list
   (feature-wayland-dwl-guile
    #:dwl-guile-configuration
    (home-dwl-guile-configuration
     (patches %lattice-dwl-guile-patches)
     (config %lattice-dwl-guile-config)))
   (feature-wayland-mako)
   (feature-wayland-foot)
   (feature-wayland-wlsunset)
   (feature-wayland-dtao-guile)))
