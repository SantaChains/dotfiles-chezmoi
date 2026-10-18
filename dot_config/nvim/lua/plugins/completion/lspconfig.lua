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

vim.lsp.config("clangd", {
	-- clangd 靠 compile_commands.json 做精确分析；用 cmake 的项目建议：
	--   cmake -S. -Bbuild -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
	-- 然后把 build/compile_commands.json 拷/链接到项目根目录。
	cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
	root_markers = { "compile_commands.json", "compile_flags.txt", ".clangd", ".git" },
})

vim.lsp.config("ltex", {
	diagnostics = { disable = { "missing-fields" } },
})

vim.lsp.enable({
	"lua_ls",
	"ts_ls",
	"pylsp",
	"cssls",
	"clangd", -- C / C++
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

-- Jump out of an empty pair: cursor sits between opening and closing char
local pair_close = { ["("] = ")", ["["] = "]", ["{"] = "}", ['"'] = '"', ["'"] = "'", ["`"] = "`" }
local function tabout(cmp)
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2]
	-- 面板可见时先撤销 auto_insert 的预览，否则预览文本会留在缓冲区里
	if cmp and cmp.is_menu_visible() then
		cmp.cancel()
		line = vim.api.nvim_get_current_line()
		col = vim.api.nvim_win_get_cursor(0)[2]
	end
	local close = pair_close[line:sub(col, col)]
	if close and line:sub(col + 1, col + 1) == close then
		vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], col + 1 })
		return true
	end
	return false
end

-- Accept completion, then shift cursor right one char without crossing line end.
-- Must move inside accept()'s callback: blink v2 applies the edit asynchronously,
-- so reading the cursor right after accept() still gives the pre-accept position.
local function accept_and_move_right(cmp)
	return cmp.accept({
		callback = function()
			local row, col = unpack(vim.api.nvim_win_get_cursor(0))
			if col < #vim.api.nvim_get_current_line() then
				vim.api.nvim_win_set_cursor(0, { row, col + 1 })
			end
		end,
	})
end

require("blink.cmp").setup({
	-- prefer_rust_*：rust 版模糊匹配器缺失时自动退回 Lua（不会因为新机器没编译而报错）
	fuzzy = { implementation = "prefer_rust_with_warning" },
	appearance = { use_nvim_cmp_as_default = true },

	keymap = {
		-- snippet 最先（否则 tabout 会把光标移出占位符），然后 tabout，再补全下一项，最后 Tab 原生
		["<Tab>"] = { "snippet_forward", tabout, "select_next", "fallback" },
		["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
		["<CR>"] = { "accept", "fallback" },
		["<C-CR>"] = { "cancel", "fallback" },
		["<S-CR>"] = { accept_and_move_right, "fallback" },
	},

	signature = {
		enabled = false,
	},

	-- 命令行补全（: / ? 等）：与插入模式一致地自动弹菜单
	cmdline = {
		keymap = { preset = "inherit" },
		completion = { menu = { auto_show = true } },
	},

	completion = {
		trigger = {
			show_on_insert = true,
			show_on_trigger_character = true,
			show_on_keyword = true,
			show_on_backspace = true,
		},
		-- 选中项自动弹出文档（hover 详情），延迟比菜单略长以免抢焦点
		documentation = {
			auto_show = true,
			auto_show_delay_ms = 200,
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
