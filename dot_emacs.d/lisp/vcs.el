;;; vcs.el --- 项目 / Git / Dired / 标签页 -*- lexical-binding: t; no-byte-compile: t; -*-
;;; Commentary:
;;  译自 doom: magit / (vc-gutter +pretty) / dired / workspaces。
;;  workspaces 用内置 tab-bar 实现，零外部依赖（Doom 那套需要 frames 持久化）。
;;  文件名故意不叫 project.el：`project` 是内置 feature，同名 + provide 会劫持 eglot/magit 的 (require 'project)。

;;; Code:

(use-package project :ensure nil
  :bind ("C-x p f" . project-find-file)
  :config (setq project-kill-buffers-display-buffer-list t))

(use-package magit :ensure t :bind ("C-x g" . magit-status)
  :config (setq magit-git-executable (or (executable-find "git") "git")))

;; 译自 doom: (vc-gutter +pretty)
(use-package diff-hl :ensure t
  :config
  (global-diff-hl-mode 1)
  (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh))

(use-package dired :ensure nil
  :hook (dired-mode . dired-hide-details-mode)
  :config
  (setq dired-dwim-target t
        dired-recursive-deletes 'top
        dired-listing-switches "-alh"
        ;; Windows 没有 ls；scoop 装了 coreutils 才有，否则用 Emacs 内置回退
        insert-directory-program (or (executable-find "ls") insert-directory-program))
  (put 'dired-find-alternate-file 'disabled nil))

;; 译自 doom: workspaces —— 用内置 tab-bar，零外部依赖
(when (fboundp 'tab-bar-mode)
  (tab-bar-mode 1)
  (setq tab-bar-new-tab-choice "*dashboard*"
        tab-bar-tab-hints t
        tab-bar-show nil)
  (global-set-key (kbd "C-<prior>") #'tab-previous)
  (global-set-key (kbd "C-<next>") #'tab-next))

(provide 'vcs)
;;; vcs.el ends here
