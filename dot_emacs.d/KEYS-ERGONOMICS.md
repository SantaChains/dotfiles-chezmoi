# 键位人体工学重构计划（plain Emacs 32 + Evil + general）

> 目标：**先在物理层和小指负荷上止损，再用模态+序列把和弦降到最低**，同时保住 vim / nvim / VSCode 已有的肌肉记忆。
> 本文是设计与迁移规范；实施在 `lisp/editing.el`（+ 新增 `lisp/keys.el`）与 OS 层。

---

## 0. TL;DR

| 层 | 动作 | 收益 | 风险 |
|---|---|---|---|
| L0 OS | CapsLock→Ctrl（左右各一），空格长按→Ctrl（Kanata）或暂用 AHK | 承重修饰键落到拇指/主指位，Ctrl 不再靠小指侧伸 | 低（可关进程回滚） |
| L1 全局 | 修好当前**失效**的 leader 层（见 §1），把高频非编辑命令全部收进 `SPC` 单层 | 消灭 `C-c x`、`C-x x`、`C-<prior>` 等散键 | 低 |
| L2 Normal | 保留 vi 核心（hjkl / operator+text object / `/` `n` `u` `.`），只补 `SPC` 层 | 零迁移成本 | 低 |
| L3 Insert | 插入态不得有 ≥2 修饰键组合；`M-+`/`M-*`/`C-c s r` 迁出 | 打字流不回手 | 低 |
| 全局 | `repeat-mode` + 自定义 repeat map | 消灭 `C-x o C-x o C-x o` 类前缀重复 | 零 |
| 度量 | `my/keystroke-audit` 采集基线 → 改后对比 | 用数据而不是感觉验收 | 零 |

---

## 1. 现状核查（有证据，先修这个）

**1.1 leader 层实际没有绑定任何命令（已实测确认）。**
`lisp/editing.el:72-93` 的 `my/leader` 表全部写成 `"bb" '(:ignore consult-buffer :which-key "buffers")`。
general 在 `general--parse-maps` 里对带 `:ignore` 的项直接跳过：

```elisp
;; elpa/general-20250612.2309/general.el:971
unless (eq bindable-def :ignore)
  collect key and collect ... )
```

`:ignore` 的用途只是"给 which-key 挂描述"（同文件 913 行的注释：*just for side effects*）。
→ 结论：`SPC b b`、`SPC q q`、`SPC s l` … **目前按下去什么都不发生**，只有 which-key 里有个标签。
→ 影响面：整个 `SPC` 层是装饰品；实际可用键位只剩下面 1.2 的散键。

实测（真实 init.el 起临时 daemon 跑 `test/verify-live.el`，命令见 §5）：

```
SPC b b => nil   SPC e e => nil   SPC s l => nil   SPC q q => nil
--> 有绑定的键: 0 / 14        (evil=t general=t override-mode=t)
```

**1.2 第二处失效：`C-c s r` / `C-c s g` 惰性未绑定（根因已定位）。**
`lisp/completion.el:31-34`（`:config` 在 31，两条绑定在 33-34）把 `global-set-key` 写在 `use-package consult` 的 `:config` 里。`:config` 只在 **consult 被加载时**才运行，而 `:bind` 给的是 autoload——启动后没人碰过 `C-c i`/`C-x b`/`M-y`，consult 就一直没加载，那两个键压根不存在。

决定性实验（`emacs -Q --batch` 只加载 `windows.el` + `completion.el`）：

```
A) completion.el 加载后: C-c-s-r=2      consult-feature=nil  rg=t
B) require consult 后:   C-c-s-r=consult-ripgrep  C-c-s-g=consult-grep
```

→ 真因：**惰性加载 + 把绑定放进 `:config`**。改法是把这两条挤到 `:init`/`:bind`（一行级）。

> 同时纠正上一轮的误判：`lookup-key` 返回 `2` **不是**“前缀被吃”的凭据，而是“前 2 键是前缀、第 3 键未绑”（干净 `emacs -Q` 对同一个键也返回 2，已实测）。`C-c` 前缀 map 里的那个 `[t]` 也不是元凶。

