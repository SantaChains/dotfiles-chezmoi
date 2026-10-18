vim.pack.add({
	{ src = "https://github.com/mfussenegger/nvim-dap", name = "dap" },
	{ src = "https://github.com/rcarriga/nvim-dap-ui", name = "dapui" },
	{ src = "https://github.com/theHamsta/nvim-dap-virtual-text", name = "dap-virtual-text" },
	-- nvim-nio 是 dapui 的硬依赖（dapui 内部 require("nio")），不能删
	{ src = "https://github.com/nvim-neotest/nvim-nio", name = "nvim-nio" },
})

-- perf: lazy-load the dap module chain on first keypress instead of at startup
local dap_loaded = false
function DapLoad()
	if dap_loaded then return end
	dap_loaded = true
	local ok, dap = pcall(require, "dap")
	if not ok then return end

	require("nvim-dap-virtual-text").setup()
	require("dapui").setup()

	local dapui = require("dapui")
	dap.listeners.after.event_initialized["dapui_config"] = function()
		dapui.open()
	end
	dap.listeners.before.event_terminated["dapui_config"] = function()
		dapui.close()
	end
	dap.listeners.before.event_exited["dapui_config"] = function()
		dapui.close()
	end
end

-- DAP keymaps
local function dap_map(key, rhs, desc)
	vim.keymap.set("n", key, rhs, { noremap = true, silent = true, desc = desc })
end

dap_map("<F1>", ":lua DapLoad() require'dap'.repl.open()<CR>", "Open DAP REPL")
dap_map("<F11>", ":lua DapLoad() require'dap'.continue()<CR>", "DAP continue")
dap_map("<F12>", ":lua DapLoad() require'dap'.terminate()<CR>", "DAP terminate")
dap_map("<leader>Bb", ":lua DapLoad() require'dap'.toggle_breakpoint()<CR>", "Toggle breakpoint")
dap_map(
	"<leader>Bc",
	":lua DapLoad() require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>",
	"Set condition breakpoint"
)
dap_map(
	"<leader>Bl",
	":lua DapLoad() require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>",
	"Set log point"
)
