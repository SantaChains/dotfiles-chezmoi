vim.pack.add({
	{ src = "https://github.com/neovim/nvim-lspconfig", name = "lspconfig" },
	{ src = "https://github.com/saghen/blink.cmp", name = "blink" },
	{ src = "https://github.com/saghen/blink.lib", name = "blink-lib" },
})

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			-- Tell the server to let Neovim handle snippet expansion
			completion = {
				callSnippet = "Replace",
			},
			-- Use LuaJIT (which Neovim uses)
			runtime = {
				version = "LuaJIT",
			},
		},
	},
})
vim.lsp.enable({
	"lua_ls",
	"ts_ls",
	"pylsp",
	"cssls",
	"svelte",
	"rust_analyzer",
	"emmet_language_server",
})

vim.o.winborder = "rounded"

vim.api.nvim_set_hl(0, "BlinkCmpMenuBorder", { fg = "#89b4fa" })

require("blink.cmp").build():pwait()

require("blink.cmp").setup({
	fuzzy = { implementation = "rust" },
	appearance = { use_nvim_cmp_as_default = true },

	keymap = {
		["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
	},

	signature = {
		enabled = false,
	},

	completion = {
		trigger = {
			show_on_insert = true,
			show_on_trigger_character = true,
			show_on_keyword = true,
			show_on_backspace = true,
		},
		list = {
			selection = {
				preselect = false,
				auto_insert = true,
			},
		},
		menu = {
			auto_show = true,
			border = "rounded",
			min_width = 35,
			auto_show_delay_ms = 100,
		},
	},

	sources = {
		default = {
			"lsp", -- (Equivalent to cmp-nvim-lsp)
			"snippets", -- (Handled by the snippets config, replaces cmp_luasnip source)
			"buffer", -- (Equivalent to cmp-buffer)
			"path", -- (Equivalent to cmp-path)
		},
	},
})

vim.api.nvim_create_autocmd("FileType", { -- Lazy load lazydev when in lua file (no pun intended)
	pattern = "lua",
	callback = function()
		vim.pack.add({
			{ src = "https://github.com/folke/lazydev.nvim", name = "lazydev" },
		})
		require("lazydev").setup()
		require("blink.cmp").setup({ -- Reload blink with lazydev as a source
			sources = {
				-- add lazydev to your completion providers
				default = { "lazydev", "lsp", "path", "snippets", "buffer" },
				providers = {
					lazydev = {
						name = "LazyDev",
						module = "lazydev.integrations.blink",
						-- make lazydev completions top priority (see `:h blink.cmp`)
						score_offset = 100,
					},
				},
			},
		})
	end,
})
