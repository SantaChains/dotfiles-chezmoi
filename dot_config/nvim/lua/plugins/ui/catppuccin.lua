vim.pack.add({
	{ src = "https://github.com/catppuccin/nvim", name = "catppuccin" },
	{ src = "https://github.com/tadaa/vimade", name = "vimade" },
})

require("catppuccin").setup({
	flavour = "mocha",
	transparent_background = true,
	term_colors = true,
	custom_highlights = {
		LineNr = { fg = "#89b4fa" },
		CursorLineNr = { fg = "#f5c2e7", bold = true },
	},
})
require("vimade").setup({
	recipe = { "minimalist", { animate = true } },
	fadelevel = 0.8,
})
