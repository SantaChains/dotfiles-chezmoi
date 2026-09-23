# NVIM For Voidfiles

Built using vim.pack and lots of mini plugins

## Installation

This config uses nix-wrapper-modules to forego needing to install dotfiles at all. This results in a cleaner,
more consistent experience across systems, in order to make it available to a dendritic nix environment.

### Trying

To try the config:

```bash
nix run git+https://git.voidarc.co.uk/voidarc/nvim
```

### Installing

Add the input to your flake:

```nix
{
    inputs = {
        nvim-voidarc.url = "git+https://git.voidarc.co.uk/voidarc/nvim"
    }
}
```

And then add the package to your system config:

```nix
inputs.nvim-voidarc.packages.${stdenv.hostPlatform.system}.default
```

There is also a `minimal` output that doesn't install any lsps, only installing required pacakges so that the plugins
function correctly (ripgrep, luarocks, luajit, etc)

### Editing and Developing

You can clone this repo to `.config/nvim`, and then use a nix-shell to use a local config instead of the provided
bundled binary. This is useful if you want to make modifications to the config and don't want to wait for a push
and rebuild to see your changes. This is the only reason I kept the main config in lua, other than having to rewrite
it in general.

## Usage

This is a very esoteric config. I am quite opinionated, so there isn't any nice stuff like a homepage or which-keys.
Instead, there is efficiency. This is the minimum amount of pacakges required in order to support full functionality,
while also being highly extensible and adaptable to any programming language that I could want to program in.

### Keybinds

All keybinds can be found in the `lua/config/binds.lua` file, with a few exceptions. The `Keybind` function is a shorthand for the vim api.
All default vim bindings remain untouched, with almost all of the set binds having a leader prefix.

The leader key is space, configurable at the top of the `init.lua` file. When referring to the leader key, assume I mean space.

#### Navigation

- \<leader\>ff - Open Telescope fuzzy finder
- \<leader\>fn - Open Telescope file manager
- \<leader\>fg - Telescope live grep (only works in git repos afaik)
- \<leader\>fb - Telescope list of open buffers
- \<leader\>bd - Delete focused buffer

If a file is open, Telescope is configured to jump to the pane/tab where that file is open, rather than open it in the current pane.
This allows for a more consistent editing experience, such as having seperate tabs for backend and frontend files.

- \<C-t\>l - Next tab
- \<C-t\>h - Previous tab
- \<C-t\>j - New tab to the right
- \<C-t\>q - Close tab (Keeps buffers open)

Instead of using \<C-t\>j, I prefer to find the file in Telescope and use <C-t>, which opens the file in a new tab. This ovverides the
regular Telescope behaviour of jumping to the relevant pane, which only applies to enter. Similarly, <C-v> in Telescope opens the
selected file in a split to the right in the current tab. All <C-w> binds for navigating windows remain unchanged

#### Editing

- \<leader\>d - Open vim.lsp.diagnostic float menu
- gd - Go to definition of function
- ss - Open flash.nvim menu

Flash nvim has no leader key for ease of access. Non-text based flash functions are available according to the binds, but I don't use them.

#### Session management

- \<leader\>qj - Save session and exit
- \<leader\>qd - Delete session and exit

Both of these commands run `wqa`, meaning that even when deleting a session no data is ever lost (not that autosave isn't on by default lol).
When opening nvim in a folder with a `.session` file, the session will automatically be restored, including window layout. For more info, see
the mini.sessions documentation. Sessions autosave, but it is faster to use the save keybind than quit all windows one by one or run `:wqa`
