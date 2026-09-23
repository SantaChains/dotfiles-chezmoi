;;; init.el --- Emacs 配置 (chezmoi 管理 / Windows · Emacs 31) -*- lexical-binding: t; no-byte-compile: t; -*-

;;; Commentary:
;;
;; 本文件已融合 ~/.emacs.d/doom/（TJ DeVries 的 Doom 配置）的**意图**。
;;
;; 为什么不是照搬：Doom 框架本体在这台机器上没装（无 ~/.emacs.d/.local、
;; ~/.config/emacs、~/.config/doom），所以 doom/init.el 的 (doom! ...) 模块
;; 开关、doom/config.el 的 `after!'、doom/packages.el 的 `package!' 一行都不会
;; 生效。这里按功能逐条翻译成 plain Emacs，每段标「译自 doom: xxx」可回溯。
;;
;; 顶层开关在 §0；Windows 适配集中在 §2；所有可选能力都先探测
;; （featurep / fboundp / executable-find / treesit-language-available-p），
;; 缺依赖只降级不中断启动。

;;; Code:

;;;; §0 顶层开关 ────────────────────────────────────────────────────────
(defvar my/evil-p t
  "非 nil 启用 evil（vim 键位）。想要纯 Emacs 键位改成 nil。")
(defvar my/leader-key ","
  "leader 键（配 SPC 双前缀，同 Doom 手感）。")
(defvar my/auto-install-packages-p t
  "首次交互式启动时自动安装缺失包；--batch 下永远跳过。")
(defvar my/transparent-p nil
  "帧透明度。Windows 支持，但远程桌面/部分显卡会花屏，故默认关。")

;;;; §1 启动性能与身份 ---------------------------------------------------
(setq gc-cons-threshold (* 128 1024 1024)
      read-process-output-max (* 1024 1024))   ; LSP/子进程吞吐
(add-hook 'after-init-hook
          (lambda () (setq gc-cons-threshold (* 8 1024 1024))))

(setq user-full-name "pureey"
      user-mail-address "148528901+SantaChains@users.noreply.github.com")

