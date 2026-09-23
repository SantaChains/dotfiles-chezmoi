# NVIM

chezmoi-managed Neovim config. Target: `~/.config/nvim`.

Requires Neovim 0.11+ (tested on 0.12.5). Uses built-in `vim.pack` plugin manager.

## Install

```powershell
chezmoi apply
```

First run will auto-install all plugins. Startup log shows `vim.pack: Installing plugins` — wait for it.

## Requirements

- Neovim >= 0.11
- git (clone plugins)
- cmake (optional, only needed to build telescope-fzf-native C binary; if absent the config skips fzf-native and Telescope falls back to its Lua sorter)
- ripgrep (`rg`) — Telescope live_grep backend
- fd — Telescope find_files preferred backend
- A Nerd Font — lualine icons + noice rendering

## Structure

```
nvim/
├── init.lua                       entry point: options, plugins.init, config, colorscheme
└── lua/
    ├── config/
    │   ├── autocmd.lua            git fetch on VimEnter, cursorline toggle, autosave notifications,
    │                              InsertEnter center-cursor, Go organize-imports, LSP reference highlight
    │   └── binds.lua              Keymap() helper + all keybindings
    └── plugins/
        ├── init.lua               auto-loader: walks plugins/**/*.lua (except init.lua itself)
        ├── debug.lua              dap + dap-go + dapui + dap-virtual-text + nvim-nio + keymaps
        ├── completion/
        │   ├── lspconfig.lua      vim.lsp.config() servers, blink.cmp, lazydev on FileType=lua
        │   ├── conform.lua        formatters_by_ft, format_on_save, nvim-lint, diagnostic virtual_text
        │   └── treesitter.lua     highlight + indent + 16 languages
        ├── ui/
        │   ├── carbonfox.lua      nightfox carbonfox variant + transparent + vimade fade
        │   ├── colorizer.lua      #hex / rgb() / hsl() 实时颜色高亮
        │   ├── lualine.lua        mode + macro indicator + branch/diagnostics + ctime
        │   └── noice.lua          cmdline view + notify + mini view
        └── utils/
            ├── telescope.lua       fuzzy finder + fzf-native(cmake cond) + file_browser + ui-select
            ├── mini.lua           pairs, ai, cursorword, indentscope, trailspace, sessions,
            │                      surround, move, icons, animate
            └── convenience.lua    auto-save + remember + scrollEOF + undotree keymap
```

## Keybinds

Leader is `<Space>`. Localleader is `,`.

### Navigation

| Bind           | What                                           |
|----------------|------------------------------------------------|
| `<leader>ff`   | Telescope find_files (hidden)                  |
| `<leader>fg`   | Telescope live_grep (hidden)                   |
| `<leader>fb`   | Telescope buffers                              |
| `<leader>fn`   | Telescope file_browser at current file's dir   |
| `<leader>sb`   | Telescope current_buffer_fuzzy_find (top-down) |
| `<leader>cx`   | Telescope diagnostics (workspace)              |
| `H` / `L`      | Previous / next buffer                         |
| `<C-t>h/l/j/q` | Tab previous / next / new / close              |
| `<leader>bd`   | Delete buffer                                  |

### LSP

| Bind                        | What                        |
|-----------------------------|-----------------------------|
| `K`                         | Hover doc                   |
| `gd`                        | Go to definition            |
| `cd`                        | Telescope definitions       |
| `cr`                        | Telescope references        |
| `gi`                        | Go to implementation        |
| `<leader>ci`                | Telescope implementations   |
| `<leader>D`                 | Telescope type definitions  |
| `<C-j>`                     | Telescope document symbols  |
| `<C-k>`                     | Signature help              |
| `<leader>ca`                | Code action                 |
| `<leader>cr`                | Rename                      |
| `<leader>cp` / `<leader>cn` | Diagnostic goto next / prev |
| `<leader>d`                 | Diagnostic float            |

### Flash (no leader)

| Bind        | What                                      |
|-------------|-------------------------------------------|
| `ss`        | fuzzily jump anywhere (backdrop dimmed)   |
| `S`         | treesitter node jump                      |
| `<leader>r` | remote flash (operate from remote target) |
| `<leader>R` | treesitter search                         |

### Session

手动命令由 mini.sessions 提供（`<leader>qj/qd` 操作 cwd 的 `.session` 文件），自动保存/恢复由 remember.nvim 处理。两者不冲突：mini.sessions 的 `autoread`/`autowrite` 已关闭，避免 setup 时重复扫描 session 文件并报 INFO 消息。

| Bind         | What                                             |
|--------------|--------------------------------------------------|
| `<leader>qj` | Save session + `wqa` (creates `.session` in cwd) |
| `<leader>qd` | Delete session + `wqa`                           |
| `<leader>fs` | Pick session to restore                          |
| `<leader>fd` | Pick session to delete                           |

### Terminal

| Bind         | What                         |
|--------------|------------------------------|
| `<leader>tj` | Terminal in new vsplit       |
| `<leader>tk` | Terminal in new tab          |
| `<C-D>`      | Exit terminal mode to normal |

### Edit conveniences

| Bind                                | What                                     |
|-------------------------------------|------------------------------------------|
| `<C-BS>`                            | Delete whole word backward (insert mode) |
| `i` / `a` / `A` / `I` on blank line | Uses blackhole register then `cc`        |
| `ss` / `S`                          | Flash (see above)                        |

### DAP (when dap installed)

| Bind         | What                   |
|--------------|------------------------|
| `<F1>`       | Open REPL              |
| `<F11>`      | Continue               |
| `<F12>`      | Terminate              |
| `<leader>b`  | Toggle breakpoint      |
| `<leader>B`  | Conditional breakpoint |
| `<leader>lp` | Log point              |
| `<leader>dt` | dap-go debug_test      |

## LSP servers configured

via `vim.lsp.config()` / `vim.lsp.enable()`:

- lua_ls — LuaJIT runtime, 3rd-party check disabled
- ts_ls
- pylsp
- cssls
- svelte
- rust_analyzer — runs through `rustup run stable`
- gopls — gofumpt on, debounce 150ms
- golangci_lint_ls
- yamlls — GitHub workflow schema
- hls — cabalfmt + ormolu
- ltex — `missing-fields` diagnostic disabled
- emmet_language_server

## Formatters (conform)

| ft                           | Formatter |
|------------------------------|-----------|
| lua                          | stylua    |
| js/ts/tsx/svelte/html/md/css | prettier  |
| python                       | black     |
| rust                         | rustfmt   |

`format_on_save = true`, `undojoin = true`.

## Notes

- Colorscheme: nightfox carbonfox variant (near-black high-contrast, IBM Carbon palette). Transparent background — both via nightfox `options.transparent = true` and a ColorScheme autocmd that forces `Normal guibg=NONE` as fallback.
- undodir: `~/.vim/undodir` (cross-platform via `expand("~")`), auto-created with `mkdir(path, "p")`.
- telescope-fzf-native: has a `cond = function() return vim.fn.executable("cmake") == 1 end end`. No cmake → auto-skipped. Install cmake → next startup builds C binary for fast fuzzy sort.
- `nvim-nio`: transitive dep of dapui 0.7+, included explicitly so `vim.pack` resolves it.
- `vim.tbl_flatten` deprecation warning at startup: emitted by a plugin (telescope or mason), not this config.
