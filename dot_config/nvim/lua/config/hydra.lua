vim.pack.add({ { src = "https://github.com/nvimtools/hydra.nvim", name = "hydra" } })

-- noice 接管了 cmdline，hydra 默认的 cmdline 提示看不见，统一走浮动窗口
local Hydra = require("hydra")
Hydra.setup({
	hint = {
		type = "window",
		position = "bottom",
		float_opts = { border = "rounded" },
	},
})

-- <C-T> 标签子模式：按 <C-T>l 进子模式后，h/j/l/q 不用再按前缀。
-- 四条入口映射由 hydra 生成（原在 config/binds.lua）。
local heads = {
	{ "j", "<cmd>tabnew<cr>", { desc = "New tab" } },
	{ "l", "<cmd>tabnext<cr>", { desc = "Next tab" } },
	{ "h", "<cmd>tabprevious<cr>", { desc = "Prev tab" } },
	{ "q", "<cmd>tabclose<cr>", { desc = "Close tab" } },
}

Hydra({
	name = "Tabs",
	mode = "n",
	body = "<C-T>",
	heads = heads,
})

-- hydra 生成的 <C-T>x 入口映射不带 desc，mini.clue 里会显示空白，这里补上
if _G.MiniClue then
	for _, head in ipairs(heads) do
		MiniClue.set_mapping_desc("n", "<C-T>" .. head[1], head[3].desc)
	end
end