---

## 1.3 和弦债务实测（真实 daemon，数据先行）

穷举可打印 ASCII + 常用功能键 × {无, `C-`, `M-`, `C-M-`}，逐个用真实 normal 态 `key-binding` 解析（`test/chord-inventory.el`）：

```
normal 态生效绑定：和弦起手 177 / 单键起手 104
拆分：必须保留 31 / 冗余可 unbind 68 / 无等价需给新家 70 / 前缀 8
```

**这是比“leader 没绑上”更根本的问题**：evil 只接管了它的键，Emacs 那层模态和弦仍然全量生效。所以现在按 `M-d` 真会杀词、`M-%` 真会弹 query-replace、`C-M-*` 一族实测 42 个三指和弦（可打印字符范围）。

| 类 | 数量 | 内容 | 处置 |
|---|---|---|---|
| 必须保留 | 31 | `C-g` `C-x` `C-c` `C-h` `M-x` `M-:` `C-w`(evil window) `C-r`(redo) `C-d/u/f/b/e/y`(滚动) `C-t` `C-]` `M-.` `M-,` `M-?` … | 不动（安全边界 / vim 语义 / 跨工具通用） |
| 冗余可 unbind | **68** | 实测构成：`M-` 系 39（`M-f M-b M-d M-k M-a M-e M-h M-q M-t M-u M-l M-c M-w M-z M-@ M-^ M-\ M-| M-v M-$ M-! M-& M-/ M-= M-SPC M-% M-( M-) M-{ M-} M-~ M-' M-i M-j M-r` …）+ `C-M-*` sexp/defun 系 20 + `C-<功能键>` 系 8 + `C-k` 1 | **直接 unbind**：evil 的 operator+motion 完全覆盖。额外的收益是消除误触（`M-d` 杀了词不进 evil undo 分组） |
| 无等价需给新家 | 70 | 实测拆：`digit-argument`/`negative-argument` **32**（vim 数字前缀，天然和弦，不该动），其余 **38**，其中 2 个是 `RET`/`TAB`（`C-RET`/`C-i` 的别名假阳性）→ 有效 **36**：`C-s` isearch、`C-a`、`C-q`、`M-o`、`M-v`、`M-;`、`C-M-\` indent-region、`C-M-a/e` defun 跳转、`C-<prior/next/tab>` 切 tab … | 迁到 `SPC` 层（§4）后确认可弃就删 |
| 前缀 | 8 | `C-x` `C-c` `C-h` `C-w` `ESC` `M-ESC` `M-g` `M-s` | 逐个决定（`M-g`/`M-s` 建议保留，它们是 Emacs 已固化的助记分组） |

**预期轨迹**：177 →（清 68）109 →（迁 36）**73**。剩下的 73 里 32 是 vim 数字前缀、8 是前缀键、31 是有意保留 —— 没有一个是“无意为之的和弦”。

**策略因此改变**：清野（unbind 68）比建 leader 便宜、比建 leader 先做，而且它不依赖任何新抽象。

---

## 1.4 跨工具对照（以你已固化的 nvim 键位为准）

实测自 `~/.config/nvim/lua/config/binds.lua`：

| 动作 | nvim 现状 | Emacs 现状 | 建议 |
|---|---|---|---|
| 定义跳转 | `gd`（裸键） | `K`（大写，需 Shift） | Emacs 加 `gd`，保留 `K` |
| 模糊跳转 | `ss`（flash） | `SPC s s`（现在是坏的） | Emacs 用 `SPC s s`；**不要**裸 `ss`（evil 的 `s` 是 substitute，占用会砸 vim 手感） |
| 关 buffer | `<leader>bd` | 无 | `SPC b d` ✓ |
| 诊断浮窗 | `<leader>d` | `SPC d d`（坏） | `SPC c d` |
| 终端 | `<leader>tj` / `tk` | 无 | `SPC o t` |
| undo 树 | `<leader>u` | 无 | `SPC t u` |
| code action / rename | `<leader>ca` / `cr` | 无 | `SPC c a` / `c r` ✓ |
| 插入态退出 | `jk` | `ESC` | **不跟进**：Emacs 引入 `jk` 必须做延迟判定（key-chord/evil-escape），与 §7 拒绝 key-chord 一致 |

---

## 1.5 现有散键（全部带修饰键或有前缀）

| 键 | 命令 | 问题 |
|---|---|---|
| `M-o` | other-window | Alt+o，单手，尚可 |
| `C-c k` | kill-this-buffer | `C-c` 前缀 + 小指 |
| `C-c i` | consult-imenu | `C-c` 二级散键，无分组 |
| ~~`C-c s r`~~ / ~~`C-c s g`~~ | ripgrep / grep | **惰性未绑定**（见 §1.2） |
| `C-x b` / `C-x p f` / `C-x g` | consult-buffer / project-find-file / magit | Emacs 老前缀，与新键位体系不统一 |
| `M-g g` / `M-y` | goto-line / yank-pop | — |
| `M-+` / `M-*` | tempel-complete / tempel-insert | **Alt+Shift+=（三指）** |
| `C-<prior>` / `C-<next>` | tab-bar 切换 | **Ctrl+PgUp 三指** |
| `K` | xref-find-definitions | 大写字母，需 Shift |
| `C-x C-r` | restart-emacs | 双 Ctrl 和弦 |

**1.6 结论**：leader 要从零建，但**优先级最高的不是建 leader，而是先清野**（§1.3 的 68 个）——零抽象、纯减法、立刻降误触。

---

## 2. 设计原则（R1–R8）与依据

| # | 原则 | 依据 |
|---|---|---|
| R1 | **承重修饰键必须在拇指/主指位**，不能靠小指侧伸 | 常规键盘 Ctrl 在左角，滥用导致左手小指过度外展与腕部尺偏（Human Factors 1999 实测打字时左腕尺偏 15°±7.7°、背伸 21°；腕背伸/尺偏升高腕管内压）。macOS 把主修饰键放 Command——**紧挨空格**，拇指可达，并且 Apple HIG 明确要求"主修饰键用 Command，**避免**把 Control 当修饰键" |
| R2 | **模态优先**：Normal 态零修饰键，Insert 态不打命令 | vi 的 operator+text object 把编辑表达成句子，2–4 击基本恒定；Emacs 默认的 C-/M- 和弦是"Emacs pinky"公认成因 |
| R3 | **序列替代和弦**（前缀 > 同按） | 前缀误键只退出、不误执行；和弦误键会执行错命令。Spacemacs 四支柱：Mnemonic / Discoverable / Consistent / Crowd-Configured；Doom 把 leader 定义为"键盘版菜单栏，随处可用" |
| R4 | **越高频越短**：Top-N 命令用 2 击（前缀+1 键），不用 3 击 | KLM：K=0.20s（平均打字者）、M=1.35s（心理准备）——每多一级前缀就多一次 M+K |
| R5 | **助记优先于位置**：分组键取命令/概念的英文首字母，同一概念永不换键 | 1989 研究：verb-modifier-object 顺序 + 助记缩写在大命令集下"远易于学习、且抗遗忘"，显著优于 Emacs 键位集 |
| R6 | **跨工具同手指**：Emacs leader 与已有 nvim leader 对齐 | 用户 `~/.config/nvim/lua/config/binds.lua` 已固化：`<leader>ff/fg/fb` 文件/搜索/buffer、`<leader>bd` 关 buffer、`<leader>ca/cr` code action/rename、`<leader>u` undotree。两套编辑器共用一个脑回路 |
| R7 | **跨 OS 语义对齐**：Ctrl=命令、Super=系统、Alt=菜单/次要 | Windows UI 指南固定 Ctrl+A/C/F/N/O/S/V/X/Y/Z 与 Alt=菜单；GNOME 规定"系统修饰键用 Super，不许抢 Alt"；i3/浏览器 `Super/Ctrl + 1..9`=切第 N 个 |
| R8 | **可发现 > 可记忆**：不记得就搜 | VSCode `Ctrl+Shift+P` / JetBrains `Ctrl+Shift+A` (Find Action) / Blender 空格搜索 都是同一哲学；实证研究显示用户很少自发从菜单迁到快捷键（*Hidden Costs of GUI*），所以必须有"搜命令"的入口 + which-key 实时提示 |

### 额外硬约束（写在实施里）

- **单次操作同手连击 ≤ 2**：`SPC`（拇指）后第二键优先用右手区（h j k l u i o n m）。
- **禁止 ≥2 修饰键的组合**进入高频路径（`C-M-`、`M-S-`、`C-S-` 一律改序列或 transient）。
- **`C-g` 保留**：取消是安全边界，任何重排不得破坏（并在 OS 层保证它是 Ctrl 位）。
- **Insert 态只用单修饰键或裸键**。

---

## 3. 三层架构

```
L0  OS/固件    CapsLock→Ctrl, 右 Alt→Ctrl, 空格长按→Ctrl(层键)
L1  Emacs 全局  SPC = leader（normal/visual/motion 生效，仿 Doom override keymap）
               SPC m / SPC ,  = localleader（buffer/项目局部命令）
               C-h 帮助体系保留；C-g 取消保留
