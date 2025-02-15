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
(setq doom-font (font-spec :family "Noto Sans Mono" :size 20)
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

(defun available-ram-in-gb ()
  "Return the total available RAM in GB, using appropriate methods based on the OS."
  (cond
   ((eq system-type 'darwin) ; macOS
    (let* ((hardware-info (shell-command-to-string "sysctl hw.memsize"))
           (ram-in-bytes (string-to-number (car (last (split-string hardware-info ":"))))))
      (/ ram-in-bytes (* 1024 1024 1024))))
   ((eq system-type 'gnu/linux) ; Linux
    (/ (car (memory-info)) (* 1024 1024)))
   (t
    (error "Unsupported operating system")))) 

(defun pt/adjust-for-host-ram (initial-value)
  "Return the initial value adjusted for the RAM available on the emacs host"
  ;; sadly not TRAMP-friendly because memory-info runs on the emacs host
  (let* ((ram-in-gb (available-ram-in-gb))
         (smallest-ram-available 8.0)
         (factor (log ram-in-gb smallest-ram-available)))
    (floor (* factor initial-value))))

(defun pt/kill-from-shell (&optional input)
  (interactive "sYank command: ")
  (if-let (non-empty-return (string-trim-right (shell-command-to-string input)))
      (kill-new non-empty-return)
    (message "Shell command %s returned nothing" input)))


(use-package! org
  :config
  (setq org-directory "~/org"
        org-agenda-files (directory-files org-directory t ".+\.org")
        org-refile-targets '((nil :maxlevel . 9)
                             (org-agenda-files :maxlevel . 9))
        org-refile-use-outline-path 'file
        org-refile-allow-creating-parent-nodes 'confirm))

(after! (rustic lsp-mode)
  (setq rustic-lsp-server 'rust-analyzer
        rustic-format-on-save t)

  ;; https://rust-analyzer.github.io/manual.html#configuration
  ;; defaults to 128 - let's adjust that for available RAM
  (setq lsp-rust-analyzer-lru-capacity `(,@(pt/adjust-for-host-ram 128))))

(use-package lsp-mode
  :config
  (setq lsp-enable-folding t)
  (setq lsp-clients-clangd-args '("--clang-tidy" "-j=12" "--log=verbose" "--pch-storage=memory" "--query-driver=/usr/bin/c++"))
  (setq lsp-idle-delay 0.2)
  (setq lsp-pylsp-plugins-flake8-max-line-length 100)


  (lsp-register-client
   (make-lsp-client :new-connection (lsp-tramp-connection "pyls")
                    :major-modes '(python-mode)
                    :remote? t
                    :server-id 'pyls-remote))

  (map! :map (rustic-mode-map c++-mode-map python-mode-map)
        :localleader
        :nv "=" #'lsp-format-buffer)
  ;; FIXME give prefixes descriptive/category names - currently they are all marked as "g prefix" et al
  (map! :leader "l" lsp-mode-map)
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

(use-package projectile
  :config
  (map! :leader
        :desc "Switch to buffer other window"
        "b o"
        #'projectile-switch-to-buffer-other-window)
)

(use-package ivy
  :config
  (setq ivy-height 20)

  (defun pt/project-search-at-point-or-blank ()
    "Be clever - search symbol at point if it exists or start a blank search"
    (interactive)
    (if-let (sym (doom-thing-at-point-or-region))
        (+default/search-project-for-symbol-at-point sym default-directory))
    (+default/search-project))

  (map! :leader
        :desc "Search in project"
        "/"
        #'pt/project-search-at-point-or-blank)
)

(use-package counsel
  :config
  ;; find all files, sort most recently modified first and cut to only show filenames
  (setq counsel-fzf-cmd (concat doom-projectile-fd-binary " . --type f --exec stat --printf='%%y %%n\\n' | sort -nr | cut -d' ' -f4 | fzf -f \"%s\""))

  (map! :leader
        :desc "Fuzzy search in project"
        "SPC"
        #'counsel-fzf)
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
        magit-display-buffer-function 'pt/magit-display-buffer-same-window-but-diff-log-proc)
  (setq! magit-list-refs-sortby '("-committerdate" "-creatordate")))


(use-package! tramp
  :config
  (add-to-list 'tramp-remote-path "~/.local/bin/")
  (add-to-list 'tramp-connection-properties
               (list (regexp-quote "/ssh:petr_tik@192.*:")
                     "remote-shell" "/bin/bash")))

(use-package! bazel
 :custom
 (bazel-command '("bazelisk"))
)

(use-package! dap-mode
  :init
  (require 'dap-python)
  (setq dap-python-debugger 'debugpy)
  (setq dap-python-executable "python3.8")
  (setq dap-ui-locals-expand-depth t)
  (setq dap-auto-configure-features '(locals breakpoints controls repl)))


(use-package! gptel
  :config
  (setq
   gptel-model "llama3.1:latest"
   gptel-backend (gptel-make-ollama "Ollama"
                                    :host "localhost:11434"
                                    :models '(llama3.1:latest llama3.2:latest llama3.2:1b))))
