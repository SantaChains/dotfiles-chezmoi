vim.pack.add({
	{ src = "https://github.com/okuuva/auto-save.nvim", name = "autosave" },
	{ src = "https://github.com/vladdoster/remember.nvim", name = "remember" },
	{ src = "https://github.com/Aasim-A/scrollEOF.nvim", name = "scrolleof" },
	{ src = "https://github.com/folke/flash.nvim", name = "flash" },
	{ src = "https://github.com/mbbill/undotree", name = "undotree" },
})

require("auto-save").setup({
	enabled = true,
	trigger_events = {
		immediate_save = { "BufLeave", "FocusLost", "QuitPre", "VimSuspend" },
		defer_save = { "InsertLeave" }, -- save after debounce
		cancel_deferred_save = { "InsertEnter" }, -- cancel pending save
	},
	debounce_delay = 1000,
	noautocmd = true,
})

-- enable remember
require("remember").setup({})

-- enable scrolleof
require("scrollEOF").setup({
	-- The pattern used for the internal autocmd to determine
	-- where to run scrollEOF. See https://neovim.io/doc/user/autocmd.html#autocmd-pattern
	pattern = "*",
	-- Whether or not scrollEOF should be enabled in insert mode
	insert_mode = false,
	-- Whether or not scrollEOF should be enabled in floating windows
	floating = true,
	-- List of filetypes to disable scrollEOF for.
	disabled_filetypes = { "terminal" },
	-- List of modes to disable scrollEOF for. see https://neovim.io/doc/user/builtin.html#mode()
	disabled_modes = { "t", "nt" },
})

-- Undotree keymap (undotree is a VimScript plugin, use its command)
vim.keymap.set("n", "<leader>u", ":UndotreeToggle<CR>")