L2  Evil Normal vi 核心不动：h j k l w b e 0 $ gg G d c y p P u C-r . / n N : q
               新增 SPC 单层分组（见 §4）
L3  Insert      裸键 / 单修饰键；模板与补全命令迁到 SPC
```

**为什么 `SPC` 而不是 `,`**：空格是全身最省力、面积最大的键，拇指按、且 normal 态原本无功能；`, ` 是 evil 的 `;`-类反向查找位（`f`/`t` 的反向），占它会破坏 vim 手感。现有 `my/leader-key ","` 降级为**备用 leader**（供非 evil 用户/终端复用）。

---

## 4. 目标键位表（P0 全量清单）

分组遵循 Doom/Spacemacs 分类键（`b f s p g w c h t q o u`），与 nvim 重叠处从 nvim（R6）。
**只列新增/变更**，vi 核心键不动。

### 4.1 Top 频次（≤2 击，最高优先）

| 键 | 命令 | 理由 |
|---|---|---|
| `gd` | `xref-find-definitions`（`K` 保留） | **裸键，0 和弦**；与 nvim 的 `gd` 一致（§1.4） |
| `SPC SPC` | `consult-buffer` | 最常用，最短序列（Doom 同位置） |
| `SPC :` | `execute-extended-command` | 命令面板：VSCode `Ctrl+Shift+P` / JetBrains `Ctrl+Shift+A` 的等价位（R8） |
| `SPC .` | `find-file` | Doom 的 `SPC .` 是 localleader；此处改绑"最常用文件动作"，**放弃 Doom 一致性换取 2 击**（见 §8 决策点） |
| `SPC ,` | localleader 别名 | 与 `SPC m` 等价，单手可达 |
| `SPC /` | `consult-ripgrep` | `/`=搜索直觉，替代 `C-c s r` |
| `SPC *` | `consult-line` | `*`=当前 buffer 内搜 |
| `SPC =` | `consult-imenu` | 大纲/符号跳转（VSCode `Ctrl+Shift+O` 等价） |
| `SPC TAB` | `evil-window-next`（另：`evil-switch-to-windows-last-buffer`） | — |

### 4.2 分组层（`SPC <组> <动作>`）

| 组 | 键 | 内容 |
|---|---|---|
| **b** buffer | `b b` 列表、`b d` 关闭（与 nvim `<leader>bd` 一致）、`b k` 关闭其它、`b s` 保存、`b r` 重载、`b n/p` 下/上 | — |
| **f** file | `f f` find-file、`f r` recent、`f s` save、`f S` save-as、`f R` rename、`f d` 删除到回收站、`f e` 编辑 init.el | `ff/fr/fs` 与 nvim `<leader>ff` 对齐 |
| **s** search | `s p` 项目搜索(ripgrep)、`s g` grep、`s b` buffer 内搜、`s l` 当前行跳转、`s s` avy 跳字、`s o` imenu/大纲 | — |
| **p** project | `p p` 切换项目、`p f` 项目内找文件、`p b` 项目 buffer、`p k` 杀项目 buffer、`p r` 最近项目 | 与 VSCode `Ctrl+R` 工作区概念一致 |
| **g** git | `g g` magit-status、`g b` blame、`g l` log、`g d` diff、`g s` stage hunk | — |
| **w** window | `w h/j/k/l` 选窗、`w s/v` 横/纵分、`w d` 关闭、`w o` 只留当前、`w =` 均衡、`w u` winner-undo | 替代 `C-w` 系列的和弦 |
| **c** code | `c a` code action、`c r` rename、`c d` 定义、`c D` 引用、`c i` 实现、`c f` 格式化、`c n` 下一个诊断、`c p` 上一个诊断 | **与 nvim `<leader>ca/cr/cp/cn` 完全一致**（R6）。注：`eglot-rename`/`eglot-code-actions` 当前**无 autoload**（实测 fboundp=nil），必须在 `with-eval-after-load 'eglot` 内绑定 |
| **h** help | `h k` describe-key、`h f` describe-function、`h v` describe-variable、`h m` describe-mode、`h b` describe-bindings、`h w` which-key 顶层 | Doom 同构 |
| **t** toggle | `t l` 行号、`t w` 折行、`t f` 折叠、`t d` diff-hl、`t z` `zoom-window-zoom`、`t t` tab-bar | — |
| **q** quit | `q q` 退出 Emacs、`q s` 保存全部并退出、`q r` restart-emacs | 替代 `C-x C-r` |
| **o** open | `o a` elfeed、`o t` 终端、`o g` gptel、`o d` dired | — |
| **i** insert | `i s` tempel 补全、`i t` tempel 插入、`i y` 插入 yank | **替代 `M-+` / `M-*`（三指和弦）** |
| **1..9** | `tab-bar-select-tab` | 浏览器/i3/tmux 同构（R7），替代 `C-<prior>` |

