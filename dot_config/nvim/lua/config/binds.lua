-- Keymap function
function Keymap(mode, key, binding, opts)
	local options = { noremap = true, silent = true }
	if opts then
		options = vim.tbl_extend("force", options, opts)
	end
	vim.keymap.set(mode, key, binding, options)
end

Keymap("n", "q:", ":", { desc = "Open command line" }) -- remove nonsense command
Keymap("n", "<leader>bd", function() -- delete buffer
	vim.cmd("bd")
	vim.cmd("echo 'Buffer deleted'")
end, { desc = "Delete buffer" })

for _, bind in ipairs({ "i", "a", "A", "I" }) do
	Keymap("n", bind, function()
		if vim.fn.getline("."):match("^%s*$") then
			return [["_cc]]
		else
			return bind
		end
	end, { expr = true, desc = "Smart insert" })
end

Keymap("i", "<C-BS>", "<C-W>", { desc = "Delete word" }) -- C-Backscpace for whole words
Keymap("i", "jk", "<Esc>", { desc = "Exit insert" }) -- exit insert mode

-- 模仿 VSCode 的 Ctrl+Z 粒度：在词/标点边界埋 undo 断点，这样 u 能逐步退，而不是一整个插入会话一起退。
-- 不动 <CR> 和括号：它们被 mini.pairs 接管着，盖掉会丢掉自动配对行为。
-- 重做仍是 <C-r>，撤销树前后仍是 g- / g+。
for _, key in ipairs({ "<Space>", ",", ".", ";" }) do
	Keymap("i", key, "<C-g>u" .. key, { desc = "Undo break" })
end

Keymap("n", "<leader>d", "<cmd>lua vim.diagnostic.open_float()<CR>", { desc = "Show diagnostics" }) -- Diagnostics for Linter
Keymap("n", "gd", "<cmd>lua vim.lsp.buf.definition()<CR>", { desc = "Goto definition" }) -- Diagnostics for Linter

-- Terminal Keymaps
Keymap("n", "<leader>tj", function() -- open term in new pane
	vim.cmd.vnew()
	vim.cmd.term()
	vim.cmd.startinsert()
end, { desc = "New terminal split" })
Keymap("n", "<leader>tk", function() -- open term in new tab
	vim.cmd.tabnew()
	vim.cmd.term()
	vim.cmd.startinsert()
end, { desc = "New terminal tab" })
Keymap("t", "<C-D>", "<C-\\><C-n>", { desc = "Exit terminal" }) -- escape terminal with c-d

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
end, { desc = "Fuzzy jump" })
Keymap("n", "sS", function()
	require("flash").treesitter()
end, { desc = "Treesitter jump" })
Keymap("n", "<leader>r", function()
	require("flash").remote()
end, { desc = "Remote jump" })
Keymap("n", "<leader>R", function()
	require("flash").treesitter_search()
end, { desc = "Remote treesitter search" })
-- / 搜索进行中按 <C-s> 切换标签模式（search.enabled=true 时用来临时关掉）
Keymap("c", "<C-s>", function()
	require("flash").toggle()
end, { desc = "Toggle flash" })

-- Mini Session Keybinds
Keymap("n", "<leader>qj", function() -- quit and save session local
	require("mini.sessions").write(".session")
	vim.cmd("wqa")
end, { desc = "Write and quit" })

Keymap("n", "<leader>qd", function() -- quit and delete session
	require("mini.sessions").delete(".session")
	vim.cmd("wqa")
end, { desc = "Delete and quit" })

-- Telescope（惰性：首次按键时才 TelescopeLoad()，省约 190ms 启动；重做是 <C-r>，撤销树前后是 g- / g+）
local function tb()
	TelescopeLoad()
	return require("telescope.builtin")
end

Keymap("n", "<leader>ff", function()
	tb().find_files({ hidden = true })
end, { desc = "Find files" })

Keymap("n", "<space>fn", function()
	TelescopeLoad()
	local full_path = vim.api.nvim_buf_get_name(0)
	local dir = vim.fn.fnamemodify(full_path, ":h")
	require("telescope").extensions.file_browser.file_browser({
		path = dir,
	})
end, { desc = "Browse files" })

Keymap("n", "<space>fs", function() -- select sessions
	MiniSessions.select()
end, { desc = "Select session" })

Keymap("n", "<space>fd", function() -- select sessions
	MiniSessions.select("delete")
end, { desc = "Delete session" })

Keymap("n", "<leader>fg", function()
	tb().live_grep({ hidden = true })
end, { desc = "Grep project" })

Keymap("n", "<leader>fb", function()
	tb().buffers({ show_all_buffers = true })
end, { desc = "List buffers" })

-- Tab binds：<C-T> 前缀已由 config/hydra.lua 的 Tabs hydra 接管

-- Buffer navigation
Keymap("n", "L", "<cmd>bnext<cr>", { desc = "Next buffer" })
Keymap("n", "H", "<cmd>bprevious<cr>", { desc = "Prev buffer" })

-- Extra telescope
Keymap("n", "<leader>sb", function()
	tb().current_buffer_fuzzy_find({
		sorting_strategy = "ascending",
		prompt_position = "top",
	})
end, { desc = "Search buffer" })
Keymap("n", "<leader>cx", function()
	TelescopeLoad()
	vim.cmd("Telescope diagnostics")
end, { desc = "List diagnostics" })

-- LSP native (no Lspsaga dependency)
Keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", { desc = "Show hover" })
Keymap("n", "cd", function()
	TelescopeLoad()
	vim.cmd("Telescope lsp_definitions")
end, { desc = "List definitions" })
Keymap("n", "cr", function()
	TelescopeLoad()
	vim.cmd("Telescope lsp_references")
end, { desc = "List references" })
Keymap("n", "<C-j>", function()
	TelescopeLoad()
	vim.cmd("Telescope lsp_document_symbols")
end, { desc = "List symbols" })
Keymap("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", { desc = "Show signature" })
Keymap("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", { desc = "Run code action" })
Keymap("n", "<leader>cr", "<cmd>lua vim.lsp.buf.rename()<CR>", { desc = "Rename symbol" })
Keymap("n", "<leader>ci", function()
	TelescopeLoad()
	vim.cmd("Telescope lsp_implementations")
end, { desc = "List implementations" })
Keymap("n", "<leader>D", function()
	TelescopeLoad()
	vim.cmd("Telescope lsp_type_definitions")
end, { desc = "List type definitions" })
Keymap("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", { desc = "Goto implementation" })
Keymap("n", "<leader>cn", "<cmd>lua vim.diagnostic.goto_next()<CR>", { desc = "Next diagnostic" })
Keymap("n", "<leader>cp", "<cmd>lua vim.diagnostic.goto_prev()<CR>", { desc = "Prev diagnostic" })
