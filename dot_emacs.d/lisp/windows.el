;;; windows.el --- Windows 适配（性能位已在 early-init.el）-*- lexical-binding: t; no-byte-compile: t; -*-
;;; Commentary:
;;  译自 doom: xclip/pbcopy（X11/macOS，本机无 X server → 换原生剪贴板）、
;;  fish 路径（NixOS → 换 pwsh）。exec-path 补全是 Windows GUI 启动 Emacs 的必修：
;;  GUI 进程未必继承 scoop/cargo/go 的用户级 PATH，探测不到 gopls/rg 就源于此。

;;; Code:

(when my/windows-p
  ;; 补 exec-path（§lsp 的 executable-find 挂载依赖这些）
  (dolist (dir (append
                (list "D:/Soft/SCOOP/shims" "D:/Soft/SCOOP/apps"
                      "D:/langcode/GOSDK/bin" "D:/langcode/gcc/mingw64/bin"
                      (expand-file-name "npm-global" "D:"))
                (when-let* ((home (or (getenv "CARGO_HOME")
                                      (expand-file-name ".cargo" (or (getenv "USERPROFILE") "~")))))
                  (list (expand-file-name "bin" home)))
                (when-let* ((gp (getenv "GOPATH")))
                  (list (expand-file-name "bin" gp)))))
    (when (and dir (file-directory-p dir))
      (add-to-list 'exec-path dir)))

  ;; 剪贴板。译自 doom: xclip/pbcopy 段 —— Windows 原生只需下面三行。
  (setq select-enable-clipboard t
        select-enable-primary nil
        save-interprogram-paste-before-kill t)

  ;; shell。译自 doom: (setq explicit-shell-file-name ".../fish") —— NixOS 路径，
  ;; 本机换成 pwsh 7（实测在 PATH）。
  (when-let* ((pwsh (or (executable-find "pwsh") (executable-find "powershell"))))
    (setq explicit-shell-file-name pwsh
          shell-file-name pwsh
          shell-command-switch "-NoProfile -Command"))

  ;; 删除走回收站（Windows 独有的安全网）
  (setq delete-by-moving-to-trash t)

  ;; 文件系统大小写不敏感 → 补全也必须忽略大小写
  (setq read-file-name-completion-ignore-case t
        read-buffer-completion-ignore-case t
        completion-ignore-case t)

  ;; GUI 启动即最大化；标题栏带项目根（project-current 返回 (TYPE . ROOT)，取 cdr）
  (add-hook 'after-init-hook
            (lambda () (when (display-graphic-p) (toggle-frame-maximized))))
  (setq frame-title-format
        '("Emacs " (:eval emacs-version) "  "
          (:eval (or (ignore-errors (cdr (project-current))) "no-project"))))
  ;; 透明度（my/transparent-p 为 t 才写）
  (when my/transparent-p
    (add-to-list 'default-frame-alist '(alpha . (92 92)))))

;;;; 编码（内部强制 UTF-8；中文输入 C-\）——跨平台都放这
(set-language-environment 'UTF-8)
(prefer-coding-system 'utf-8-unix)
(set-default-coding-systems 'utf-8-unix)
(setq selection-coding-system 'utf-8
      default-input-method "windows")

(provide 'windows)
;;; windows.el ends here
