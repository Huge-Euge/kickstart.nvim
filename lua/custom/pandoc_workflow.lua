local PANDOC_SCRIPT = 'pandoc_apa_with_citations.sh'
local PDF_VIEWER_CMD = 'zathura'

-- Function to open the PDF viewer only once
local pdf_viewer_open = false
local function open_pdf_viewer(pdf_file)
  if not pdf_viewer_open then
    -- Use vim.fn.system() to execute the command asynchronously in the background
    -- 'nohup' '> /dev/null' and '&' all help the instance of zathura to be disowned by the parent process
    vim.fn.system(string.format('nohup %s %s > /dev/null 2>&1 &', PDF_VIEWER_CMD, vim.fn.shellescape(pdf_file)))
    pdf_viewer_open = true
  end
end

-- Function to run the Pandoc script
local function run_pandoc_and_update()
  -- 1. Get the current file name and the bibliography file name (assuming it's hardcoded or known)
  local input_file = vim.fn.expand '%:p' -- Full path to the current Markdown file
  local pdf_output_file = vim.fn.fnamemodify(input_file, ':r') .. '.pdf'
  local current_buf = vim.api.nvim_get_current_buf()

  -- 2. Construct the full shell command
  local shell_command = string.format('%s %s', PANDOC_SCRIPT, vim.fn.shellescape(input_file))

  vim.cmd 'echo ""'
  vim.cmd 'redraw!'

  print 'Running Pandoc conversion...'

  -- 3. Execute the script asynchronously
  -- Use jobstart for non-blocking execution
  vim.fn.jobstart(shell_command, {
    on_exit = function(jid, code)
      if code == 0 then
        -- 4. If conversion succeeded, update the preview
        print '✅ Conversion complete. Updating preview...'
        open_pdf_viewer(pdf_output_file)
      else
        print '❌ Conversion failed! Check script and LaTeX output.'
      end
    end,
    -- Optional: redirect stdout/stderr to a temporary file for debugging
    stdout = false,
    stderr = false,
  })

  local group_name = 'PandocAutoUpdateGroup_' .. current_buf

  vim.api.nvim_create_augroup(group_name, { clear = true })

  vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
    buffer = current_buf,
    group = group_name,
    callback = function()
      run_pandoc_and_update()
    end,
    desc = 'Run Pandoc on save for this file only',
    once = false,
  })
end

return {
  run_pandoc = run_pandoc_and_update,
}
