-- Pragtical 用户模块 (chezmoi 管理)
-- 目标: ~/.config/pragtical/init.lua   (pragtical v3.12.5, scoop 安装)
--
-- USERDIR 解析顺序(官方文档,命中即用):
--   1) <exe 所在目录>/user        <- 便携模式,发布包自带,优先级最高!
--   2) $PRAGTICAL_USERDIR
--   3) $XDG_CONFIG_HOME/pragtical <- 本机命中这里(C:\Users\Jliu Pureey\.config)
--   4) $HOME/.config/pragtical
-- 因此必须把自带的 <exe>/user 目录移走(官方 README 也是这么写的),否则本文件不会被读取。
-- 本模块在插件之前加载,保存后自动重载。

local core = require "core"
local config = require "core.config"
local keymap = require "core.keymap"
local style = require "core.style"

------------------------------ 主题 --------------------------------------------
-- 默认即深色主题(default.lua)。想换内置主题就取消注释其中一行:
-- core.reload_module("colors.tokyo_night")
-- core.reload_module("colors.catppuccin-mocha")
-- core.reload_module("colors.gruvbox_dark")
-- core.reload_module("colors.rose-pine")
-- core.reload_module("colors.nightfox")
-- 浅色: core.reload_module("colors.summer")

------------------------------ 字体 --------------------------------------------
-- 发布包自带 DATADIR/fonts: JetBrainsMono-Regular.ttf / FiraSans-Regular.ttf / icons.ttf
-- SCALE 用于把字号按 DPI 换算成像素,别硬写像素值。
local mono = DATADIR .. "/fonts/JetBrainsMono-Regular.ttf"
local ui = DATADIR .. "/fonts/FiraSans-Regular.ttf"
local SIZE = 14

style.code_font = renderer.font.load(mono, SIZE * SCALE)
style.font = renderer.font.load(ui, SIZE * SCALE)
style.big_font = renderer.font.load(ui, (SIZE * 2.5) * SCALE)

-- 中文回退字体:Windows 自带微软雅黑(msyh.ttc 只有第一个 face 可用,正好是雅黑)。
-- 用 pcall 包住,字体文件缺失时只跳过回退,不会让编辑器启动失败。
local ok_cjk, cjk = pcall(renderer.font.load, "C:\\Windows\\Fonts\\msyh.ttc", SIZE * SCALE)
if ok_cjk then
  style.code_font = renderer.font.group { style.code_font, cjk }
  style.font = renderer.font.group { style.font, cjk }
end

---------------------------- 缩进 / 编辑行为 ------------------------------------
config.indent_size = 4
config.tab_type = "soft" -- "soft"=空格 "hard"=制表符
config.max_project_files = 5000 -- 项目索引上限(默认 2000)

-- 光标闪烁
-- config.disable_blink = true
-- config.blink_period = 0.4

-- 追加忽略项(文件夹以 / 结尾,文件以 $ 结尾)
table.insert(config.ignore_files, "^build/")
table.insert(config.ignore_files, "^dist/")
table.insert(config.ignore_files, "^target/")

---------------------------- 快捷键 --------------------------------------------
-- 均为已验证存在的命令名;默认表里 ctrl+up/down 已是 move-lines,这里加 alt 版备用
keymap.add {
  ["alt+up"] = "doc:move-lines-up",
  ["alt+down"] = "doc:move-lines-down",
}

-- 一键打开本文件(命令面板里叫 core:open-user-module)
keymap.add({ ["ctrl+shift+,"] = "core:open-user-module" }, true)

-- 用 Ctrl+Tab / Ctrl+Shift+Tab 切标签是默认行为;想改成 alt+方向键切换视图:
-- keymap.add({ ["ctrl+j"] = "root:switch-to-down", ["ctrl+k"] = "root:switch-to-up" })
