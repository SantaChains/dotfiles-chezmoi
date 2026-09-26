vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- 远程插件提供者(rplugins):本配置没有 Node/Python/Perl/Ruby 写的远程插件,全部关闭
-- 消除 checkhealth 的 4 条 provider 警告。外部 LSP/工具(pyright 等)不受影响。
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- Scrolloff
local scrolloff = math.floor(vim.o.lines / 2) - 3
vim.opt.scrolloff = scrolloff

-- Must be set before plugins that depend on it (colorizer)
vim.opt.termguicolors = true
vim.opt.hlsearch = false
vim.opt.incsearch = true

require("plugins.init")
require("config.autocmd")
require("config.binds")

-- Colorscheme
vim.cmd.colorscheme("catppuccin")

-- Transparent background fallback
vim.api.nvim_create_augroup("user_colors", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
	group = "user_colors",
	callback = function()
		vim.api.nvim_set_hl(0, "Normal", { ctermbg = "NONE", guibg = "NONE" })
	end,
})

-- Line numbers
vim.opt.cursorline = true
vim.wo.relativenumber = true
vim.wo.number = true

-- Windows
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.o.winborder = "rounded"

-- Sane tab management
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = false

-- Undo management
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false
local undodir = vim.fn.expand("~") .. "/.vim/undodir"
vim.fn.mkdir(undodir, "p")
vim.opt.undodir = undodir
vim.opt.undofile = true

-- Clipboard + Fold
vim.opt.clipboard = "unnamedplus"
vim.opt.foldlevelstart = 99

-- Mouse + autoread
vim.opt.mouse = "a"
vim.opt.autoread = true

-- Nowrap
vim.opt.wrap = false

-- Indent
vim.o.autoindent = true

-- Local project config
vim.o.exrc = true

-- Ignore case
vim.o.ignorecase = true
vim.o.smartcase = true
