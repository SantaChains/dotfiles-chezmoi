vim.pack.add({ { src = "https://github.com/echasnovski/mini.nvim", name = "mini" } })

require("mini.pairs").setup() -- Bracket pairs and stuff

require("mini.ai").setup() -- Around and In extension for visual mode

vim.g.minicursorword_disable = true -- perf: skip per-cursor-move word match
require("mini.cursorword").setup() -- Underline current word below cursor (makes it easier to c and d)

require("mini.indentscope").setup({ -- shows indents
	symbol = "│",
	draw = {
		delay = 10,
		animation = function() return 0 end, -- perf: instant draw, was linear 15ms
		-- animation = require("mini.indentscope").gen_animation.linear({
		-- 	duration = 15,
		-- 	unit = "step",
		-- 	easing = "out",
		-- }),
	},
})

require("mini.trailspace").setup() -- Shows useless spaces

-- 文件浏览器：替代 netrw/telescope-file_browser 的日常浏览（<Space>fn 打开）
require("mini.files").setup()

-- 删 buffer 但保留窗口布局（比 :bd 更安全，不会连带关窗口）
require("mini.bufremove").setup()

require("mini.sessions").setup({ -- dir based session management (autosave/recovery handled by remember.nvim)
	autoread = false,
	autowrite = false,
	file = ".session",
	force = { read = false, write = true, delete = true },
})

require("mini.surround").setup() -- Suround selections with characters

require("mini.move").setup({ -- move selection in visual mode
	-- 注意：mappings 是整表替换而不是合并，四个方向必须写全，
	-- 否则没写的方向（默认 H/L）会直接丢映射。
	mappings = {
		left = "H",
		right = "L",
		down = "J",
		up = "K",
	},
})

local animate = require("mini.animate") -- animations ovs
require("mini.animate").setup({
	cursor = {
		enable = false,
	},
	scroll = {
		enable = false, -- perf: disable smooth scroll animation
		-- Animate for 200 milliseconds with linear easing
		timing = animate.gen_timing.linear({ duration = 100, unit = "total" }),
		-- Animate equally but with at most 120 steps instead of default 60
		subscroll = animate.gen_subscroll.equal({ max_output_steps = 60 }),
	},
})

-- 按前缀键后列出下一步可用键；描述自动取自各映射的 desc 字段
-- （见 config/binds.lua、config/hydra.lua）。前缀组本身没有映射，clue 里单独补。
local miniclue = require("mini.clue")
miniclue.setup({
	triggers = {
		{ mode = "n", keys = "<Leader>" },
		{ mode = "n", keys = "<C-T>" },
		{ mode = { "n", "x" }, keys = "g" },
		{ mode = { "n", "x" }, keys = "z" },
		{ mode = "n", keys = "<C-w>" },
		{ mode = { "i", "c" }, keys = "<C-x>" },
		{ mode = { "i", "c" }, keys = "<C-r>" },
	},
	clues = {
		-- 分组标题
		{ mode = "n", keys = "<Leader>b", desc = "+Buffer" },
		{ mode = "n", keys = "<Leader>B", desc = "+Debug" },
		{ mode = "n", keys = "<Leader>c", desc = "+Code" },
		{ mode = "n", keys = "<Leader>f", desc = "+Find" },
		{ mode = "n", keys = "<Leader>q", desc = "+Session" },
		{ mode = "n", keys = "<Leader>s", desc = "+Search" },
		{ mode = "n", keys = "<Leader>t", desc = "+Terminal" },
		-- 内置键位
		miniclue.gen_clues.builtin_completion(),
		miniclue.gen_clues.g(),
		miniclue.gen_clues.marks(),
		miniclue.gen_clues.registers(),
		miniclue.gen_clues.windows(),
		miniclue.gen_clues.z(),
	},
	window = {
		-- timeoutlen 默认 1000，留一点余量让窗口跟得上按键
		delay = 200,
		config = { width = "auto", border = "rounded" },
	},
})
