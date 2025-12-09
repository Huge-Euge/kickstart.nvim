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
  local file_dir = vim.fn.expand '%:p:h' -- Directory of the md file
  local file_name = vim.fn.expand '%:t' -- Just the filename
  local pdf_output_file = vim.fn.fnamemodify(input_file, ':r') .. '.pdf'
  local current_buf = vim.api.nvim_get_current_buf()

  if vim.fn.executable(PANDOC_SCRIPT) == 0 then
    print 'Error: Pandoc script not found in PATH.'
    return
  end

  -- 2. Construct the full shell command
  local shell_command = string.format('%s %s', PANDOC_SCRIPT, vim.fn.shellescape(input_file))

  vim.cmd 'echo ""'
  vim.cmd 'redraw!'

  print 'Running Pandoc conversion...'

  local log_file = vim.fn.tempname()

  -- Create the shell command string
  -- 1st: cd into file_dir, && if that worked,
  -- 2nd: PANDOC_SCRIPT on file_name
  local shell_command = string.format('(cd %s && %s %s) > %s 2>&1', vim.fn.shellescape(file_dir), PANDOC_SCRIPT, vim.fn.shellescape(file_name), log_file)

  -- 3. Execute the script asynchronously
  -- Use jobstart for non-blocking execution
  vim.fn.jobstart(shell_command, {
    on_exit = function(jid, code)
      vim.cmd 'echo ""'
      vim.cmd 'redraw!'

      if code == 0 then
        print '✅ Conversion complete. Updating preview...'
        open_pdf_viewer(pdf_output_file)
      else
        print '❌ Conversion failed! Check script and LaTeX output.'
        -- Read and print the error log
        local errors = vim.fn.readfile(log_file)
        for _, line in ipairs(errors) do
          print(line)
        end
      end
      vim.fn.delete(log_file)
    end,
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
