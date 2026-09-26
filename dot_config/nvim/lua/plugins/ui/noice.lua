vim.pack.add({
	{ src = "https://github.com/folke/noice.nvim", name = "noice" },
	{ src = "https://github.com/MunifTanjim/nui.nvim", name = "nui" },
	{ src = "https://github.com/rcarriga/nvim-notify", name = "notify" },
})

-- notify.setup returns its config table, not a callable; assign the module itself
require("notify").setup({
	background_colour = "#000000",
	render = "compact",
	stages = "slide",
})
vim.notify = require("notify")
require("noice").setup({
	messages = {
		enabled = true,
		view = "mini",
		view_error = "notify", -- view for errors
		view_warn = "notify", -- view for warnings
		view_history = "messages", -- view for :messages
		view_search = "virtualtext", -- view for search count messages. Set to `false` to disable
	},
	notify = {
		enabled = true,
		view = "notify",
	},
	lsp = {
		-- noice 接管 LSP UI(消除 checkhealth 四条 WARNING):
		-- hover/signature 走 noice 弹窗,markdown 渲染经 noice 处理
		override = {
			["vim.lsp.util.convert_input_to_markdown_lines"] = true,
			["vim.lsp.util.stylize_markdown"] = true,
		},
		hover = {
			enabled = true,
		},
		signature = {
			enabled = true,
		},
	},
	presets = {
		long_message_to_split = true, -- long messages will be sent to a split
		inc_rename = false, -- enables an input dialog for inc-rename.nvim
		lsp_doc_border = false, -- add a border to hover docs and signature help
	},
})
