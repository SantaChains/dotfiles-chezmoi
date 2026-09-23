;;; init.el --- Emacs 配置 (chezmoi 管理 / Windows · Emacs 31) -*- lexical-binding: t; no-byte-compile: t; -*-

;; 实测:本机 Emacs 31.1 的 user-emacs-directory = ~/.emacs.d/,
;; 因为 ~/.emacs.d 已存在会优先于 XDG(~/.config/emacs)。
;; 所以本文件源路径是 dot_emacs.d/init.el → ~/.emacs.d/init.el(而非 dot_config/emacs)。

;;; 启动性能 -------------------------------------------------------------
(setq gc-cons-threshold (* 64 1024 1024))
(add-hook 'after-init-hook
          (lambda () (setq gc-cons-threshold (* 8 1024 1024))))

;;; 身份 -----------------------------------------------------------------
(setq user-full-name "pureey"
      user-mail-address "148528901+SantaChains@users.noreply.github.com")

;;; 基础界面 -------------------------------------------------------------
(when (fboundp 'menu-bar-mode)    (menu-bar-mode -1))
(when (fboundp 'tool-bar-mode)    (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode)  (scroll-bar-mode -1))
(blink-cursor-mode -1)
(setq inhibit-startup-screen t
      initial-scratch-message nil
      ring-bell-function 'ignore
      use-file-dialog nil
      use-dialog-box nil
      x-stretch-lines-after-point nil)

(global-display-line-numbers-mode 1)   ;; 行号
(column-number-mode 1)                 ;; 列号
(global-hl-line-mode 1)                ;; 当前行高亮

;;; 编码(Windows 关键:强制 UTF-8)--------------------------------------
(set-language-environment 'UTF-8)
(prefer-coding-system 'utf-8-unix)
(set-default-coding-systems 'utf-8-unix)
(setq selection-coding-system 'utf-8)
;; 中文输入:需要时 C-\ 切换
(setq default-input-method "windows")

;;; 备份 / autosave 集中到 var,避免污染工作目录 --------------------------
(let ((var (locate-user-emacs-file "var/")))
  (setq backup-directory-alist `(("." . ,var))
        auto-save-file-name-transforms `((".*" ,var t))
        auto-save-list-file-prefix var)
  (make-directory var t))

;;; 常用行为 -------------------------------------------------------------
(setq version-control t
      delete-old-versions -1
      confirm-nonexistent-file-or-buffer nil
      kill-ring-max 200
      save-place-for-located-files t
      compilation-always-kill t
      tab-width 4
      indent-tabs-mode nil)
(recentf-mode 1)
(savehist-mode 1)
(save-place-mode 1)
(winner-mode 1)          ; 窗口布局 undo/redo: C-c <left>/<right>
(show-paren-mode 1)
(electric-pair-mode 1)
(pixel-scroll-precision-mode 1)   ; Emacs 28+ 平滑滚动

;;; 包管理(不自动联网 refresh,按需 M-x list-packages)-------------------
(require 'package)
(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/"))
      package-menu-async t)
;; 国内网络可改用清华镜像(取消注释替换上面 package-archives):
;; (setq package-archives
;;       '(("gnu"   . "https://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
;;         ("melpa" . "https://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/")))
(package-initialize)

;;; 字体(缺失自动回退,不报错)------------------------------------------
(let* ((available (font-family-list))
       (chosen (car (seq-remove (lambda (f) (not (member f available)))
                                '("Maple Mono NF CN" "JetBrainsMono Nerd Font" "Consolas")))))
  (when chosen
    (set-face-attribute 'default nil :family chosen :height 110)))

;;; 快捷键微调 -----------------------------------------------------------
(global-set-key (kbd "M-o") 'other-window)
(global-set-key (kbd "C-c k") 'kill-this-buffer)

(provide 'init)
;;; init.el ends here
