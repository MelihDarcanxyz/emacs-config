;; [[file:README.org::*Package Manager][Package Manager:1]]
(defvar elpaca-installer-version 0.4)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
                            :ref nil
                            :files (:defaults (:exclude "extensions"))
                            :build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
    (build (expand-file-name "elpaca/" elpaca-builds-directory))
    (order (cdr elpaca-order))
    (default-directory repo))
(add-to-list 'load-path (if (file-exists-p build) build repo))
(unless (file-exists-p repo)
    (make-directory repo t)
    (when (< emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
        (if-let ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
                ((zerop (call-process "git" nil buffer t "clone"
                                    (plist-get order :repo) repo)))
                ((zerop (call-process "git" nil buffer t "checkout"
                                    (or (plist-get order :ref) "--"))))
                (emacs (concat invocation-directory invocation-name))
                ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
                                    "--eval" "(byte-recompile-directory \".\" 0 'force)")))
                ((require 'elpaca))
                ((elpaca-generate-autoloads "elpaca" repo)))
            (kill-buffer buffer)
        (error "%s" (with-current-buffer buffer (buffer-string))))
    ((error) (warn "%s" err) (delete-directory repo 'recursive))))
(unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))


;; Install use-package support
(elpaca elpaca-use-package
;; Enable :elpaca use-package keyword.
(elpaca-use-package-mode)
;; Assume :elpaca t unless otherwise specified.
(setq elpaca-use-package-by-default t))

;; Block until current queue processed.
(elpaca-wait)

;;For example:
;;(use-package general :demand t)
;;(elpaca-wait)

;;Turns off elpaca-use-package-mode current declartion
;;Note this will cause the declaration to be interpreted immediately (not deferred).
;;Useful for configuring built-in emacs features.
(use-package emacs :elpaca nil :config (setq ring-bell-function #'ignore))

;; Don't install anything. Defer execution of BODY
(elpaca nil (message "deferred"))
;; Package Manager:1 ends here

;; [[file:README.org::*Evil Mode][Evil Mode:1]]
;; Expands to: (elpaca evil (use-package evil :demand t))
(use-package evil
    :init      ;; tweak evil's configuration before loading it
    (setq evil-want-integration t) ;; This is optional since it's already set to t by default.
    (setq evil-want-keybinding nil)
    (setq evil-vsplit-window-right t)
    (setq evil-split-window-below t)
    :config
    (evil-mode 1)

    (evil-global-set-key 'motion "j" 'evil-next-visual-line)
    (evil-global-set-key 'motion "k" 'evil-previous-visual-line)

    ;; This is necessary for org mode folding to work
    (evil-define-key 'normal 'org-mode-map (kbd "<tab>") 'org-cycle)
    
    (evil-set-initial-state 'messages-buffer-mode 'normal)
    (evil-set-initial-state 'dashboard-mode 'normal)
)

(use-package evil-collection
    :after evil
    :config
    (setq evil-collection-mode-list '(dashboard dired ibuffer))
    (evil-collection-init)
)

(use-package evil-tutor)
;; Evil Mode:1 ends here

;; [[file:README.org::*General Keybindings][General Keybindings:1]]
(use-package general
      :config
      (general-evil-setup)

      ;; set up 'SPC' as the global leader key
      (general-create-definer md/leader-keys
      :states '(normal insert visual emacs)
      :keymaps 'override
      :prefix "SPC" ;; set leader
      :global-prefix "M-SPC") ;; access leader in insert mode

      (md/leader-keys
      "b" '(:ignore t :wk "Buffer")
      "b b" '(switch-to-buffer :wk "Switch buffer")
      "b i" '(ibuffer :wk "Ibuffer")
      "b k" '(kill-this-buffer :wk "Kill this buffer")
      "b n" '(next-buffer :wk "Next buffer")
      "b p" '(previous-buffer :wk "Previous buffer")
      "b r" '(revert-buffer :wk "Reload buffer"))

      (md/leader-keys
      "h" '(:ignore t :wk "Help")
      "h f" '(counsel-describe-function :wk "Describe function")
      "h v" '(counsel-describe-variable :wk "Describe variable"))

      (md/leader-keys
      "." '(counsel-find-file :wk "Find file")
      "f c" '((lambda () (interactive) (counsel-find-file "~/.emacs.d/README.org")) :wk "Edit emacs config")
      "f r" '(counsel-recentf :wk "Find recent files")
      "TAB TAB" '(comment-line :wk "(Un)comment line"))

      (md/leader-keys
      "t" '(:ignore t :wk "Toggle")
      "t l" '(display-line-numbers-mode :wk "Toggle line numbers")
      "t t" '(visual-line-mode :wk "Toggle truncated lines"))

      (md/leader-keys
      :keymaps 'org-mode-map
      "o" '(:ignore t :wk "Org mode")
      "o l" '(org-insert-link :wk "Insert link")
      "o o" '(org-open-at-point :wk "Open link")
      "o t" '(org-babel-tangle :wk "Tangle file")
      "o c" '(org-toggle-checkbox :wk "Toggle checkbox")
      "o s" '(org-schedule :wk "Insert schedule")
      "o d" '(org-deadline :wk "Insert deadline")
      "o a" '(:ignore t :wk "Org agenda")
      "o a a" '(org-agenda :wk "Org agenda")
      "o a l" '(org-agenda-list :wk "Org agenda list")
      )
)

  (global-set-key (kbd "<escape>") 'keyboard-escape-quit)
;; General Keybindings:1 ends here

;; [[file:README.org::*Diminish][Diminish:1]]
(use-package diminish)
;; Diminish:1 ends here

;; [[file:README.org::*Ivy List Utility][Ivy List Utility:1]]
(use-package counsel
    :after ivy
;    :bind (("M-x" . counsel-M-x)
;           ("C-x b" . counsel-ibuffer)
;           ("C-x C-f" . counsel-find-file)
;           :map minibuffer-local-map
;           ("C-r" . 'counsel-minibuffer-history))
    :config
    (counsel-mode)
    (setq ivy-initial-inputs-alist nil)) ;; Don't start searches with ^

(use-package ivy
    :diminish
    :config
    (ivy-mode))

(use-package all-the-icons-ivy-rich
    :ensure t
    :init (all-the-icons-ivy-rich-mode 1))

(use-package ivy-rich
  :after ivy
  :ensure t
  :init (ivy-rich-mode 1) ;; this gets us descriptions in M-x.
  :custom
  (ivy-virtual-abbreviate 'full
   ivy-rich-switch-buffer-align-virtual-buffer t
   ivy-rich-path-style 'abbrev)
  :config
  (ivy-set-display-transformer 'ivy-switch-buffer
                               'ivy-rich-switch-buffer-transformer))
;; Ivy List Utility:1 ends here

;; [[file:README.org::*Helpful][Helpful:1]]
(use-package helpful
  :commands (helpful-callable helpful-variable helpful-command helpful-key)
  :custom
  (counsel-describe-function-function #'helpful-callable)
  (counsel-describe-variable-function #'helpful-variable)
  :bind
  ([remap describe-function] . counsel-describe-function)
  ([remap describe-command] . helpful-command)
  ([remap describe-variable] . counsel-describe-variable)
  ([remap describe-key] . helpful-key))
;; Helpful:1 ends here

;; [[file:README.org::*Projectile][Projectile:1]]
(use-package projectile
    :diminish projectile-mode
    :config (projectile-mode)
    :custom ((projectile-completion-system 'ivy))
    :init
    (when (file-directory-p "~/Projects")
        (setq projectile-project-search-path '("~/Projects")))
    (setq projectile-switch-project-action #'projectile-dired))

(use-package counsel-projectile
    :config (counsel-projectile-mode))
;; Projectile:1 ends here

;; [[file:README.org::*Magit][Magit:1]]
(use-package magit
    :custom 
    (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

;; This is deprecated. Use evil-collection instead
;; (use-package evil-magit
;;     :after magit)

;; More like live in emacs package
(use-package forge)
;; Magit:1 ends here

;; [[file:README.org::*Dashboard][Dashboard:1]]
(use-package dashboard
    :ensure t
    :after org
    :init
    (progn
    (setq dashboard-items '((recents . 5)
                            (bookmarks . 5)
                            (projects . 5)
                            (agenda . 5)
                            (registers . 5)))
    (setq dashboard-show-shortcuts t)
    (setq dashboard-center-content nil)
    (setq dashboard-banner-logo-title "Welcome aboard captain.")
    (setq dashboard-set-file-icons t)
    (setq dashboard-set-heading-icons t)
    (setq dashboard-startup-banner 'logo)

    (setq dashboard-set-navigator t)
    (setq dashboard-navigator-buttons
    `(;; line1
    ((,(all-the-icons-octicon "mark-github" :height 1.1 :v-adjust 0.0)
    "Homepage"
    "Browse homepage"
    (lambda (&rest _) (browse-url "homepage")))
    ("★" "Star" "Show stars" (lambda (&rest _) (show-stars)) warning)
    ("?" "" "?/h" #'show-help nil "<" ">"))
    ;; line 2
    ((,(all-the-icons-faicon "linkedin" :height 1.1 :v-adjust 0.0)
    "Linkedin"
    ""
    (lambda (&rest _) (browse-url "homepage")))
    ("⚑" nil "Show flags" (lambda (&rest _) (message "flag")) error)))))
    
 
    :config
    (dashboard-setup-startup-hook)
)
;; Dashboard:1 ends here

;; [[file:README.org::*Disable Menubar, Toolbars and Scrollbars][Disable Menubar, Toolbars and Scrollbars:1]]
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq inhibit-startup-message t)
(setq visible-bell t)
;; Disable Menubar, Toolbars and Scrollbars:1 ends here

;; [[file:README.org::*Display Line Numbers and Truncated Lines][Display Line Numbers and Truncated Lines:1]]
(column-number-mode)
(global-display-line-numbers-mode 1)
(global-visual-line-mode t)

(setq display-line-numbers-type 'relative)

(dolist (mode '(term-mode-hook
                shell-mode-hook
                eshell-mode-hook))
    (add-hook mode(lambda () (display-line-numbers-mode 0))))
;; Display Line Numbers and Truncated Lines:1 ends here

;; [[file:README.org::*Scrolling][Scrolling:1]]
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1))) ;; one line at a time
(setq mouse-wheel-progressive-speed nil) ;; don't accelerate scrolling
(setq mouse-wheel-follow-mouse 't) ;; scroll window under mouse
(setq scroll-step 1) ;; keyboard scroll one line at a time
;; Scrolling:1 ends here

;; [[file:README.org::*Modeline][Modeline:1]]
(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  :custom (doom-modeline-height 32))
;; Modeline:1 ends here

;; [[file:README.org::*Theme][Theme:1]]
;; (load-theme 'deeper-blue t)

(use-package doom-themes
  :ensure t
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
  (load-theme 'doom-one t)

  ;; Enable flashing mode-line on errors
  (doom-themes-visual-bell-config)
  ;; Enable custom neotree theme (all-the-icons must be installed!)
  (doom-themes-neotree-config)
  ;; or for treemacs users
  (setq doom-themes-treemacs-theme "doom-atom") ; use "doom-colors" for less minimal icon theme
  (doom-themes-treemacs-config)
  ;; Corrects (and improves) org-mode's native fontification.
  (doom-themes-org-config))
;; Theme:1 ends here

;; [[file:README.org::*Fonts][Fonts:1]]
(set-face-attribute 'default nil
    :font "JetBrains Mono"
    :height 110
    :weight 'medium)
(set-face-attribute 'variable-pitch nil
    :font "Ubuntu"
    :height 120
    :weight 'medium)
(set-face-attribute 'fixed-pitch nil
    :font "JetBrains Mono"
    :height 110
    :weight 'medium)
;; Makes commented text and keywords italics.
;; This is working in emacsclient but not emacs.
;; Your font must have an italic face available.
(set-face-attribute 'font-lock-comment-face nil
    :slant 'italic)
(set-face-attribute 'font-lock-keyword-face nil
    :slant 'italic)

;; This sets the default font on all graphical frames created after restarting Emacs.
;; Does the same thing as 'set-face-attribute default' above, but emacsclient fonts
;; are not right unless I also add this method of setting the default font.
(add-to-list 'default-frame-alist '(font . "JetBrains Mono-12"))

;; Uncomment the following line if line spacing needs adjusting.
(setq-default line-spacing 0.12)
;; Fonts:1 ends here

;; [[file:README.org::*Icons][Icons:1]]
(use-package all-the-icons
    :ensure t
    :if (display-graphic-p))

(use-package all-the-icons-dired
    :hook (dired-mode . (lambda () (all-the-icons-dired-mode t))))

(use-package nerd-icons
  ;; :custom
  ;; The Nerd Font you want to use in GUI
  ;; "Symbols Nerd Font Mono" is the default and is recommended
  ;; but you can use any other Nerd Font if you want
  ;; (nerd-icons-font-family "Symbols Nerd Font Mono")
 )
;; Icons:1 ends here

;; [[file:README.org::*Rainbow Brackets][Rainbow Brackets:1]]
(use-package rainbow-delimiters
    :hook (prog-mode . rainbow-delimiters-mode))
;; Rainbow Brackets:1 ends here

;; [[file:README.org::*ORG][ORG:1]]
(defun md/org-font-setup ()
  ;; Replace list hyphen with dot
  (font-lock-add-keywords 'org-mode
                          '(("^ *\\([-]\\) "
                             (0 (prog1 () (compose-region (match-beginning 1) (match-end 1) "•"))))))

  ;; Set faces for heading levels
  (dolist (face '((org-level-1 . 1.2)
                  (org-level-2 . 1.1)
                  (org-level-3 . 1.05)
                  (org-level-4 . 1.0)
                  (org-level-5 . 1.1)
                  (org-level-6 . 1.1)
                  (org-level-7 . 1.1)
                  (org-level-8 . 1.1)))
 (set-face-attribute (car face) nil :font "Cantarell" :weight 'regular :height (cdr face)))

  ;; Ensure that anything that should be fixed-pitch in Org files appears that way
  (set-face-attribute 'org-block nil :foreground nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil   :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-table nil   :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-special-keyword nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-meta-line nil :inherit '(font-lock-comment-face fixed-pitch))
  (set-face-attribute 'org-checkbox nil :inherit 'fixed-pitch))

(defun md/org-mode-setup ()
    (org-indent-mode)
    (variable-pitch-mode 0) ;; TODO Fucks up line numbers, gotta change their faces specificly
    (visual-line-mode 1))

(use-package org
    :pin org
    :commands (org-capture org-agenda)
    :hook (org-mode . md/org-mode-setup)
    :config
    (setq org-ellipsis " ▾")
    (setq org-hide-emphasis-markers t)

    (setq org-agenda-start-with-log-mode t)
    (setq org-log-done 'time)
    (setq org-log-into-drawer t)

    (setq org-agenda-files
        '("~/Stuff/org-files/tasks.org"
          "~/Stuff/org-files/habits.org"
          "~/Stuff/org-files/birthdays.org"))

    (md/org-font-setup))

(defun md/org-mode-visual-fill ()
  (setq visual-fill-column-width 120
        visual-fill-column-center-text t)
  (visual-fill-column-mode 1))

(use-package visual-fill-column
  :hook (org-mode . md/org-mode-visual-fill))
;; ORG:1 ends here

;; [[file:README.org::*Enabling Table of Contents][Enabling Table of Contents:1]]
(use-package toc-org
    :commands toc-org-enable
    :init (add-hook 'org-mode-hook 'toc-org-enable))
;; Enabling Table of Contents:1 ends here

;; [[file:README.org::*Enabling Org Bullets][Enabling Org Bullets:1]]
(use-package org-bullets
    :after org
    :hook (org-mode . org-bullets-mode))
;; Enabling Org Bullets:1 ends here

;; [[file:README.org::*Disable Electric Indent][Disable Electric Indent:1]]
(electric-indent-mode -1)
;; Disable Electric Indent:1 ends here

;; [[file:README.org::*Org Tempo][Org Tempo:1]]
(require 'org-tempo)
;; Org Tempo:1 ends here

;; [[file:README.org::*WHICH Key][WHICH Key:1]]
(use-package which-key
    :init
    (which-key-mode 1)
    :diminish which-key-mode
    :config
    (setq which-key-side-window-location 'bottom
        which-key-sort-order #'which-key-key-order-alpha
        which-key-sort-uppercase-first nil
        which-key-add-column-padding 1
        which-key-max-display-columns nil
        which-key-min-display-lines 6
        which-key-side-window-slot -10
        which-key-side-window-max-height 0.25
        which-key-idle-delay 0.3
        which-key-max-description-length 25
        which-key-allow-imprecise-window-fit t
        which-key-separator " → " ))
;; WHICH Key:1 ends here
