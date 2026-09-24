vim.pack.add({
	{ src = "https://github.com/catgoose/nvim-colorizer.lua", name = "colorizer" },
})

-- norcalli repo is unmaintained and uses deprecated vim.tbl_flatten (removed in 0.13).
-- catgoose rewrite; css preset = names, hex, rgb(), hsl(), oklch(), css var();
-- hex default = true adds #RRGGBBAA (8-digit, off by default).
require("colorizer").setup({
	filetypes = { "*" },
	options = {
		parsers = {
			css = true,
			hex = { default = true },
		},
	},
})
