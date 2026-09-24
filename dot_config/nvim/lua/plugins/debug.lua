vim.pack.add({
	{ src = "https://github.com/mfussenegger/nvim-dap", name = "dap" },
	{ src = "https://github.com/leoluz/nvim-dap-go", name = "dap-go" },
	{ src = "https://github.com/rcarriga/nvim-dap-ui", name = "dapui" },
	{ src = "https://github.com/theHamsta/nvim-dap-virtual-text", name = "dap-virtual-text" },
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
	require("dap-go").setup()
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
local opts = { noremap = true, silent = true }
vim.keymap.set("n", "<F1>", ":lua DapLoad() require'dap'.repl.open()<CR>", opts)
vim.keymap.set("n", "<F11>", ":lua DapLoad() require'dap'.continue()<CR>", opts)
vim.keymap.set("n", "<F12>", ":lua DapLoad() require'dap'.terminate()<CR>", opts)
vim.keymap.set("n", "<leader>b", ":lua DapLoad() require'dap'.toggle_breakpoint()<CR>", opts)
vim.keymap.set("n", "<leader>B", ":lua DapLoad() require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>", opts)
vim.keymap.set("n", "<leader>lp", ":lua DapLoad() require'dap'.set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>", opts)
vim.keymap.set("n", "<leader>dt", ":lua DapLoad() require'dap-go'.debug_test()<CR>", opts)
