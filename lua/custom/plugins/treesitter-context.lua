return {
  {
    'nvim-treesitter/nvim-treesitter-context',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {
      enable = false,
      max_lines = 3, -- keep context header small; adjust as needed
    },
  },
}

