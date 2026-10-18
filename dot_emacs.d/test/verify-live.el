;;; verify-live.el --- 在真实运行中的 Emacs（含完整 init.el）里核对键位 -*- lexical-binding: t; -*-
;;; Commentary:
;;  用法（起临时 daemon → 验 → 立刻杀掉，不碰交互会话）：
;;    emacs --daemon=verify-keys
;;    emacsclient -f "~/.emacs.d/server/verify-keys" --eval '(load "~/.emacs.d/test/verify-live.el")'
;;    emacsclient -f "~/.emacs.d/server/verify-keys" --eval '(kill-emacs)'
;;  检查两点：
;;    A. lisp/editing.el 的 my/leader 表里哪些键真的绑上了命令（KEYS-ERGONOMICS.md §1.1）
;;    B. §1.2 列的"现有真实键位"是否真存在
;;  返回值是报告字符串（princ 进 daemon 的 stdout，客户端看不到）。
;;; Code:

(defun vk/probe (key)
  "在 evil normal 状态上下文里返回 KEY 的绑定。"
  (with-temp-buffer
    (fundamental-mode)
    (evil-local-mode 1)
    (evil-normal-state)
    (key-binding (kbd key) t)))

(defun vk/report ()
  (with-output-to-string
    (let ((leader-keys '("SPC b b" "SPC b d" "SPC e e" "SPC e r" "SPC e f" "SPC g g"
                         "SPC l l" "SPC l r" "SPC l n" "SPC s s" "SPC s l" "SPC d d"
                         "SPC u z" "SPC q q"))
          (scattered '("M-o" "C-c k" "C-c i" "C-c s r" "C-c s g" "C-x b" "C-x p f"
                       "C-x g" "M-g g" "M-y" "M-+" "M-*" "C-<prior>" "C-x C-r")))
      (princ (format "evil=%s general=%s override-mode=%s\n"
                     (featurep 'evil) (featurep 'general)
                     (bound-and-true-p general-override-mode)))
      (princ "=== A. my/leader 表（期望：每行都有命令） ===\n")
      (let ((bound 0))
        (dolist (k leader-keys)
          (let ((b (vk/probe k)))
            (when b (setq bound (1+ bound)))
            (princ (format "  %-10s => %S\n" k b))))
        (princ (format "  --> 有绑定的键: %d / %d\n" bound (length leader-keys))))
      (princ "=== B. §1.2 声称的现有散键（期望：每行都有命令） ===\n")
      (let ((missing 0))
        (dolist (k scattered)
          (let ((b (vk/probe k)))
            (unless b (setq missing (1+ missing)))
            (princ (format "  %-10s => %S\n" k b))))
        (princ (format "  --> 未绑定: %d / %d\n" missing (length scattered)))))))

;; 末尾不自动跑：batch 下 evil 未加载会报错。用 (progn (load ...) (vk/report)) 显式调用。
;;; verify-live.el ends here
