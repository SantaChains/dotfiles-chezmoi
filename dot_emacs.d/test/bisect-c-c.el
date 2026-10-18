;;; bisect-c-c.el --- 定位 C-c s r 从哪一步开始不可达 -*- lexical-binding: t; -*-
;;; Commentary:
;;  按 init.el 的真实模块顺序逐个加载，每一步后打印 C-c 前缀与 C-c s r 的绑定。
;;  用法: emacs -Q --batch -l ~/.emacs.d/test/bisect-c-c.el
;;; Code:

(package-initialize)
(setq my/evil-p t my/leader-key "," my/transparent-p nil my/auto-install-packages-p nil)
(defconst my/windows-p (memq system-type '(windows-nt ms-dos cygwin)))
(defun my/edit-init () "stub" (interactive))
;; 让 use-package 的 :after evil 立即成立（真实启动时 evil 由 idle timer 加载）
(require 'evil)
(require 'general)

(defun bc/probe (label)
  (princ (format "%-11s C-c=%-10S C-c-s-r=%-24S C-c-s=%-6S [t]=%S\n"
                 label
                 (let ((m (lookup-key global-map (kbd "C-c"))))
                   (if (keymapp m) "keymap" m))
                 (lookup-key global-map (kbd "C-c s r"))
                 (lookup-key global-map (kbd "C-c s"))
                 (let ((m (lookup-key global-map (kbd "C-c"))))
                   (and (keymapp m) (lookup-key m [t]))))))

(bc/probe "pre")
(dolist (mod '("windows" "ui" "completion" "editing" "lsp" "vcs" "apps"))
  (condition-case err
      (load (expand-file-name (format "~/.emacs.d/lisp/%s.el" mod)) nil 'nomessage)
    (error (princ (format "%-11s LOAD-ERROR %s\n" mod (error-message-string err)))))
  (bc/probe mod))
;;; bisect-c-c.el ends here
