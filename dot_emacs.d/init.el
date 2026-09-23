;;; init.el --- Emacs 配置总编排 (chezmoi 管理 / Windows · Emacs 31) -*- lexical-binding: t; no-byte-compile: t; -*-
;;; Commentary:
;;
;; 本配置已**分文件管理**（这是 plain Emacs 的原生能力，只是需自己搭加载器）：
;;
;;   early-init.el  —— GC/包后端/Windows 文件系统性能（Emacs 27+ 先于本文件加载）
;;   init.el        —— 你正在看的：顶层开关 + 身份 + 包清单 + 加载器（控制面板）
;;   lisp/*.el      —— 按主题拆分的功能模块，顺序加载
;;   custom.el      —— Custom 面板写出的变量（early-init 里已重定向，不污染此处）
;;
;; 之所以这样拆：参考的 Doom 配置拆 init/config/packages/custom 四件套是**框架强制
;; 的契约**，plain Emacs 并无此约束。这里保留 plain Emacs 惯例（单一入口），但把功能
;; 按主题正交分解，兼顾可读与可维护。每段标「译自 doom: xxx」可回溯到原参考。
;;
;; Doom 框架本体这台机器没装（无 ~/.emacs.d/.local、~/.config/emacs、~/.config/doom），
;; 所以 doom! / after! / use-package! / package! 一行都不会生效，全部按功能逐条翻译成
;; plain Emacs。可选能力一律先探测（featurep / fboundp / executable-find /
;; treesit-language-available-p），缺依赖只降级不中断启动。
;;
;; 加载器用 load-file-name 定位模块目录：真实启动解析为 ~/.emacs.d/lisp/，
;; 批处理校验时自动指回源码同级的 lisp/，两边都能真正加载到模块。

;;; Code:

;;;; §0 顶层开关（改这里即可，模块会读取）──────────────────────────────
(defvar my/evil-p t
  "非 nil 启用 evil（vim 键位）。想要纯 Emacs 键位改成 nil。")
(defvar my/leader-key ","
  "leader 键（配 SPC 双前缀，同 Doom 手感）。")
(defvar my/auto-install-packages-p t
  "首次交互式启动时自动安装缺失包；--batch 下永远跳过。")
(defvar my/transparent-p nil
  "帧透明度。Windows 支持，但远程桌面/部分显卡会花屏，故默认关。")
(defconst my/windows-p (memq system-type '(windows-nt ms-dos cygwin))
  "是否 Windows/Cygwin 平台。")

;;;; §1 身份 -------------------------------------------------------------
(setq user-full-name "pureey"
      user-mail-address "148528901+SantaChains@users.noreply.github.com")

;;;; §2 需要外部安装的包清单 + 缺包自动安装 ------------------------------
;; 内置包不列在这里。译自 doom 各模块 + custom.el 的选择，逐条可回溯。
(defvar my/selected-packages
  '(;; 补全/搜索（译自 doom: :completion vertico + :ui popup）
    vertico orderless marginalia consult
    corfu cape tempel
    ;; 编辑（译自 doom: (evil +everywhere) / fold / snippets / modeline / ophints）
    evil evil-collection general which-key
    ;; 界面（译自 doom: doom-dashboard / hl-todo / (vc-gutter +pretty) / indent-guides）
    catppuccin-theme dashboard hl-todo diff-hl indent-bars beacon keycast avy
    ;; 工具（译自 doom: magit / :tools lsp / dape / :app rss + custom.el 的 gptel）
    magit eglot flycheck dape elfeed gptel zoom-window
    ;; 语言（译自 doom: (go ...) (zig +lsp) markdown nix；nix 在 Windows 无用故剔除）
    go-mode zig-mode markdown-mode yaml-mode
    ;; 便利
    restart-emacs)
  "需要外部安装的包；内置包不列在这里。")

(defun my/ensure-packages ()
  "安装 `my/selected-packages' 中缺失者。批处理跳过，失败只警告。"
  (when (and my/auto-install-packages-p (not noninteractive))
    (let ((missing (seq-remove
                    (lambda (p) (or (package-installed-p p) (locate-library (symbol-name p))))
                    my/selected-packages)))
      (when missing
        (message "首次配置：%d 个包待安装（M-x *Messages* 看进度）" (length missing))
        (condition-case err
            (progn
              (package-refresh-contents)
              (dolist (p missing)
                (condition-case e (package-install p)
                  ('error (message "[init.el] 装 %s 失败: %s" p (error-message-string e)))))
              (message "包安装完成；M-x restart-emacs 重启生效"))
          ('error
           (message "[init.el] 刷新索引失败(%s)。可改用国内镜像：见 early-init.el package-archives"
                    (error-message-string err))))))))
(add-hook 'after-init-hook #'my/ensure-packages)

;;;; §3 辅助函数（供各模块的键位引用，必须先于模块定义）────────────────
(defun my/edit-init () "编辑本配置文件。" (interactive)
  (find-file (expand-file-name "init.el" user-emacs-directory)))

;;;; §4 加载主题模块（顺序有意义：windows 需早于 lsp 以便 executable-find 命中）
(defconst my/lisp-dir
  (file-name-directory (or load-file-name buffer-file-name))
  "init.el 自身所在目录；模块在其中的 lisp/ 子目录。")

(let ((dir (expand-file-name "lisp" my/lisp-dir)))
  ;; 故意不动 load-path：模块用绝对路径 load，避免与内置 feature 同名时发生劫持。
  (dolist (mod '( "windows"     ;; exec-path / 剪贴板 / shell / 编码 / 帧
                  "ui"          ;; 字体 / 主题 / 界面 / dashboard / which-key / keycast
                  "completion"  ;; vertico+orderless+marginalia+consult / corfu+cape+tempel
                  "editing"     ;; evil + leader + 折叠 + 备份/undo/savehist/electric
                  "lsp"         ;; eglot（逐语言探测）/ flycheck / dape / go / treesit
                  "vcs"         ;; project / magit / diff-hl / dired / tab-bar
                  "apps" ))     ;; org / elfeed / gptel
    (load (expand-file-name mod dir) nil 'nomessage)))

(provide 'init)
;;; init.el ends here
