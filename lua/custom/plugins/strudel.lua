return {
  'gruvw/strudel.nvim',
  build = 'npm ci',
  config = function()
    local strudel = require 'strudel'

    strudel.setup()

    local launch_toggle = function()
      if strudel.is_launched() then
        strudel.toggle()
      else
        strudel.launch()
        strudel.execute()
      end
    end

    vim.api.nvim_create_autocmd('BufReadPost', {
      pattern = { '*.str', '*.std' },
      desc = 'Strudel-Related keybinds on .str files',
      callback = function()
        vim.keymap.set('n', '<leader>T', launch_toggle, { buffer = true, desc = 'STRUDEL: Execute Strudel' })
        vim.keymap.set('n', '<leader>u', strudel.update, { buffer = true, desc = 'STRUDEL: Update Strudel' })
      end,
    })
  end,
}
