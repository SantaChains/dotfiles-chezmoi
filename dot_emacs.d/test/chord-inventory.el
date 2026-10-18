;;; chord-inventory.el --- normal 态"和弦债务"实测盘点 v3 -*- lexical-binding: t; -*-
;;; Commentary:
;;  历史教训（两版都被证伪，记在这里）：
;;   v1 用 map-keymap 枚举 → 漏掉全部 M- 绑定（meta 事件不在 char-table 迭代范围，
;;      已验证：map-keymap 抓不到 M-o，而 key-binding 能）。
;;   v2 在 batch 里提前 (require 'evil) 才能让 use-package :after 生效，但这违反
;;      editing.el 的"evil 前置变量必须早于 require"约束 → C-u 等绑定失真。
;;   v3 因此：**优先在真实 daemon 里跑**（evil 由 idle timer 在正确时机加载）；
;;      只有不在 daemon 里时才走 batch 兜底（近似值，输出会标注）。
;;  用法:
;;    emacs --daemon=verify-keys
;;    emacsclient -f "$HOME/.emacs.d/server/verify-keys" \
;;      --eval '(progn (load "~/.emacs.d/test/chord-inventory.el" nil t) (ci/report))'
;;; Code:

(defvar ci/batch-approx nil "本次报告是否为 batch 近似值。")

(unless (featurep 'evil)
  (setq ci/batch-approx t)
  (package-initialize)
  (setq my/evil-p t my/leader-key "," my/transparent-p nil my/auto-install-packages-p nil)
  (defconst my/windows-p (memq system-type '(windows-nt ms-dos cygwin)))
  (defun my/edit-init () "stub" (interactive))
  (require 'evil)
  (require 'general)
  (dolist (mod '("windows" "ui" "completion" "editing" "lsp" "vcs"))
    (condition-case err
        (load (expand-file-name (format "~/.emacs.d/lisp/%s.el" mod)) nil 'nomessage)
      (error (princ (format "LOAD-ERROR %s: %s\n" mod (error-message-string err)))))))

(defconst ci/bases
  (append (number-sequence ?\s ?~)
          '(tab return backspace delete escape up down left right home end prior next)))

(defconst ci/keep-keys
  '("C-g" "C-x" "C-c" "C-h" "C-SPC" "C-@" "M-x" "M-:" "C-]" "C-^" "C-\\"
    "C-/" "C-?" "C-_" "C-l" "C-o" "C-t" "C-v" "C-z" "M-." "M-," "M-?" "M-<" "M->"
    "C-d" "C-u" "C-f" "C-b" "C-e" "C-y" "C-n" "C-p" "C-r" "C-w" "C-j")
  "必须保留：安全边界、前缀、evil 原生命令。")

(defconst ci/leak-prefixes
  '("kill-" "backward-" "forward-" "upcase-" "downcase-" "capitalize-" "transpose-"
    "mark-" "fill-" "ispell-" "abbrev-" "delete-horizontal" "delete-indentation"
    "just-one-space" "cycle-spacing" "query-replace" "shell-command" "zap-to-char"
    "dabbrev" "count-words" "not-modified" "tab-to-tab" "default-indent"
    "move-to-window" "insert-parentheses" "move-past-" "beginning-of-buffer"
    "end-of-buffer" "scroll-other-window" "left-word" "right-word")
  "Emacs 行编辑命令前缀：evil 的 operator+motion 已覆盖，属冗余泄漏，可 unbind。")

(defun ci/candidates ()
  (let (out)
    (dolist (b ci/bases)
      (dolist (mods '(nil (control) (meta) (control meta)))
        (push (vector (if mods (event-convert-list (append mods (list b))) b)) out)))
    (nreverse out)))

(defun ci/report ()
  "返回和弦债务报告字符串。"
  (let ((buf (generate-new-buffer " *ci*")))
    (with-current-buffer buf
      (fundamental-mode)
      (evil-local-mode 1)
      (evil-normal-state)
      (let ((chord nil) (plain 0))
        (dolist (k (ci/candidates))
          (let ((b (key-binding k t))
                (mods (event-modifiers (aref k 0))))
            (when b
              (if (or (memq 'control mods) (memq 'meta mods))
                  (push (cons (key-description k) b) chord)
                (setq plain (1+ plain))))))
        (let ((keep nil) (leak nil) (home nil) (prefix nil))
          (dolist (b chord)
            (cond
             ((keymapp (cdr b)) (push b prefix))
             ((member (car b) ci/keep-keys) (push b keep))
             ((and (symbolp (cdr b))
                   (seq-some (lambda (p) (string-prefix-p p (symbol-name (cdr b))))
                             ci/leak-prefixes))
              (push b leak))
             (t (push b home))))
          (with-output-to-string
            (princ (format "%snormal 态生效绑定：和弦起手 %d / 单键起手 %d\n"
                           (if ci/batch-approx "[batch 近似] " "[真实 daemon] ")
                           (length chord) plain))
            (princ (format "拆分：必须保留 %d / 冗余可 unbind %d / 无等价需给新家 %d / 前缀 %d\n"
                           (length keep) (length leak) (length home) (length prefix)))
            (princ (format "新家里 digit/negative-argument %d，其余真命令 %d\n\n"
                           (length (seq-filter
                                    (lambda (b) (memq (cdr b) '(digit-argument negative-argument)))
                                    home))
                           (length (seq-remove
                                    (lambda (b) (memq (cdr b) '(digit-argument negative-argument)))
                                    home))))
            (princ "=== 冗余可 unbind（evil 已有对等能力）===\n")
            (dolist (b (sort leak (lambda (x y) (string< (car x) (car y)))))
              (princ (format "  %-10s %S\n" (car b) (cdr b))))
            (princ "\n=== 无 evil 等价，需要新家（进 SPC 层）===\n")
            (dolist (b (sort home (lambda (x y) (string< (car x) (car y)))))
              (princ (format "  %-10s %S\n" (car b) (cdr b))))
            (princ "\n=== 前缀（需人工决定留哪些）===\n")
            (dolist (b (sort prefix (lambda (x y) (string< (car x) (car y)))))
              (princ (format "  %-10s %s\n" (car b) (if (symbolp (cdr b)) (cdr b) "keymap"))))))))))

;;; chord-inventory.el ends here