### 4.3 localleader（`SPC m`，按主模式）

| 模式 | 键 | 命令 |
|---|---|---|
| prog 通用 | `m n` outline-cycle、`m c` 注释、`m i` imenu、`m e` eglot、`m f` 格式 | — |
| go / zig / markdown 等 | 由 `lisp/lsp.el` 挂 `eglot`/`dape` 命令 | — |

### 4.4 明确**不动**的键

`h j k l w b e 0 $ gg G d c y p u C-r . / n N f t ; , * # % { } ( )` — vi 核心。
`C-g`（取消）、`C-h`（帮助前缀）、`C-x C-s`/`C-x C-c`（肌肉记忆，保留但不再是主路径）、`M-x`（Alt 在空格旁，拇指可达，不算负担）。
`C-d`/`C-u`（滚动）、`C-w`（evil 删词/窗口前缀）保留——vim 核心，2 击胜过 3 击序列（R4）。

---

## 5. 分期与验证

每期结束必须过**验证门**。已就位的最小验证（`test/verify-live.el`，不需要 GUI、不碰交互会话）：

```bash
cd ~/.emacs.d
emacs --daemon=verify-keys          # 用真实 init.el 起临时 daemon
emacsclient -f "$HOME/.emacs.d/server/verify-keys" \
  --eval '(progn (load "~/.emacs.d/test/verify-live.el" nil t) (vk/report))'
emacsclient -f "$HOME/.emacs.d/server/verify-keys" --eval '(kill-emacs)'
```

