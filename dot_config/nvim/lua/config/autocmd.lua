-- Autocommand to check git status
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		-- Verify if the current directory is a git repo (cross-platform: /dev/null vs NUL)
		local null = vim.fn.has("win32") == 1 and "2>NUL" or ">/dev/null 2>&1"
		local is_git = os.execute("git rev-parse --is-inside-work-tree " .. null)
		if is_git ~= 0 then
			return
		end
		-- Perform an async fetch to avoid startup lag
		vim.fn.jobstart("git fetch", {
			on_exit = function()
				-- Get the number of commits the remote is ahead of local HEAD
				local count = vim.fn.system("git rev-list --count HEAD..@{u}"):gsub("%s+", "")
				if count ~= "" and tonumber(count) > 0 then
					vim.schedule(function()
						vim.notify(
							"󰊢 " .. count .. " new commit(s) available on remote.",
							vim.log.levels.INFO,
							{ title = "Git Status", icon = "󰊢" }
						)
					end)
				end
			end,
		})
	end,
})

-- vim.api.nvim_create_autocmd("FileType", {
-- 	pattern = { "svelte" },
-- 	callback = function()
-- 		vim.treesitter.start()
-- 	end,
-- })

local cursorline_group = vim.api.nvim_create_augroup("CursorLineControl", { clear = true })

vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
	group = cursorline_group,
	callback = function()
		vim.opt_local.cursorline = true
	end,
})

vim.api.nvim_create_autocmd({ "WinLeave" }, {
	group = cursorline_group,
	callback = function()
		vim.opt_local.cursorline = false
	end,
})

local group = vim.api.nvim_create_augroup("autosave", {})

-- Notification to say when a file is saved by autosave
vim.api.nvim_create_autocmd("User", {
	pattern = "AutoSaveWritePre",
	group = group,
	callback = function(opts)
		if opts.data.saved_buffer ~= nil then
			local filename = vim.fn.expand("%:t")
			print("Saved '" .. filename .. "' at " .. vim.fn.strftime("%H:%M:%S"))
		end
	end,
})

-- Notification when enabling/disabling autosave for a buffer
vim.api.nvim_create_autocmd("User", {
	pattern = "AutoSaveEnable",
	group = group,
	callback = function()
		print("AutoSave enabled")
	end,
})

vim.api.nvim_create_autocmd("User", {
	pattern = "AutoSaveDisable",
	group = group,
	callback = function()
		print("AutoSave disabled")
	end,
})

-- Center cursor on screen whenver insert mode is activated
-- (Stops fucky wucky shit with scrollEOF)
vim.api.nvim_create_autocmd("InsertEnter", {
	callback = function()
		vim.cmd("normal! zz")
	end,
})
