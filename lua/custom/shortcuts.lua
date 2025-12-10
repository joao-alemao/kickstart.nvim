-- Copy current filename to clipboard
--
local function get_filepath()
  local filepath = vim.fn.expand '%:.' -- https://vi.stackexchange.com/a/39795
  vim.fn.setreg('+', filepath) -- write to clipboard
end

vim.keymap.set('n', 'yf', get_filepath, { noremap = true, silent = true })