输出是「每个待查键 → 实际绑定」，可当断言：P0-a 完成后同法再跑，期望 `有绑定的键: 14 / 14`。

注意：`emacs --batch -l init.el` **不能**用于本项验证——evil 是 `:defer 0.1` 加载，batch 下 `evil=nil`，leader 全查不到（已实测）。`emacs --daemon` 跑满 120s 会被 `timeout` 杀掉，验完立刻 `kill-emacs`。

**本轮实测踩过的三个坑（都会让你得到假结论，已写进测试脚本注释）**：

| 坑 | 现象 | 正确做法 |
|---|---|---|
| `map-keymap` 枚举 | 完全漏报 `M-*` 绑定（meta 事件不在 char-table 迭代范围） | 穷举候选键空间 + `key-binding` 逐个解析 |
| batch 里提前 `(require 'evil)` | 为了触发 `use-package :after` 而提前加载，反而使 `editing.el` 的 `evil-want-*` 前置变量失效（`C-u` 行为失真） | 优先在真实 daemon 里跑 |
| 用 `lookup-key` 返回值判死 | 返回 `2` 就误判为“前缀被吃” | `2` 只意味着“前 2 键是前缀”；用 `key-binding` 验证真实可达性 |

### P0-a  清野（零抽象、纯减法，先做这个）
1. 新增 `lisp/keys.el`，把 §1.3 的 **68 个冗余和弦 unbind**（`M-` 系 39 + `C-M-*` 系 20 + `C-<功能键>` 系 8 + `C-k` 1），用列表生成而不是手写 68 行。
2. 修 §1.2 的惰性 bug：`completion.el` 里两条 `global-set-key` 从 `:config` 挑到 `:bind`。
3. 开 `repeat-mode 1` + 自定义 repeat map（窗口尺寸、outline、diff-hl、tab、grep 跳转）。
4. **验证**：`test/chord-inventory.el` 再跑一次，期望 `和弦起手` 从 177 降到 **109**；`C-h k M-d` 报 “M-d is undefined”。

