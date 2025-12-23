-- Copy current filename to clipboard
--
local function get_filepath()
  local filepath = vim.fn.expand '%:.' -- https://vi.stackexchange.com/a/39795
  vim.fn.setreg('+', filepath) -- write to clipboard
end

vim.keymap.set('n', 'yf', get_filepath, { noremap = true, silent = true })

-- Go to references of the enclosing function (uses Treesitter to find the function node)
vim.keymap.set('n', '<leader>gr', function()
  local function telescope_refs()
    local ok, builtin = pcall(require, 'telescope.builtin')
    if ok and builtin.lsp_references then
      builtin.lsp_references()
    else
      vim.lsp.buf.references()
    end
  end

  local ok, ts_utils = pcall(require, 'nvim-treesitter.ts_utils')
  if not ok then
    telescope_refs()
    return
  end
  local node = ts_utils.get_node_at_cursor()
  if not node then
    telescope_refs()
    return
  end
  while node
    and node:type() ~= 'function_definition'
    and node:type() ~= 'function_declaration'
    and node:type() ~= 'method_definition'
    and node:type() ~= 'function'
    and node:type() ~= 'arrow_function'
    and node:type() ~= 'method' do
    node = node:parent()
  end
  if not node then
    telescope_refs()
    return
  end
  local target = nil
  for child in node:iter_children() do
    local t = child:type()
    if t:find('identifier') or t == 'name' then
      target = child
      break
    end
  end
  if not target then
    telescope_refs()
    return
  end
  local start_row, start_col = target:range()
  vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
  telescope_refs()
end, { desc = 'LSP references of enclosing function' })

-- Toggle Treesitter Context view
vim.keymap.set('n', '<leader>sc', '<cmd>TSContextToggle<CR>', { desc = 'Toggle Treesitter context header' })
