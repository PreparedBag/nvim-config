return {
    'preservim/nerdtree',
    init = function()
        vim.g.NERDTreeQuitOnOpen = 1
        vim.g.NERDTreeMinimalUI = 1

        vim.cmd([[
            autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
            autocmd BufEnter * if winnr() == winnr('h') && bufname('#') =~ 'NERD_tree_\d\+' && bufname('%') !~ 'NERD_tree_\d\+' && winnr('$') > 1 |
            \ let buf=bufnr() | buffer# | execute "normal! \<C-W>w" | execute 'buffer'.buf | endif
            ]])

        vim.api.nvim_create_autocmd('FileType', {
            pattern = 'nerdtree',
            callback = function()
                vim.keymap.set('n', 't', '<Nop>', { buffer = true, noremap = true, silent = true })
            end,
        })
    end,
    keys = {
        {
            '<leader>N',
            function()
                if vim.bo.filetype == 'nerdtree' then
                    vim.cmd('wincmd p')
                else
                    vim.cmd('NERDTreeFocus')
                end
            end,
            desc = 'Focus NERDTree or return to previous buffer',
        },
        { '<leader>n', ':NERDTreeToggle<CR>', desc = 'Toggle NERDTree' },
    },
}
