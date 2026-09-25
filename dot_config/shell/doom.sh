# ─────────────────────────────────────────────────────────────
#  Doom Emacs 便捷命令（bash / zsh 共用）
#  由 ~/.bashrc 与 ~/.zshrc source
# ─────────────────────────────────────────────────────────────

# doom CLI（~/.config/emacs/bin/doom）加入 PATH，仅当尚未存在时
case ":$PATH:" in
  *":$HOME/.config/emacs/bin:"*) ;;
  *) export PATH="$HOME/.config/emacs/bin:$PATH" ;;
esac

# dm [文件...]       启动 Doom Emacs（默认图形界面）
# dm -t [文件...]    在终端内启动（emacs -nw）
# dm -t -q           等价于 emacs -nw -q，忽略配置直接启动
dm() {
  if [ "$1" = "-t" ] || [ "$1" = "--tty" ] || [ "$1" = "--nw" ]; then
    shift
    command emacs -nw "$@"
  else
    command emacs "$@"
  fi
}
