# chezmoi 速查（极简）

> 本文件在仓库根目录，**不受 chezmoi 管理**（无前缀属性 → chezmoi 忽略）。纯备忘录。

## 日常命令
```powershell
chezmoi add -v <目标文件路径>   # 把已存在的真实配置收编进源仓库（拷贝，不改目标）
chezmoi apply                  # 源 → 目标（下发）；加 -v 看改了什么
chezmoi diff                   # 只看会改哪些，不落盘
chezmoi re-add                 # 直接改了目标文件后，反向回存到源
chezmoi forget <path>          # 停止管理某文件（保留目标文件本身）
chezmoi managed                # 列出所有受管目标
chezmoi verify ~/.config/...   # 校验某目标是否与源一致
chezmoi doctor                 # 体检（看 suspicious-entries / 路径）
```

## Windows 关键坑（务必记住）
每个工具读配置的根目录不同，放错 = 白写：
- **走 XDG(`~/.config`) 的工具**：lazygit、yazi、starship、whkd、glazewm、mise、uv、tealdeer、lsd、ripgrep、gh、nvim。
  → chezmoi 源路径写 `dot_config/<tool>/...`
- **走 `%APPDATA%\<tool>`（dirs crate）的工具**：helix、bat、alacritty、zed、micro、wezterm。
  → chezmoi 源路径写 `AppData/Roaming/<tool>/...`
- **走 `%LOCALAPPDATA%\<tool>`**：clangd（`AppData/Local/clangd/config.yaml`）。
- **ripgrep 不认默认路径**：必须设环境变量 `RIPGREP_CONFIG_PATH`（已由 `run_once_set-ripgrep-env.ps1` 写入）。
- **delta / eza 无独立配置文件**：delta 配在 `~/.gitconfig`；eza 靠别名/环境变量。

## 提交纪律
- 改完源：`git add -A && git commit`（chezmoi 配了 autoCommit 会自动提交，autoPush 关闭）。
- **手动 `git push`**，不要盲目推；推送前务必确认无密钥（见下）。

## 安全
- 绝不提交密钥：`gh/hosts.yml`、`**/auth.ini`、`*.token`、`*_KEY/*`、`*password*` 已在 `.chezmoiignore`/`.gitignore` 排除。
- 一旦某个 key 泄露到公开仓库：**先去服务端吊销/轮换**，再重写历史 + 强推；只清 git 历史救不回已公开的密钥。



--- 
## 等待添加
fish
temux
zellij
ghostty
katty


---
## 独立配置不收编
wezterm
nushell
nvim:lazyvim Astronvim nvchal