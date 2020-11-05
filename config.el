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


(use-package! org
  :config
  (setq org-directory "~/org"
        org-agenda-files (directory-files org-directory nil ".+\.org")
        org-refile-targets '((nil :maxlevel . 9)
                             (org-agenda-files :maxlevel . 9))
        org-refile-use-outline-path 'file
        org-refile-allow-creating-parent-nodes 'confirm))

(after! rustic
  (setq rustic-lsp-server 'rust-analyzer
        rustic-format-on-save t))

(after! lsp-mode
  (setq lsp-enable-folding t)
  (setq lsp-clients-clangd-args '("--clang-tidy" "-j=12" "--log=verbose" "--pch-storage=memory" "--query-driver=/usr/bin/c++"))
  (lsp-register-client
   (make-lsp-client :new-connection (lsp-tramp-connection "pyls")
                    :major-modes '(python-mode)
                    :remote? t
                    :server-id 'pyls-remote))
  )

(map! :leader
      :desc "eshell in project root"
      "p e"
      #'project-eshell)

;; TODO - try to make it search symbol-at-point by default
(map! :leader
      :desc "Search in project"
      "/"
      #'+ivy/project-search)

(map! :leader
      :desc "Fuzzy search in project"
      "SPC"
      #'counsel-fzf)

(map! :after lsp-mode
      :map (rustic-mode-map c++-mode-map python-mode-map)
      :localleader
      :nv "=" #'lsp-format-buffer)

(add-hook 'eshell-preoutput-filter-functions 'ansi-color-apply)

(after! magit
  (setq magit-bury-buffer-function #'magit-mode-quit-window))


(use-package! tramp
  :config
  (add-to-list 'tramp-remote-path "~/.local/bin/")
  (add-to-list 'tramp-connection-properties
               (list (regexp-quote "/ssh:petr_tik@192.*:")
                     "remote-shell" "/bin/bash")))



(custom-set-faces!
  '(font-lock-comment-face :foreground "#C2B493" :slant italic))

(defun lsp-clangd-update-args-with-compile-commands ()
  "Unless --compile-commands-dir is already set, run a potentially interactive search for the directory that contains compile_commands.json.

  Then return either the default args or the modified args"
  (if (-first
       ;; lsp-client-clangd-args might already lists a "--compile-commands-dir=build/" and will fail if we pass another one
       ;; trust the user - if it's already set, don't mess around
       (lambda (arg) (string-prefix-p "--compile-commands-dir" arg))
       lsp-clients-clangd-args)
      ((lsp--info "compilation_commands_dir set in clangd-args")
       lsp-clients-clangd-args)
    (if-let (found-dir (lsp-clangd-find-compile-commands-dir))
        ;; TODO expensive to create a list from 1 element - how to append atom to list
        (append lsp-clients-clangd-args (list (concat "--compile-commands-dir=" found-dir)))
      lsp-clients-clangd-args)
))


(defun lsp-clangd-find-compile-commands-dir ()
  "Searches for directories that contain the compile_commands.json and returns the full directory path or nil

  If multiple compile_commands.json files are found in the project directory tree - ask the user to choose"
  ;; TODO lsp-workspace-root won't find anything at the start of the workspace
  (let ((candidate-dirs (directory-files-recursively (lsp-workspace-root) "compile_commands.json")))
    (pcase (length candidate-dirs)
          ;; TODO can I lsp--warn-user-in-message-and-log at the same time
      (`0 (lsp--warn "Cannot find compile_commands.json - intellisense might not work")
          nil)
      ;; if you find 1 only - assume it's correct and strip the dirname from the full path
      (`1 (file-name-directory (car candidate-dirs)))
      ;; if you have several - ask the user to choose with lsp--completing-read
      ;; TODO if Ctrl-G from inside this completing read still falls to default lsp-clients-clangd-args
      (_ (file-name-directory (lsp--completing-read
           "Found compile_commands.json in several directories, which one do you want to use?"
           candidate-dirs
           (lambda (candidate) candidate))))
      )
    ))
