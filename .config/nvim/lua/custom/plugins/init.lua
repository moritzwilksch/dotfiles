-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
        {'justinmk/vim-sneak'},
        {
              "kylechui/nvim-surround",
              version = "*", -- Use for stability; omit to use `main` branch for the latest features
              event = "VeryLazy",
              config = function()
                  require("nvim-surround").setup({
              -- Configuration here, or leave empty to use defaults
                  })
              end
        },
        {
                'jpalardy/vim-slime',
                config = function()
                        vim.cmd.xmap('<leader>s', '<Plug>SlimeRegionSend')
                        vim.cmd.vmap('<leader>s', '<Plug>SlimeRegionSend')
                        vim.cmd.nmap('<leader>s', '<Plug>SlimeParagraphSend')
                        vim.cmd.nmap('<leader>s', '<Plug>SlimeSendCell')
                        vim.g.slime_target = "tmux"
                        vim.g.slime_paste_file = "/home/moritz/.slime_paste"
                        vim.g.slime_cell_delimiter = "# %%"
                        vim.g.slime_default_config = {socket_name= "default", target_pane="1"}
                        vim.g.slime_bracketed_paste = 1
                        vim.g.slime_dont_ask_default = 1
                end,
        }
}
