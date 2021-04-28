;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "petr-tik"
      user-mail-address "")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
(setq doom-font (font-spec :family "monospace" :size 16 :weight 'semi-light)
      doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
;;
;;
(setq doom-localleader-key ",")

(load! "+global_maps.el")

(use-package! org
  :config
  (setq org-directory "~/org"
        org-agenda-files (directory-files org-directory t ".+\.org")
        org-refile-targets '((nil :maxlevel . 9)
                             (org-agenda-files :maxlevel . 9))
        org-refile-use-outline-path 'file
        org-refile-allow-creating-parent-nodes 'confirm))

(after! rustic
  (setq rustic-lsp-server 'rust-analyzer
        rustic-format-on-save t))

(use-package lsp-mode
  :config
  (setq lsp-enable-folding t)
  (setq lsp-clients-clangd-args '("--clang-tidy" "-j=12" "--log=verbose" "--pch-storage=memory" "--query-driver=/usr/bin/c++"))
  (setq lsp-idle-delay 0.2)
  ;; defaults to 128 - this puppy has enough RAM
  ;; https://rust-analyzer.github.io/manual.html
  (setq lsp-rust-analyzer-lru-capacity 1024)

  (lsp-register-client
   (make-lsp-client :new-connection (lsp-tramp-connection "pyls")
                    :major-modes '(python-mode)
                    :remote? t
                    :server-id 'pyls-remote))

  (map! :map (rustic-mode-map c++-mode-map python-mode-map)
        :localleader
        :nv "=" #'lsp-format-buffer)
  ;; TODO expose the lsp-command-map under SPC l
  (map! :leader "l" lsp-command-map)
) ; lsp-mode


(use-package project
  :config
  (add-to-list 'project-switch-commands '(?z "fzf" counsel-fzf))
  (add-to-list 'project-switch-commands '(?m "Magit" magit-status))

  (map! :leader
        :desc "eshell in project root"
        "p e"
        #'project-eshell)
)

(add-hook 'eshell-preoutput-filter-functions 'ansi-color-apply)

(after! evil
  (evil-set-initial-state 'comint-mode 'normal))

(after! magit
  (defun pt/magit-display-buffer-same-window-but-diff-log-proc (buffer)
    "Display BUFFER in the selected window except for some modes.
If a buffer's `major-mode' derives from `magit-diff-mode' or
`magit-process-mode', display it in another window.  Display all
other buffers in the selected window."
    (display-buffer
     buffer (if (with-current-buffer buffer
                  (derived-mode-p 'magit-diff-mode 'magit-process-mode 'magit-log-mode))
                '(nil (inhibit-same-window . t))
              '(display-buffer-same-window))))

  (setq magit-bury-buffer-function #'magit-mode-quit-window
        git-commit-major-mode 'org-mode
        magit-display-buffer-function 'pt/magit-display-buffer-same-window-but-diff-log-proc))


(use-package! tramp
  :config
  (add-to-list 'tramp-remote-path "~/.local/bin/")
  (add-to-list 'tramp-connection-properties
               (list (regexp-quote "/ssh:petr_tik@192.*:")
                     "remote-shell" "/bin/bash")))
