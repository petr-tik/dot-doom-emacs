;;; +global_maps.el -*- lexical-binding: t; -*-

;; TODO Leave this here, move the rest to respective use-package sexps
(map! :leader
      :desc "Find file other window"
      "f o"
      #'find-file-other-window)
