-- Keymap function
function Keymap(mode, key, binding, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.keymap.set(mode, key, binding, options)
end

Keymap("n", "q:", ":") -- remove nonsense command
Keymap("n", "<leader>bd", function() -- delete buffer
	vim.cmd("bd")
	vim.cmd("echo 'Buffer deleted'")
end)

for _, bind in ipairs({ "i", "a", "A", "I" }) do
	Keymap("n", bind, function()
		if vim.fn.getline("."):match("^%s*$") then
			return [["_cc]]
		else
			return bind
		end
	end, { expr = true })
end

Keymap("i", "<C-BS>", "<C-W>") -- C-Backscpace for whole words

Keymap("n", "<leader>d", "<cmd>lua vim.diagnostic.open_float()<CR>") -- Diagnostics for Linter
Keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>") -- Diagnostics for Linter

-- Terminal Keymaps
Keymap("n", "<leader>tj", function() -- open term in new pane
	vim.cmd.vnew()
	vim.cmd.term()
	vim.cmd.startinsert()
end)
Keymap("n", "<leader>tk", function() -- open term in new tab
	vim.cmd.tabnew()
	vim.cmd.term()
	vim.cmd.startinsert()
end)
Keymap("t", "<C-D>", "<C-\\><C-n>") -- escape terminal with c-d

-- Flash keymaps
Keymap("n", "ss", function()
	require("flash").jump({
		search = {
			mode = "fuzzy",
		},
		highlight = {
			backdrop = true,
		},
	})
end)
Keymap("n", "S", function()
	require("flash").treesitter()
end)
Keymap("n", "<leader>r", function()
	require("flash").remote()
end)
Keymap("n", "<leader>R", function()
	require("flash").treesitter_search()
end)

-- Mini Session Keybinds
Keymap("n", "<leader>qj", function() -- quit and save session local
	require("mini.sessions").write(".session")
	vim.cmd("wqa")
end)

Keymap("n", "<leader>qd", function() -- quit and delete session
	require("mini.sessions").delete(".session")
	vim.cmd("wqa")
end)

-- Telescope

local builtin = require("telescope.builtin")

Keymap("n", "<leader>ff", function()
	builtin.find_files({ hidden = true })
end)

Keymap("n", "<space>fn", function()
	local full_path = vim.api.nvim_buf_get_name(0)
	local dir = vim.fn.fnamemodify(full_path, ":h")
	require("telescope").extensions.file_browser.file_browser({
		path = dir,
	})
end)

Keymap("n", "<space>fs", function() -- select sessions
	MiniSessions.select()
end)

Keymap("n", "<space>fd", function() -- select sessions
	MiniSessions.select("delete")
end)

Keymap("n", "<leader>fg", function()
	builtin.live_grep({ hidden = true })
end)

Keymap("n", "<leader>fb", function()
	builtin.buffers({ show_all_buffers = true })
end)

-- Tab binds
Keymap("n", "<C-T>l", function()
	vim.cmd("tabnext")
end)

Keymap("n", "<C-T>h", function()
	vim.cmd("tabprevious")
end)

Keymap("n", "<C-T>j", function()
	vim.cmd("tabnew")
end)

Keymap("n", "<C-T>q", function()
	vim.cmd("tabclose")
end)