### P0-b  建骨架（手感变化：中）
1. 把 §1.1 的 `:ignore` 占位改成真绑定（全在 `keys.el`，`editing.el` 只留加载）。
2. 把 §1.3 “需给新家”里的 ~36 个真命令过一遍：迁进 `SPC` 层或确认可弃。
3. **验证**：`test/verify-live.el` 期望 `有绑定的键: 14 / 14`；和弦起手降到 **~73**；并对 §4 用到的每个命令名做 `fboundp` 断言（**本轮已实测**：22 个命令名里 18 个 OK，2 个写错已修（`evil-switch-to-window`→`evil-window-next`、`zoom-window`→`zoom-window-zoom`），2 个 `eglot-*` 无 autoload 需包在 `with-eval-after-load`），否则绑定会指向未定义命令。

### P0-c  收容散键 + Insert 态清零和弦
按 §4 全量绑定；§1.5 的旧散键留 2 周双绑；`M-+`/`M-*` → `SPC i s`/`SPC i t`；`C-c s r`/`C-c i`/`C-c k` 删除；`C-<prior>` → `SPC 1..9`。

### P1  OS 层（顺序：AHK 快赢 → Kanata 长期）
1. 先用已装的 AutoHotkey（`/d/Soft/SCOOP/shims/AutoHotkey`）做最保守的一步：**CapsLock→Ctrl**。开机自启可参考现有 `~/.config/whkd-autostart.vbs` 模式。
2. 可选升级 Kanata（未安装）：Caps→Ctrl（tap=Esc）、右 Alt→Ctrl、空格长按→Ctrl 层键。
3. **验证**：`C-h k` 里能按出 `C-x`（左小指不伸）；打字 30 分钟无小指酸。回滚 = 退出常驻进程。

### P2  发现性打磨
`keycast` 已有；补 `SPC h k`/`SPC :` 的频次记录；用 §6 数据再砍一轮。

---

## 6. 度量（先量后改，别信感觉）

内置无依赖埋点，落盘 TSV：

```
keys/stamp      keys-desc            nmods  cmd
```

