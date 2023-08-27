## Minimalist Setup
1. Install `vim-plug` according to [instructions](https://github.com/junegunn/vim-plug)https://github.com/junegunn/vim-plug
2. Run `:PlugInstall`

## `kickstart.nvim`
1. Install [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
2. Use the `~/.config/nvim/lua/custom/plugins/init.lua` custom plugin config for
   - `vim-sneak`
   - `vim-surround`
   - `vim-slime` (Send text to tmux ipython REPL)
3. Set darker color theme by changing that block:
```lua
   {
    -- Theme inspired by Atom
    'navarasu/onedark.nvim',
    priority = 1000,
    config = function()
      require('onedark').setup {style = 'darker'}
      vim.cmd.colorscheme 'onedark'
    end,
  }
```
