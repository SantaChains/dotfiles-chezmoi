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

vim.lsp.config("rust_analyzer", {
	cmd = { "LspProxy", "--", "rust-analyzer" },
})

vim.lsp.config("gopls", {
	settings = {
		gopls = {
			gofumpt = true,
		},
	},
	flags = { debounce_text_changes = 150 },
})

vim.lsp.config("yamlls", {
	settings = {
		yaml = {
			schemas = {
				["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
			},
		},
	},
})

vim.lsp.config("hls", {
	settings = {
		haskell = {
			cabalFormattingProvider = "cabalfmt",
			formattingProvider = "ormolu",
		},
	},
	single_file_support = true,
})

vim.lsp.config("golangci_lint_ls", {})

vim.lsp.config("ltex", {
	diagnostics = { disable = { "missing-fields" } },
})

vim.lsp.enable({
	"lua_ls",
	"ts_ls",
	"pylsp",
	"cssls",
	"svelte",
	"rust_analyzer",
	"gopls",
	"golangci_lint_ls",
	"yamlls",
	"hls",
	"ltex",
	"emmet_language_server",
})

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