- `nmods` = `this-command-keys-vector` 里修饰键事件的个数 → **和弦率 = Σ(nmods>0) / 总条数**。
- 一天后：`awk` 出 Top-30 命令 → 决定 §4 里谁该升到 2 击、谁可以降级。
- 改后同法再采一次，对比三指标：**总击键数、和弦率、Top-10 命令平均序列长度**。
- 目标：和弦率降到基线的一半；Top-10 命令全部 ≤2 击。
- 不做 A/B 就不断言"更快/更省"（工具自报的节省一律不采信）。

---

## 7. 不采纳清单（有理由，不是没想到）

| 方案 | 理由 |
|---|---|
| `key-chord`（同击双键） | 需要延迟判定，打字流会 lag；其 README 自己把"快打时 lag"列为禁用场景。前缀序列无此代价（R3） |
| home-row mods（a→Ctrl 等） | 需要双手配合、快打时误触，社区/厂商文档均列为已知缺点。若上 Kanata，优先**拇指位**而非主行 |
| 全量换 Colemak/Dvorak | 迁移成本数周且收益无共识；R1 的收益由 OS 层 1 键重映射即可拿到大半 |
| 重构 vi 核心（改 hjkl、改 operator） | 破坏 R6（nvim 一致性）与十几年肌肉记忆，收益不抵成本 |
| 全面 `M-x` → 自建命令面板前缀 | `M-x` 本身是 Alt（拇指位）+ 1 键，已是 2 击；只增 `SPC :` 别名，不删 `M-x` |
| 全键位一次性大改（无过渡） | 违反可逆性；P0-a 与 P0-b 分两步，旧键双绑 2 周 |

---

## 8. 决策点（若与你的直觉冲突，改这里）

1. **`SPC .` 用来做什么**：本方案给它 `find-file`（2 击，最高频），代价是放弃 Doom 的"`SPC .` = localleader"惯例（本方案 localleader 用 `SPC m` / `SPC ,`）。
2. **OS 层做到哪一步**：Caps→Ctrl（1 键，最保守）／+右 Alt→Ctrl（对称）／+空格长按→Ctrl（Kanata，最彻底）。默认按最保守起步。
3. **normal 层是否微调**：默认不动（保 vim 肌肉记忆）；若愿意，可后续把 `;`→localleader、`s`→surround(需 evil-surround)。
4. **是否允许装 Kanata**：默认不装，先用已有 AutoHotkey。

---

## 附：依据来源

- Apple HIG *Keyboards*（主修饰键用 Command、避免 Control）、Apple 支持页（Command 在空格两侧）
- Microsoft *Shortcut Keys: UI Text Guidelines*（Ctrl+A/C/F/N/O/S/V/X/Y/Z 固定语义；Alt=菜单）
- GNOME Design *Keyboard Shortcuts*（系统修饰键用 Super，不抢 Alt）
- IntelliJ IDEA *Predefined keymaps* / *Find Action*；Blender *Operators* & *Design Paradigms*（modal operator、双击切换变体、非模态优先）
- Spacemacs DOCUMENTATION 四支柱；Doom `doom-keybinds.el`（leader/localleader 定义）
- GNU Emacs 手册 *Repeating*（`repeat-mode`）；karthink *Persistent prefix keymaps*
- Card/Moran/Newell KLM（K=0.20s、M=1.35s）；Lane et al. *Hidden Costs of GUI*（用户不自发迁移到快捷键）
- 1989 *Designing keybindings to be easy to learn and resistant to forgetting*（助记 + verb-modifier-object）
- Human Factors 1999 *Wrist and Forearm Postures of Users of Conventional Keyboards*（尺偏/背伸实测）；*Effect of wrist posture on carpal tunnel pressure*（腕管内压）
- XahLee *How to Avoid Emacs Pinky*、*Emacs vs vim: Compute Keybinding Efficiency*
- Dygma *Home-row mods vs Thumbkeys*；key-chord README（快打 lag）