;;;; §2 Windows 适配（本机实测 Emacs 31.1，scoop shim：D:\Soft\SCOOP\shims）
(defconst my/windows-p (memq system-type '(windows-nt ms-dos cygwin)))

(when my/windows-p
  ;; 2.1 补 exec-path。GUI 启动的 Emacs 未必继承到 scoop/cargo/go 的用户级 PATH，
  ;;     探测不到 gopls/rg 就是这里的问题（§9 的 eglot 挂载也依赖这些）。
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

  ;; 2.2 NTFS 性能：Windows 上 Emacs 卡顿的两个经典原因
  ;;     w32-get-true-file-attributes 对每个文件多查一次安全描述符
  (when (boundp 'w32-get-true-file-attributes) (setq w32-get-true-file-attributes nil))
  (when (boundp 'w32-pipe-read-delay)         (setq w32-pipe-read-delay 0))

  ;; 2.3 剪贴板。译自 doom: xclip/pbcopy 段 —— 那两个是 X11/macOS 的，
  ;;     本机无 X server；Windows 原生剪贴板只需下面三行。
  (setq select-enable-clipboard t
        select-enable-primary nil
        save-interprogram-paste-before-kill t)

  ;; 2.4 shell。译自 doom: (setq explicit-shell-file-name "/run/current-system/sw/bin/fish")
  ;;     —— 那是 NixOS 路径，本机换成 pwsh 7（实测在 PATH）。
  (when-let* ((pwsh (or (executable-find "pwsh") (executable-find "powershell"))))
    (setq explicit-shell-file-name pwsh
          shell-file-name pwsh
          shell-command-switch "-NoProfile -Command"))

  ;; 2.5 删除走回收站（Windows 独有的安全网）
  (setq delete-by-moving-to-trash t)

  ;; 2.6 文件系统大小写不敏感 → 补全也必须忽略大小写
  (setq read-file-name-completion-ignore-case t
        read-buffer-completion-ignore-case t
        completion-ignore-case t)

  ;; 2.7 GUI 启动即最大化；标题栏带项目根
  (add-hook 'after-init-hook
            (lambda () (when (display-graphic-p) (toggle-frame-maximized))))
  (setq frame-title-format
        '("Emacs " (:eval emacs-version) "  "
          (:eval (or (ignore-errors (cdr (project-current))) "no-project"))))
  ;; 透明度（my/transparent-p 为 t 才写）
  (when my/transparent-p
    (add-to-list 'default-frame-alist '(alpha . (92 92)))))

;;;; §3 编码（内部强制 UTF-8；中文输入 C-\）────────────────────────────
(set-language-environment 'UTF-8)
(prefer-coding-system 'utf-8-unix)
(set-default-coding-systems 'utf-8-unix)
(setq selection-coding-system 'utf-8
      default-input-method "windows")

;;;; §4 包管理 + 缺包自动安装 -------------------------------------------
(require 'package)
(setq package-archives
      '(("melpa"  . "https://melpa.org/packages/")
        ("nongnu" . "https://elpa.nongnu.org/nongnu/")
        ("gnu"    . "https://elpa.gnu.org/packages/"))
      package-menu-async t
      ;; Custom 面板写出去的东西另存，不污染本文件
      ;; （doom/custom.el 里那坨 org-agenda-files/package-selected-packages 就是这么来的）
      custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file) (load custom-file))
(package-initialize)

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
           (message "[init.el] 刷新索引失败(%s)。可改用国内镜像：见 §4 package-archives"
                    (error-message-string err))))))))
(add-hook 'after-init-hook #'my/ensure-packages)

;;;; §5 界面 / 字体 / 主题 ----------------------------------------------
;; 译自 doom: doom-font '("Terminess Nerd Font" 25) —— 该字体本机未装。
;; 实测注册表里是 Maple Mono NF（**没有** CN 变体）与 Cascadia Code，
;; 所以候选顺序按实际存在的排；找不到就整体跳过，不报错。
(when (display-graphic-p)
  (let ((available (font-family-list)))
    (when-let* ((chosen (seq-find (lambda (f) (member f available))
                                  '("Maple Mono NF" "Cascadia Code" "Source Code Pro"
                                    "JetBrainsMono Nerd Font" "Consolas"))))
      (set-face-attribute 'default nil :family chosen :height 115 :weight 'medium)
      (let ((xfd (list (cons 'font (font-xlfd-name
                                   (font-spec :family chosen :size 13))))))
        (setq initial-frame-alist (append xfd initial-frame-alist)
              default-frame-alist (append xfd default-frame-alist))))
    (when (member "Segoe UI" available)
      (set-face-attribute 'variable-pitch nil :family "Segoe UI" :height 115))))

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

;; MELPA 的 catppuccin-theme 只注册一个 feature 名 `catppuccin（没有 catppuccin-mocha 主题文件），
;; 四套配色靠 catppuccin-flavor 切换；改 flavor 后要 catppuccin-reload 才生效。
;; 包提供的 feature 叫 catppuccin-theme（不是 catppuccin），写错会导致 require 失败
(use-package catppuccin-theme
  :ensure t
  :custom (catppuccin-flavor 'mocha)          ; 译自 doom: (setq doom-theme 'catppuccin)
  :config (load-theme 'catppuccin t))

(use-package which-key :ensure t :custom (which-key-idle-delay 0.4)
  :config (which-key-mode 1))
;; keycast 没有 `keycast-mode，提供的是 keycast-mode-line-mode / -header-line-mode / -tab-bar-mode
(use-package keycast :ensure t :config (keycast-mode-line-mode 1))
(use-package so-long :ensure nil :config (global-so-long-mode 1))

;; 译自 doom: doom-dashboard
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

;;;; §6 备份 / 常用行为 --------------------------------------------------
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

;;;; §7 补全 / 搜索（vertico 系）───────────────────────────────────────
;; 译自 doom: :completion vertico（Doom 的 popup 模块由 vertico+corfu 取代）
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

;;;; §8 编辑体验（evil + leader + 折叠 + 跳转）─────────────────────────
;; 这些 evil 变量**必须**在 evil 加载前设，故放文件顶层，不能塞进 :custom。
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

;;;; §9 LSP / 语法 / 调试 -----------------------------------------------
;; 译自 doom: :tools lsp —— Doom 用 lsp-mode，Emacs 29+ 内置 eglot 更轻，这里用 eglot。
;; 每个语言都先探测 server 可执行文件，缺了不挂钩子（避免 "Cannot start language client"）。
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

(use-package flycheck :ensure t
  :hook (prog-mode . flycheck-mode)
  :config (setq flycheck-check-syntax-automatically '(save mode-enabled)
                flycheck-idle-change-delay 0.1))   ; 译自 doom: flycheck idle delay
;; 译自 doom: (use-package! dape) + 注释掉的 dap-dlv-go
(use-package dape
  :ensure t
  :custom (dape-buffer-window-arrangement 'right)
  :bind ("<f7>" . dape)
  :config
  (when (executable-find "dlv")
    (add-hook 'dape-hook (lambda () (ignore-errors (require 'dape-dlv))))))

;;;; §10 项目 / Git / Dired / 标签页 ------------------------------------
(use-package project :ensure nil
  :bind ("C-x p f" . project-find-file)
  :config (setq project-kill-buffers-display-buffer-list t))
(use-package magit :ensure t :bind ("C-x g" . magit-status)
  :config (setq magit-git-executable (or (executable-find "git") "git")))
(use-package diff-hl :ensure t                       ; 译自 doom: (vc-gutter +pretty)
  :config
  (global-diff-hl-mode 1)
  (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh))
(use-package dired :ensure nil
  :hook (dired-mode . dired-hide-details-mode)
  :config
  (setq dired-dwim-target t
        dired-recursive-deletes 'top
        dired-listing-switches "-alh"
        ;; Windows 没有 ls；scoop 装了 coreutils 才有，否则用 Emacs 内置回退
        insert-directory-program (or (executable-find "ls") insert-directory-program))
  (put 'dired-find-alternate-file 'disabled nil))
;; 译自 doom: workspaces —— 用内置 tab-bar，零外部依赖
(when (fboundp 'tab-bar-mode)
  (tab-bar-mode 1)
  (setq tab-bar-new-tab-choice "*dashboard*"
        tab-bar-tab-hints t
        tab-bar-show nil)
  (global-set-key (kbd "C-<prior>") #'tab-previous)
  (global-set-key (kbd "C-<next>") #'tab-next))

;;;; §11 补全源 / 片段 ---------------------------------------------------
;; 译自 doom: company + snippets（换成 corfu+cape+tempel：无需外部 formatter/模板仓库）
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
(use-package tempel :ensure t :after cape
  :bind (("M-+" . tempel-complete) ("M-*" . tempel-insert))
  :init
  (defun my/tempel-hook () (add-to-list 'completion-at-point-functions #'tempel-complete))
  (add-hook 'prog-mode-hook #'my/tempel-hook)
  (add-hook 'text-mode-hook #'my/tempel-hook)
  :config
  (setq tempel-path (expand-file-name "templates/.templates" user-emacs-directory))
  (make-directory tempel-path t))

;;;; §12 tree-sitter（有 grammar 才改用它 mode，缺了就静默跳过）────────
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

;;;; §13 Org / RSS / LLM ------------------------------------------------
;; 译自 doom: org-directory "/run/media/bashbunni/mememe/more-org/" —— Linux 挂载点，
;; 本机不存在；改指 ~/.emacs.d/org/（不硬编码用户名，主目录含空格也安全）
(setq org-directory (expand-file-name "org" user-emacs-directory))
(make-directory org-directory t)
(setq org-agenda-files (directory-files org-directory t "\\.org\\'")
      org-startup-indented t
      org-hide-emphasis-markers t
      org-enforce-todo-dependencies t
      org-log-done 'time)
(with-eval-after-load 'org
  (when (facep 'variable-pitch)
    (custom-set-faces '(org-level-1 ((t :inherit variable-pitch :height 1.2))))))
;; 译自 doom: custom.el 的 (after! elfeed (setq elfeed-search-filter "@12-month-ago"))
(use-package elfeed :ensure t :bind ("C-x w" . elfeed)
  :custom (elfeed-search-filter "@12-month-ago +unread"))
;; 译自 doom: custom.el 的 package-selected-packages 里有 gptel（Emacs 里用 LLM）
;; endpoint/key 全部走环境变量，绝不写进配置（本仓库是公开仓库）
(use-package gptel :ensure t :bind ("C-c o s" . gptel)
  :config
  (when-let* ((base (or (getenv "OPENAI_BASE_URL") (getenv "LLM_BASE_URL")))
              (key (or (getenv "OPENAI_API_KEY") (getenv "LLM_KEY"))))
    (setq gptel-backend (gptel-make-openai "local" :host base :key key)
          gptel-model (or (getenv "LLM_MODEL") "gpt-4o-mini"))))

;;;; §14 辅助函数 -------------------------------------------------------
(defun my/edit-init () "编辑本配置文件。" (interactive)
  (find-file (expand-file-name "init.el" user-emacs-directory)))

(provide 'init)
;;; init.el ends here
