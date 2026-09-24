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

require("mini.sessions").setup({ -- dir based session management (autosave/recovery handled by remember.nvim)
	autoread = false,
	autowrite = false,
	file = ".session",
	force = { read = false, write = true, delete = true },
})

require("mini.surround").setup() -- Suround selections with characters

require("mini.move").setup({ -- move selection in visual mode
	mappings = {
		down = "J",
		up = "K",
	},
})

require("mini.icons").setup() -- Icon provider

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
