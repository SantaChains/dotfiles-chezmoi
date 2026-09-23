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

;;;; 包后端
(require 'package)
(setq package-archives
      '(("melpa"  . "https://melpa.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("gnu"    . "https://elpa.gnu.org/packages/"))
      package-menu-async t
      ;; Custom 面板写出去的东西另存，不污染配置本体
      ;; （doom/custom.el 里那坨 org-agenda-files/package-selected-packages 就是这么来的）
      custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file) (load custom-file))
(package-initialize)

;;;; Windows 文件系统性能（真正的 Windows 卡顿源头之一）
(when (memq system-type '(windows-nt ms-dos cygwin))
  ;; w32-get-true-file-attributes 对每个文件多查一次安全描述符
  (when (boundp 'w32-get-true-file-attributes) (setq w32-get-true-file-attributes nil))
  (when (boundp 'w32-pipe-read-delay)         (setq w32-pipe-read-delay 0))
  ;; 关闭包启动期自动装载，交给 init.el 里 use-package 按需触发
  (setq package-enable-at-startup nil))

(provide 'early-init)
;;; early-init.el ends here
