-- [[ Setting options ]]
local user_home_dir = vim.fn.expand('$HOME') .. '/'
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '
vim.g.have_nerd_font = true
vim.opt.pumheight = 15 -- max number of entries in completion window
vim.opt.guicursor:append('a:blinkon1')
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.showmode = false
vim.opt.breakindent = true
vim.opt.undofile = true
vim.opt.ignorecase = true -- Case-insensitive searching UNLESS \C or capital in search
vim.opt.smartcase = true
vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 250
-- vim.opt.timeoutlen = 300
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = {
    tab = '» ',
    trail = '·',
    nbsp = '␣'
}
vim.opt.inccommand = 'split'
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.breakindent = true

-- [[ Basic Keymaps ]]
vim.opt.hlsearch = true
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, {
    desc = 'Go to previous [D]iagnostic message'
})
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, {
    desc = 'Go to next [D]iagnostic message'
})
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, {
    desc = 'Show diagnostic [E]rror messages'
})
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, {
    desc = 'Open diagnostic [Q]uickfix list'
})

-- window management
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', {
    desc = 'Move focus to the left window'
})
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', {
    desc = 'Move focus to the right window'
})
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', {
    desc = 'Move focus to the lower window'
})
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', {
    desc = 'Move focus to the upper window'
})
vim.keymap.set('n', '<leader>o', 'o<Esc>', {
    desc = 'Insert a newline below the cursor'
})
vim.keymap.set('n', '<leader>O', 'O<Esc>', {
    desc = 'Insert a newline below the cursor'
})
vim.keymap.set('v', 'o', 'ozz', {
    desc = 'Other end of visual selection + center'
})

-- cycle buffers
vim.keymap.set('n', '<S-l>', ':bnext<CR>', {
    noremap = true,
    silent = true
})
vim.keymap.set('n', '<S-h>', ':bprev<CR>', {
    noremap = true,
    silent = true
})

vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

-- [[ Basic Autocommands ]]
-- Highlight when yanking (copying) text
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', {
        clear = true
    }),
    callback = function()
        vim.highlight.on_yank()
    end
})

-- [[ Install `lazy.nvim` plugin manager ]]
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
    local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
    vim.fn.system {
        'git',
        'clone',
        '--filter=blob:none',
        '--branch=stable',
        lazyrepo,
        lazypath
    }
end ---@diagnostic disable-next-line: undefined-field
vim.opt.rtp:prepend(lazypath)

-- [[ Configure and install plugins ]]
require('lazy').setup({
    'tpope/vim-sleuth', -- Detect tabstop and shiftwidth automatically
    -- "gc" to comment visual regions/lines
    {
        'numToStr/Comment.nvim',
        opts = {}
    },
    {
        url = 'https://codeberg.org/andyg/leap.nvim',
        config = function()
            vim.keymap.set({
                'n',
                'x',
                'o'
            }, 's', '<Plug>(leap-forward)')
            vim.keymap.set({
                'n',
                'o'
            }, 'S', '<Plug>(leap-backward)')
            vim.keymap.set({
                'n',
                'x',
                'o'
            }, 'gs', '<Plug>(leap-from-window)')
            require('leap').opts.special_keys.prev_target = ','
            require('leap').opts.special_keys.next_target = ';'
            require('leap').opts.special_keys.prev_group = '<bs>'
            require('leap.user').set_repeat_keys('<cr>', '<bs>')
            require('leap').opts.keys = {
                'S',
                mode = {
                    'n',
                    'x',
                    'o'
                },
                desc = 'Leap backward to'
            }
        end
    },
    {
        'kylechui/nvim-surround',
        version = '*', -- Use for stability; omit to use `main` branch for the latest features
        config = function()
            require('nvim-surround').setup {}
        end
    },
}
)

-- The line beneath this is called `modeline`. See `:help modeline`
