;;; apps.el --- Org / RSS / LLM -*- lexical-binding: t; no-byte-compile: t; -*-
;;; Commentary:
;;  译自 doom: org-directory "/run/media/bashbunni/mememe/more-org/" —— Linux 挂载点，
;;  本机不存在；改指 ~/.emacs.d/org/（不硬编码用户名，主目录含空格也安全）。
;;  elfeed/gptel 译自 custom.el 的 (after! elfeed ...) 与 package-selected-packages。
;;  gptel 的 endpoint/key 全部走环境变量，绝不写进配置（本仓库是公开仓库）。

;;; Code:

;;;; Org
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

;;;; RSS（译自 doom: custom.el 的 (after! elfeed (setq elfeed-search-filter "@12-month-ago"))）
(use-package elfeed :ensure t :bind ("C-x w" . elfeed)
  :custom (elfeed-search-filter "@12-month-ago +unread"))

;;;; LLM（gptel）
(use-package gptel :ensure t :bind ("C-c o s" . gptel)
  :config
  (when-let* ((base (or (getenv "OPENAI_BASE_URL") (getenv "LLM_BASE_URL")))
              (key (or (getenv "OPENAI_API_KEY") (getenv "LLM_KEY"))))
    (setq gptel-backend (gptel-make-openai "local" :host base :key key)
          gptel-model (or (getenv "LLM_MODEL") "gpt-4o-mini"))))

(provide 'apps)
;;; apps.el ends here
