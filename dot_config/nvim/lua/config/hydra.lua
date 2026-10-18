vim.pack.add({ { src = "https://github.com/nvimtools/hydra.nvim", name = "hydra" } })

-- hydra.nvim 1.0.3 仍在用 vim.validate({...}) 旧签名（上游 PR #72 至今未合并），
-- nvim 0.12 每次启动刷 4 条 deprecated。这里把旧签名桥到新签名；
-- hydra 加载前就位即可，等上游修好这整段可删。
local _validate = vim.validate
vim.validate = function(a, b, c, d, e)
	if type(a) == "table" and b == nil then
		for name, spec in pairs(a) do
			_validate(name, spec[1], spec[2], spec[3], spec[4])
		end
		return
	end
	return _validate(a, b, c, d, e)
end

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
