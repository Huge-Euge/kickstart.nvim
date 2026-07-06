vim.api.nvim_create_user_command('Roll', function(opts)
  -- 1. Get the argument string (e.g., "2d20 + 1d4 + 5")
  local input = opts.args

  -- 2. Remove all spaces to make parsing easier
  local clean_input = input:gsub('%s+', '')

  local total = 0
  local details = {}

  -- Seed the random number generator
  math.randomseed(os.time())

  -- 3. Split the string by the '+' symbol and iterate over each part
  for part in string.gmatch(clean_input, '[^+]+') do
    -- Check if this part is a die roll (e.g., "2d20")
    -- Pattern: digits, followed by 'd', followed by digits
    local count, faces = part:match '(%d+)d(%d+)'

    if count and faces then
      -- It is a die roll
      local sub_total = 0
      local rolls = {}

      for _ = 1, tonumber(count) do
        local roll = math.random(1, tonumber(faces))
        table.insert(rolls, roll)
        sub_total = sub_total + roll
      end

      total = total + sub_total
      table.insert(details, string.format('%sd%s(%s)', count, faces, table.concat(rolls, ',')))
    else
      -- It is likely a static number (e.g., "5")
      local num = tonumber(part)
      if num then
        total = total + num
        table.insert(details, tostring(num))
      end
    end
  end

  -- 4. Output the result
  -- Format: "Rolled: 25 [2d20(10,5), 1d4(4), 6]"
  print(string.format('Rolled: %d  [%s]', total, table.concat(details, ' + ')))
end, { nargs = '+' }) -- 'nargs = "+"' requires at least one argument

vim.api.nvim_create_user_command('Choose', function(opts)
  -- 1. Get the range of the visual selection (1-based indices)
  local start_line = opts.line1
  local end_line = opts.line2

  -- 2. Pick a random number between start and end
  math.randomseed(os.time())
  local winner_row = math.random(start_line, end_line)

  -- 3. Get the content of that specific line
  -- nvim_buf_get_lines uses 0-based indexing, so we subtract 1
  local lines = vim.api.nvim_buf_get_lines(0, winner_row - 1, winner_row, false)
  local winner_text = lines[1]

  -- 4. Print the winner
  print('Selected: ' .. winner_text)
end, { range = true }) -- 'range = true' allows it to accept visual selections
