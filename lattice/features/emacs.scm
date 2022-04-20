;;This file is controlled by /etc/dotfiles/README.org
;;ALL CHANGES ARE FUTILE!
(define-module (lattice features emacs)
  #:use-module (guix gexp)
  #:use-module (gnu home services)
  #:use-module (gnu services)
  #:use-module (gnu packages)
  #:use-module (gnu packages emacs)
  #:use-module (gnu packages emacs-xyz)
  #:use-module (rde features)
  #:use-module (rde features base)
  #:use-module (rde features emacs)

  #:export (%lattice-emacs-base-features))

(define* (make-emacs-feature base-name
			     #:key
			     (home-services (const '()))
			     (system-services (const '())))
  "Creates a basic emacs feature configuration."
  (let ((f-name (symbol-append 'emacs- base-name)))
    (feature
     (name f-name)
     (values `((,f-name . #t)))
     (home-services-getter home-services)
     (system-services-getter system-services))))

(define* (feature-emacs-evil
	  #:key
	  (no-insert-state-message? #t)
	  (leader? #t)
	  (undo-fu? #t)
	  (commentary? #t)
	  (collection? #t)
	  (surround? #t))
  "Add and configure evil-mode for Emacs."
  (ensure-pred boolean? no-insert-state-message?)
  (ensure-pred boolean? leader?)
  (ensure-pred boolean? undo-fu?)
  (ensure-pred boolean? collection?)
  (ensure-pred boolean? surround?)
  (define emacs-f-name 'evil)

  (define (get-home-services config)
    (list
     (elisp-configuration-service
      emacs-f-name
      `(;; Make the Escape key behave more nicely for evil-mode
	(global-set-key (kbd "<escape>") 'keyboard-quit)
	(define-key query-replace-map (kbd "<escape>") 'quit)
	;; Hide ``-- INSERT --'' message
	,@(if no-insert-state-message?
	      `((setq evil-insert-state-message nil))
	      '())
	;; Required by the additional packages
	(setq evil-want-keybinding nil)
	;; Use C-u to scroll up
	(setq evil-want-C-u-scroll t)
	;; undo with higher granularity
	(setq evil-want-fine-undo t)
	;; The packages below must be loaded and configured in a certain order
	(require 'evil)
	,@(if leader?
	      `((require 'evil-leader)
		(global-evil-leader-mode)
		(evil-leader/set-leader "<SPC>")
		(evil-leader/set-key
		 "<SPC>" 'find-file
		 "b" 'switch-to-buffer
		 "k" 'kill-buffer
		 "K" 'kill-this-buffer
		 "s" 'save-buffer
		 "S" 'evil-write-all
		 )
		'()))
	,@(if undo-fu?
	      `((eval-when-compile (require 'undo-fu))
		(setq evil-undo-system 'undo-fu)
		(define-key evil-normal-state-map (kbd "u") 'undo-fu-only-undo)
		(define-key evil-normal-state-map (kbd "C-r") 'undo-fu-only-redo))
	      '())
	(evil-mode 1)
	,@(if commentary?
	      `((require 'evil-commentary)
		(evil-commentary-mode))
	      '())
	,@(if collection?
	      `((when (require 'evil-collection nil t)
		  (evil-collection-init)))
	      '())
	,@(if surround?
	      `((require 'evil-surround)
		(global-evil-surround-mode 1))
	      '())
	)
      #:elisp-packages (list
			emacs-evil
			(if leader? emacs-evil-leader)
			(if undo-fu? emacs-undo-fu)
			(if commentary? emacs-evil-commentary)
			(if collection? emacs-evil-collection)
			(if surround? emacs-evil-surround)))))
  (make-emacs-feature emacs-f-name
		      #:home-services get-home-services))



(define* (pkgs #:rest lst)
  (map specification->package+output lst))

(define %lattice-emacs-base-features
  (list
   (feature-emacs
    ;;#:emacs emacs-pgtk-native-comp
    #:extra-init-el `()
    #:additional-elisp-packages
    (append
     (list emacs-consult-dir)
     (pkgs "emacs-elfeed" "emacs-hl-todo"
	   "emacs-ytdl"
	   "emacs-ement"
	   "emacs-restart-emacs"
	   "emacs-org-present")))
   (feature-emacs-appearance)
   (feature-emacs-faces)
   (feature-emacs-evil)
   (feature-emacs-completion
    #:mini-frame? #t)
   (feature-emacs-vertico)
   (feature-emacs-project)
   (feature-emacs-perspective)
   (feature-emacs-input-methods)
   (feature-emacs-which-key)
   (feature-emacs-keycast #:turn-on? #f)

   (feature-emacs-dired)
   (feature-emacs-eshell)
   (feature-emacs-monocle)
   (feature-emacs-elpher)
   (feature-emacs-pdf-tools)

   (feature-emacs-git)
   (feature-emacs-org
    #:org-directory "~/org")
   (feature-emacs-org-roam
    #:org-roam-directory "~/org/slipbox")
   (feature-emacs-org-agenda
    #:org-agenda-files '("~/org/todo.org"))))
