-- vim.pack 的 spec 只认 src/name/version/data，没有 build/cond 字段，所以编译只能走
-- PackChanged 钩子。必须在 vim.pack.add 之前注册，否则首次安装时钩子不在场。
vim.api.nvim_create_autocmd("PackChanged", {
	callback = function(ev)
		local name, kind = ev.data.spec.name, ev.data.kind
		if name ~= "telescope-fzf" or (kind ~= "install" and kind ~= "update") then return end
		if vim.fn.executable("cmake") ~= 1 then return end
		if not ev.data.active then vim.cmd.packadd("telescope-fzf") end
		local cwd = ev.data.path
		vim.system({ "cmake", "-S.", "-Bbuild", "-DCMAKE_BUILD_TYPE=Release" }, { cwd = cwd }):wait()
		vim.system({ "cmake", "--build", "build", "--config", "Release" }, { cwd = cwd }):wait()
		vim.system({ "cmake", "--install", "build", "--prefix", "build" }, { cwd = cwd }):wait()
	end,
})

vim.pack.add({
	{ src = "https://github.com/nvim-telescope/telescope.nvim", name = "telescope" },
	{ src = "https://github.com/nvim-lua/plenary.nvim", name = "plenary" },
	{ src = "https://github.com/nvim-telescope/telescope-symbols.nvim", name = "telescope-symbols" },
	{ src = "https://github.com/nvim-telescope/telescope-ui-select.nvim", name = "telescope-ui-select" },
	{ src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim", name = "telescope-fzf" },
	{ src = "https://github.com/nvim-telescope/telescope-file-browser.nvim", name = "telescope-file-browser" },
	{ src = "https://github.com/2kabhishek/nerdy.nvim", name = "telescope-nerdy" },
})

-- perf: telescope 的 require + setup 约占启动 190ms（实测 995 → 803ms）。
-- 改成首次按键才加载，与已有的 DapLoad() 同一套路。键位见 config/binds.lua 的 tb()。
-- 注意：file_browser 的 hijack_netrw 只有在 TelescopeLoad() 之后才生效。
local loaded = false
function TelescopeLoad()
	if loaded then return end
	loaded = true

	local actions = require("telescope.actions")
	require("telescope").setup({
		defaults = {
			file_ignore_patterns = { ".git/", "%.csv", ".venv", ".node_modules", "node_modules", ".svelte-kit", ".vscode" },
		},
		pickers = {
			buffers = {
				show_all_buffers = true,
				mappings = {
					i = {
						["<CR>"] = actions.select_drop,
					},
					n = {
						["<CR>"] = actions.select_drop,
						["d"] = actions.delete_buffer,
					},
				},
			},
			find_files = {
				show_all_buffers = true,
				mappings = {
					i = {
						["<CR>"] = actions.select_drop,
					},
					n = {
						["<CR>"] = actions.select_drop,
					},
				},
			},
			live_grep = {
				additional_args = function()
					return { "--hidden" }
				end,
			},
		},
		extensions = {
			file_browser = {
				theme = "ivy",
				hijack_netrw = true,
			},
			["ui-select"] = {
				require("telescope.themes").get_dropdown({}),
			},
		},
	})

	pcall(require("telescope").load_extension, "fzf")
	require("telescope").load_extension("file_browser")
	require("telescope").load_extension("ui-select")
	require("telescope").load_extension("nerdy")
end
