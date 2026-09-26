;;; ui.el --- 字体 / 主题 / 界面骨架 / dashboard / 模式行提示 -*- lexical-binding: t; no-byte-compile: t; -*-
;;; Commentary:
;;  译自 doom: doom-font '("Terminess Nerd Font" 25) —— 该字体本机未装。
;;  实测注册表里是 Maple Mono NF（**没有** CN 变体）与 Cascadia Code，候选按实际存在排；
;;  找不到就整体跳过，不报错。doom-theme 'catppuccin + catppuccin-flavor 'mocha。

;;; Code:

;;;; 字体（GUI 才设；按注册表实际存在的候选择一）
(when (display-graphic-p)
  (let ((available (font-family-list)))
    (when-let* ((chosen (seq-find (lambda (f) (member f available))
                                  '("Maple Mono NF" "Cascadia Code" "Source Code Pro"
                                    "JetBrainsMono Nerd Font" "Consolas"))))
      (set-face-attribute 'default nil :family chosen :height 180 :weight 'medium)
      (let ((xfd (list (cons 'font (font-xlfd-name
                                   (font-spec :family chosen :size 18))))))
        (setq initial-frame-alist (append xfd initial-frame-alist)
              default-frame-alist (append xfd default-frame-alist))))
    (when (member "Segoe UI" available)
      (set-face-attribute 'variable-pitch nil :family "Segoe UI" :height 180))))

;;;; 去掉 GUI 噪音 + 基础光标/行号
(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(blink-cursor-mode -1)
(setq inhibit-startup-screen t
      initial-scratch-message nil
      ring-bell-function 'ignore
      use-file-dialog nil
      use-dialog-box nil
      cursor-type 'box
      next-line-add-newlines nil)
(global-display-line-numbers-mode 1)
(column-number-mode 1)
(global-hl-line-mode 1)

;;;; 主题
;; MELPA 的 catppuccin-theme 只注册一个 feature 名 `catppuccin（没有 catppuccin-mocha 主题文件），
;; 四套配色靠 catppuccin-flavor 切换；改 flavor 后要 catppuccin-reload 才生效。
;; 包提供的 feature 叫 catppuccin-theme（不是 catppuccin），写错会导致 require 失败
(use-package catppuccin-theme
  :ensure t
  :custom (catppuccin-flavor 'mocha)          ; 译自 doom: (setq doom-theme 'catppuccin)
  :config (load-theme 'catppuccin t))

;;;; 模式行提示
(use-package which-key :ensure t :custom (which-key-idle-delay 0.4)
  :config (which-key-mode 1))
;; keycast 没有 `keycast-mode，提供的是 keycast-mode-line-mode / -header-line-mode / -tab-bar-mode
(use-package keycast :ensure t :config (keycast-mode-line-mode 1))
(use-package so-long :ensure nil :config (global-so-long-mode 1))

;;;; 启动面板（译自 doom: doom-dashboard）
(use-package dashboard
  :ensure t
  :custom (dashboard-startup-banner 'logo)
  (dashboard-set-file-info t)
  :init (setq initial-buffer-choice
              (lambda () (get-buffer-create "*dashboard*")))
  :config
  (dashboard-setup-startup-hook)
  (setq dashboard-items '((recents . 10) (projects . 6) (bookmarks . 4) (registers . 3))
        dashboard-footer-messages '("pureey @ Windows · Emacs 31")))

(provide 'ui)
;;; ui.el ends here
