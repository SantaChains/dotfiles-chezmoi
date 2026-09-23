vim.pack.add({
	{ src = "https://github.com/norcalli/nvim-colorizer.lua", name = "colorizer" },
})

require("colorizer").setup({ "*" }, {
	RGB = true,
	RRGGBB = true,
	RRGGBBAA = true,
	HSL = true,
	css = true,
	css_fn = true,
})
