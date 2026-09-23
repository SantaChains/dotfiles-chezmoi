vim.pack.add({ { src = "https://github.com/nvim-treesitter/nvim-treesitter", name = "treesitter" } })

require("nvim-treesitter").setup({
	highlight = { enable = true },
	indent = { enable = true },
})

require("nvim-treesitter").install({
	"bash",
	"html",
	"svelte",
	"latex",
	"javascript",
	"json",
	"lua",
	"markdown",
	"markdown_inline",
	"query",
	"regex",
	"tsx",
	"typescript",
	"python",
	"vim",
	"yaml",
})
