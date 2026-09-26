;;; early-init.el --- Emacs 启动早期设置（本文件先于 init.el、且在 UI 初始化前加载） -*- lexical-binding: t; no-byte-compile: t; -*-
;;; Commentary:
;;
;; Emacs 27+ 会在 init.el 之前加载本文件。放这里的三件事**必须**早：
;;   1. GC 阈值 —— 要在任何包加载**之前**调高，否则启动中途触发 GC 白白拖慢；
;;   2. 包后端 —— MELPA/Nongnu/GNU 索引与 package-initialize；
;;   3. Windows w32 性能开关 —— 影响首批文件属性扫描。
;; 分文件管理的整体编排见 init.el；各主题模块在 lisp/ 下。

;;; Code:

;;;; GC / 子进程吞吐（启动期放大，after-init 后回落）
(setq gc-cons-threshold (* 128 1024 1024)
      read-process-output-max (* 1024 1024))   ; LSP/子进程吞吐
(add-hook 'after-init-hook
          (lambda () (setq gc-cons-threshold (* 8 1024 1024))))

;;;; 包后端配置
;; 注意：这里只做「配置」，不调 package-initialize / package-activate-all。
;; Emacs 启动流程会自动在 init.el 之前激活已装包（batch 模式会跳过）。
;; 激活逻辑统一放到 init.el 开头，这样 batch 模式也能工作。
(require 'package)
;; Windows 上 MSYS 默认目录会污染 GPG 路径，显式用 locate-user-emacs-file 绝对化
(setq package-gnupghome-dir (locate-user-emacs-file "elpa/gnupg" "gnupg"))
(make-directory package-gnupghome-dir t)
;; Emacs 31 把 package-check-signature 做成了「可绑定的 defalias」，
;; setq 完全有效（实测 archive-contents 刷新无签名错误）。
;; HTTPS 已提供完整性保证，关掉签名检查更稳定。
(setq package-check-signature nil)
(setq package-archives
      '(("melpa"  . "https://melpa.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("gnu"    . "https://elpa.gnu.org/packages/"))
      package-menu-async t
      ;; Custom 面板写出去的东西另存，不污染配置本体
      custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file) (load custom-file))

;;;; Windows 文件系统性能（真正的 Windows 卡顿源头之一）
(when (memq system-type '(windows-nt ms-dos cygwin))
  ;; w32-get-true-file-attributes 对每个文件多查一次安全描述符
  (when (boundp 'w32-get-true-file-attributes) (setq w32-get-true-file-attributes nil))
  (when (boundp 'w32-pipe-read-delay)         (setq w32-pipe-read-delay 0)))

(provide 'early-init)
;;; early-init.el ends here
