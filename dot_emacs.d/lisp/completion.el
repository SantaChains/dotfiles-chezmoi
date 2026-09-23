;;; completion.el --- 补全 / 搜索 / 片段（vertico 系 + corfu 系）-*- lexical-binding: t; no-byte-compile: t; -*-
;;; Commentary:
;;  译自 doom: :completion vertico（popup 模块由 vertico+corfu 取代）；
;;  company+snippets → corfu+cape+tempel（无需外部 formatter/模板仓库，Windows 零依赖）。

;;; Code:

;;;; Minibuffer 补全（vertico 系）
(use-package vertico
  :ensure t
  :custom (vertico-cycle t) (vertico-count 15)
  :init (vertico-mode 1))

(use-package orderless
  :ensure t
  :custom (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia :ensure t :config (marginalia-mode 1))

(use-package consult
  :ensure t
  :bind (("C-x b" . consult-buffer)
         ("M-y" . consult-yank-pop)
         ("M-g g" . consult-goto-line)
         ("C-c i" . consult-imenu)
         ([remap switch-to-buffer] . consult-buffer)
         ([remap bookmark-jump] . consult-bookmark)
         ([remap apropos] . consult-apropos))
  :config
  ;; rg 不在 PATH 时 consult-ripgrep 直接报错 → 探测后才绑键
  (when (executable-find "rg") (global-set-key (kbd "C-c s r") #'consult-ripgrep))
  (global-set-key (kbd "C-c s g") #'consult-grep))

;;;; 行内补全（corfu 系，替代 company）
(use-package corfu
  :ensure t
  :custom (corfu-cycle t) (corfu-auto t) (corfu-auto-delay 0.15)
  (corfu-preview-current nil) (corfu-quit-at-boundary 'separator)
  :config (global-corfu-mode 1) (corfu-echo-mode 1))

(use-package cape :ensure t
  :custom (completion-cycle-threshold 3)
  :config
  (dolist (c '(cape-line cape-elisp-block cape-elisp-library-symbols cape-dabbrev
              cape-file cape-keyword cape-symbol))
    (when (fboundp c) (add-to-list 'completion-at-point-functions c))))

;;;; 片段（tempel，替代 yasnippet + doom snippets）
(use-package tempel :ensure t :after cape
  :bind (("M-+" . tempel-complete) ("M-*" . tempel-insert))
  :init
  (defun my/tempel-hook () (add-to-list 'completion-at-point-functions #'tempel-complete))
  (add-hook 'prog-mode-hook #'my/tempel-hook)
  (add-hook 'text-mode-hook #'my/tempel-hook)
  :config
  (setq tempel-path (expand-file-name "templates/.templates" user-emacs-directory))
  (make-directory tempel-path t))

(provide 'completion)
;;; completion.el ends here
