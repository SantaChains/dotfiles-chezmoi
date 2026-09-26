;;; lsp.el --- eglot / flycheck / dape / tree-sitter -*- lexical-binding: t; no-byte-compile: t; -*-
;;; Commentary:
;;  译自 doom: :tools lsp —— Doom 用 lsp-mode，Emacs 29+ 内置 eglot 更轻，这里用 eglot。
;;  每个语言都先探测 server 可执行文件，缺了不挂钩子（避免 "Cannot start language client"）。
;;  go 段逐字翻译 doom/config.el 的三条 lsp-go-*（gofumpt / 全量 analyses / 保存整理 import）。

;;; Code:

;;;; eglot
(with-eval-after-load 'eglot
  (setq eglot-autoshutdown t
        eglot-send-changes-idle-time 0.2       ; 译自 doom: lsp-idle-delay 0.1
        eglot-connect-timeout 60
        eglot-events-buffer-size 0))
(dolist (pair '((go-mode . "gopls") (rust-mode . "rust-analyzer")
                (c-mode . "clangd") (c++-mode . "clangd")
                (lua-mode . "lua-language-server") (python-mode . "pyright-langserver")
                (zig-mode . "zls") (js-mode . "typescript-language-server")))
  (when (executable-find (cdr pair))
    (add-hook (car pair) #'eglot-ensure)))

;; 逐字翻译 doom/config.el 的三条 lsp-go-*（gofumpt / 全量 analyses / 保存整理 import）
(add-hook 'go-mode-hook
          (lambda ()
            (setq-local eglot-workspace-configuration
                        '(:gofumpt t
                          :completeUnimported t
                          :ui (:semanticTokens t)
                          :analyses (:fieldalignment t :nilness t :shadow t
                                     :unusedparams t :unusedwrite t :useany t
                                     :staticcheck t)))))

;; 译自 doom: (format +onsave) + lsp-go-install-save-hooks
(defun my/eglot-save-hooks ()
  "连上 LSP 后保存即格式化 + 整理 import。"
  (when (and (eq eglot--managed-mode t))
    (add-hook 'before-save-hook #'eglot-format-buffer t t)
    (when (fboundp 'eglot-organize-imports)
      (add-hook 'before-save-hook #'eglot-organize-imports t t))))
(add-hook 'eglot-managed-mode-hook
          (lambda () (when (eglot-current-server) (my/eglot-save-hooks))))

;;;; flycheck（译自 doom: :checkers syntax）
(use-package flycheck :ensure t
  :hook (prog-mode . flycheck-mode)
  :config (setq flycheck-check-syntax-automatically '(save mode-enabled)
                flycheck-idle-change-delay 0.1))   ; 译自 doom: flycheck idle delay

;;;; dape（译自 doom: (use-package! dape) + 注释掉的 dap-dlv-go）
(use-package dape
  :ensure t
  :custom (dape-buffer-window-arrangement 'right)
  :bind ("<f7>" . dape)
  :config
  (when (executable-find "dlv")
    (add-hook 'dape-hook (lambda () (ignore-errors (require 'dape-dlv))))))

;;;; tree-sitter（有 grammar 才改用它 mode，缺了就静默跳过）
(when (and (fboundp 'treesit-available-p) (treesit-available-p)
           (fboundp 'treesit-language-available-p))
  (dolist (pair '((go-mode . (go . go-ts-mode))
                  (rust-mode . (rust . rust-ts-mode))
                  (c-mode . (c . c-ts-mode))
                  (c++-mode . (cpp . c++-ts-mode))
                  (js-mode . (javascript . js-ts-mode))
                  (json-mode . (json . json-ts-mode))
                  (toml-mode . (toml . toml-ts-mode))
                  (yaml-mode . (yaml . yaml-ts-mode))
                  (bash-mode . (bash . bash-ts-mode))
                  (css-mode . (css . css-ts-mode))
                  (lua-mode . (lua . lua-ts-mode))))
    (let ((lang (car (cdr pair))) (ts (cdr (cdr pair))))
      (when (treesit-language-available-p lang)
        (add-to-list 'major-mode-remap-alist (cons (car pair) ts))))))

(provide 'lsp)
;;; lsp.el ends here
