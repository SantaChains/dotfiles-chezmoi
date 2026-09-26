vim.pack.add({ { src = "https://github.com/nvim-treesitter/nvim-treesitter", name = "treesitter" } })

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

-- New API (main branch, nvim 0.12): highlight and indent are enabled per
-- filetype, not via setup(). start() fails silently (pcall) for filetypes
-- without an installed parser; indentexpr degrades to -1 (keep default).
vim.api.nvim_create_autocmd("FileType", {
	callback = function(args)
		if pcall(vim.treesitter.start, args.buf) then
			vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end
	end,
})
