;;; +global_maps.el -*- lexical-binding: t; -*-

;; TODO Leave this here, move the rest to respective use-package sexps
(map! :leader
      :desc "Find file other window"
      "f o"
      #'find-file-other-window)

(map! :leader
      :desc "Switch to buffer other window"
      "b o"
      #'projectile-switch-to-buffer-other-window)

;; TODO - try to make it search symbol-at-point by default
(map! :leader
      :desc "Search in project"
      "/"
      #'+ivy/project-search)

(map! :leader
      :desc "Fuzzy search in project"
      "SPC"
      #'counsel-fzf)
