# ─────────────────────────────────────────────────────────────
#  ~/.config/fish/config.fish   (Arch Linux on WSL2)
#  详细说明见 Windows 侧 D:/Linux/ARCH-WSL2-使用手册.md
# ─────────────────────────────────────────────────────────────

# --- PATH：用户级命令目录 ---
fish_add_path -g $HOME/.local/bin            # uv tool / mojo / node(nvm 软链)
fish_add_path -g $HOME/.bun/bin              # bun
fish_add_path -g $HOME/.config/emacs/bin     # doom CLI

# --- 环境变量 ---
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx PAGER less
set -gx MANPAGER 'less -R'
set -g fish_greeting ""                      # 关掉启动问候

# --- LLVM/Clang 工具链（官方 extra 仓库：clang / llvm / lld / lldb）---
# 构建脚本（make / CMake / configure）认这些变量。想临时改回 gcc：
#   env CC=gcc CXX=g++ make ...
if type -q clang
    set -gx CC clang
    set -gx CXX clang++
end
if type -q llvm-config
    set -gx LLVM_CONFIG (command -v llvm-config)
end

# --- 缩写（abbr：输入时展开，回车前可见，比 alias 更适合交互）---
abbr -a g   git
abbr -a gs  'git status -sb'
abbr -a gd  'git diff'
abbr -a gl  'git log --oneline --graph --decorate -20'
abbr -a gp  'git push'
abbr -a gc  'git commit -m'
# ls 系列走 eza（现代 ls）：真 ls 用 command ls
abbr -a ls  'eza --icons --group-directories-first'
abbr -a ll  'eza -la --icons --git --group-directories-first'
abbr -a la  'eza -a --icons'
abbr -a lt  'eza --tree --level=2 --icons'
abbr -a k   kak
abbr -a py  python3
abbr -a cr  cargo
# Arch 包管理（记住：永远整系统升级，不要 -Sy <包>）
abbr -a pSyu  'sudo pacman -Syu'
abbr -a pSs   'pacman -Ss'
abbr -a pQ    'pacman -Q'
abbr -a pS    'sudo pacman -S'
abbr -a pRns  'sudo pacman -Rns'

# --- 关于 nvm ---
# nvm 是 bash 脚本，fish 里无法直接 source。这里让 fish 通过
# ~/.local/bin/node（指向 nvm 默认版本的软链）使用 Node。
# 换版本请在 bash 里操作，然后重建软链：
#   bash -lc 'nvm install 22 && nvm alias default 22'
#   for b in node npm npx corepack
#     ln -sf (dirname (readlink -f ~/.local/bin/node))/$b ~/.local/bin/$b
#   end
# 若想直接在 fish 里用 nvm，可安装 fisher + nvm.fish：
#   curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish \
#     | source && fisher install jorgebucaran/nvm.fish

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# --- 去掉 Windows PATH（appendWindowsPath 带进来的 73 个 /mnt/* 目录）---
# 为什么：命令找不到时，WSL 要逐个试探这些 Windows 目录（9P/interop），
# 实测每次约 650ms（20 次 = 13 秒），这就是“fish 卡”的真正原因。
# 需要调 Windows 程序时用绝对路径，例如 /mnt/c/Windows/explorer.exe
# 想保留某几个（如 VS Code 的 bin），把下面一行改成白名单写法：
#   set -gx PATH /mnt/c/Users/Jliu\ Pureey/AppData/Local/Programs/Microsoft\ VS\ Code/bin $PATH
set -gx PATH (string match -v "/mnt/*" $PATH)

# --- 清理冗余目录：去重 + 丢弃已不存在的 ---
# 例：残留的 ~/.pi/agent/bin 会让每次命令查找都多试探一次
set -l _p
for d in $PATH
    test -d $d; or continue                 # 丢弃已不存在的目录
    contains -- $d $_p; and continue        # 丢弃重复项（保留首次出现的顺序）
    set -a _p $d
end
set -gx PATH $_p

# ─────────────────────────────────────────────────────────────
#  新增工具集成（守卫写法：没装就跳过，装了下次开 shell 自动生效）
#  安装命令见手册 §12
# ─────────────────────────────────────────────────────────────

# fzf：Ctrl-R 历史 / Ctrl-T 找文件 / Alt-C 跳目录。
# 用 fd 作为文件来源（自带、快、尊重 .gitignore）。
if type -q fzf
    set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --exclude .git --exclude .venv --exclude target'
    set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
    set -gx FZF_CTRL_T_OPTS '--preview "bat -n --color=always --line-range :200 {}"'
    set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --exclude .git --exclude .venv --exclude target'
    set -gx FZF_ALT_C_OPTS '--preview "eza --tree --level 2 --color always {} 2>/dev/null || lsd --tree --depth 2 --color always {} 2>/dev/null || ls -la {}"'
    fzf --fish | source
end

# zoxide：智能 cd，z <关键词> 跳常用目录；zi 配合 fzf 交互选择。
if type -q zoxide
    zoxide init fish | source
end

# yazi：文件管理器；退出后回到最后浏览的目录（官方 fish 包装）。
if type -q yazi
    function y --description 'yazi + cd to last dir on exit'
        set -l tmp (mktemp -t yazi-cwd.XXXXXX)
        yazi $argv --cwd-file="$tmp"
        if set -l cwd (cat -- "$tmp"); and test -n "$cwd"; and test "$cwd" != "$PWD"
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end
end
