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
				-- Extract digits only: rev-list fails (no upstream) and prints a fatal message
				local count = tonumber(vim.fn.system("git rev-list --count HEAD..@{u}"):match("%d+"))
				if count and count > 0 then
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

-- Go: organize imports on save
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = { "*.go" },
	callback = function()
		local params = vim.lsp.util.make_range_params(nil, vim.lsp.util._get_offset_encoding())
		params.context = { only = { "source.organizeImports" } }
		local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
		for _, res in pairs(result or {}) do
			for _, r in pairs(res.result or {}) do
				if r.edit then
					vim.lsp.util.apply_workspace_edit(r.edit, vim.lsp.util._get_offset_encoding())
				else
					vim.lsp.buf.execute_command(r.command)
				end
			end
		end
	end,
})

-- LSP: highlight references on CursorHold, clear on CursorMoved
vim.api.nvim_create_autocmd("LspAttach", {
	callback = function(args)
		local client = vim.lsp.get_client_by_id(args.data.client_id)
		if client and client.server_capabilities.documentHighlightProvider then
			local grp = vim.api.nvim_create_augroup("lsp_document_highlight_" .. args.buf, { clear = true })
			vim.api.nvim_create_autocmd("CursorHold", {
				buffer = args.buf,
				group = grp,
				callback = function()
					vim.lsp.buf.document_highlight()
				end,
			})
			vim.api.nvim_create_autocmd("CursorMoved", {
				buffer = args.buf,
				group = grp,
				callback = function()
					vim.lsp.buf.clear_references()
				end,
			})
		end
	end,
})
