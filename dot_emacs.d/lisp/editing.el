;;; editing.el --- evil 键位 / leader / 折叠 / 备份 / undo / 编辑行为 -*- lexical-binding: t; no-byte-compile: t; -*-
;;; Commentary:
;;  译自 doom: (evil +everywhere) / fold / (vc-gutter +pretty) / indent-guides /
;;  undo / electric。evil 的前置变量**必须**在 evil 加载前设，故放本文件顶层，
;;  不能塞进 use-package 的 :custom（:custom 在 :config 之后、加载之后才生效）。

;;; Code:

;;;; 备份 / undo / 会话持久化（这些是纯 setq，无需前置顺序约束）
(let ((var (locate-user-emacs-file "var/")))
  (setq backup-directory-alist `(("." . ,var))
        auto-save-file-name-transforms `((".*" ,var t))
        auto-save-list-file-prefix var)
  (make-directory var t))

(setq version-control t
      delete-old-versions -1
      confirm-nonexistent-file-or-buffer nil
      kill-ring-max 200
      save-place-for-located-files t
      compilation-always-kill t
      compilation-scroll-output t
      tab-width 4
      indent-tabs-mode nil
      undo-limit 800000
      undo-strong-limit 12000000
      undo-outer-limit 120000000)
(recentf-mode 1)
(setq recentf-max-saved-items 200
      recentf-exclude '("\\.tmp\\'" "\\.ercsave\\'" locate-user-emacs-file))
(savehist-mode 1)
(setq savehist-additional-variables '(kill-ring search-ring regexp-search-ring))
(save-place-mode 1)
(winner-mode 1)
(show-paren-mode 1)
(electric-pair-mode 1)
(setq electric-pair-preserve-balance t
      electric-pair-delete-adjacent-pairs t
      electric-pair-skip-self t)
(global-auto-revert-mode 1)
(when (fboundp 'pixel-scroll-precision-mode) (pixel-scroll-precision-mode 1))
(when (boundp 'undo-incremental-redo) (setq undo-incremental-redo t)) ; Emacs 31 新政
(global-set-key (kbd "M-o") #'other-window)
(global-set-key (kbd "C-c k") #'kill-this-buffer)
(global-set-key (kbd "C-x C-r") #'restart-emacs)

;;;; Evil（前置变量必须在 require evil 之前）
(setq evil-want-keyword nil
      evil-want-C-u-scroll t
      evil-respect-visual-line-mode t
      evil-search-module 'evil-search)   ; 注意：变量是 evil-search-module，同名函数是另一回事
(use-package evil :ensure t :defer 0.1
  :config
  (when my/evil-p (evil-mode 1))
  (when (fboundp 'evil-set-undo-system) (evil-set-undo-system 'undo-redo))
  (key-set evil-normal-state-map (kbd "K") #'xref-find-definitions))
(use-package evil-collection
  :ensure t :after evil :config (evil-collection-init))

;;;; Leader 键位（general，配 SPC 前缀 = Doom 手感）
(use-package general :ensure t :after evil
  :config
  (general-create-definer my/leader
    :keymaps '(normal visual motion emacs) :prefix "SPC"
    :global-prefix (if my/evil-p nil my/leader-key))
  (my/leader
    "b" '(:ignore t :which-key "buffer")
    "bb" '(:ignore consult-buffer :which-key "buffers")
    "bd" '(:ignore kill-this-buffer :which-key "kill")
    "e" '(:ignore t :which-key "edit")
    "ee" '(:ignore find-file :which-key "find file")
    "er" '(:ignore consult-recent-file :which-key "recent files")
    "ef" '(my/edit-init :which-key "edit init.el")
    "g" '(:ignore t :which-key "git")
    "gg" '(:ignore magit-status :which-key "magit")
    "l" '(:ignore t :which-key "lsp")
    "ll" '(:ignore eglot :which-key "eglot")
    "lr" '(:ignore consult-imenu :which-key "imenu")
    "ln" '(:ignore eglot-rename :which-key "rename")
    "s" '(:ignore t :which-key "search/jump")
    "ss" '(:ignore avy-goto-char-timer :which-key "avy")
    "sl" '(:ignore consult-line :which-key "line")
    "d" '(:ignore t :which-key "debug")
    "dd" '(:ignore dape :which-key "dape")
    "u" '(:ignore t :which-key "ui")
    "uz" '(:ignore zoom-window :which-key "zoom")
    "qq" '(:ignore save-buffers-kill-terminal :which-key "quit"))
  ;; 不用 evil 时也给一套 C-c 前缀的等价键
  (unless my/evil-p
    (global-set-key (kbd "C-c s s") #'avy-goto-char-timer)
    (global-set-key (kbd "C-c g g") #'magit-status)
    (global-set-key (kbd "C-c e e") #'eglot)))

;;;; 跳转 / 视觉辅助 / 折叠
(use-package avy :ensure t :custom (avy-timeout-seconds 0.3))
(use-package indent-bars :ensure t :hook (prog-mode . indent-bars-mode))
(use-package beacon :ensure t :config (beacon-mode 1))
(use-package hl-todo :ensure t :config (global-hl-todo-mode 1))

;; 译自 doom: fold（outline 比 hs-mode 更适配 ts 模式）
;; outline 是内置库：写 :pin builtin 会让 use-package 去查 package-alist 并报
;; "Failed to parse package outline"，内置库直接 require 即可。
(use-package outline
  :bind (:map outline-minor-mode-map ("C-c n" . outline-cycle))
  :hook (prog-mode . outline-minor-mode)
  :custom (outline-minor-mode-highlight nil))

(provide 'editing)
;;; editing.el ends here
