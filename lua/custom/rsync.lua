-- Rsync-on-save automation and destination switching
-- Adapts paths to the current user's home directory

local uv = vim.uv or vim.loop
local home = uv.os_homedir()

local project_root = home .. '/code/veo/sunstone'
local rsync_rsh_helper = home .. '/code/veo/sunstone/lab/tools/workspace/rsync_k8s_helper.sh'

-- Command to rsync to onprem
_G.onprem_sync_command = {
  'rsync',
  '-av',
  '--verbose',
  '--stats',
  '--progress',
  '--rsh=' .. rsync_rsh_helper,
  '--exclude',
  '__pycache__/',
  '--exclude',
  '*.pyc',
  '--exclude',
  '*.csv',
  '--exclude',
  '*.jpg',
  '--exclude',
  '.pytest_cache/',
  '--exclude',
  '.neptune/',
  '--exclude',
  '.git/lfs/',
  '--exclude',
  '.metaflow/',
  project_root,
  'jcta-workspace-0:/root/workspace/jcta/',
}

-- Command to rsync to EC2
_G.ec2_sync_command = {
  'rsync',
  '-av',
  '--verbose',
  '--stats',
  '--progress',
  '--exclude',
  '__pycache__/',
  '--exclude',
  '*.pyc',
  '--exclude',
  '*.csv',
  '--exclude',
  '*.jpg',
  '--exclude',
  '.pytest_cache/',
  '--exclude',
  '.neptune/',
  '--exclude',
  '.git/lfs/',
  '--exclude',
  '.metaflow/',
  project_root,
  'aws-ec2-g52xl:/home/ubuntu',
}

-- Default to rsync to onprem
_G.rsync_command = _G.onprem_sync_command

-- Switch rsync destination to BOTH (onprem + ec2)
vim.api.nvim_create_user_command('Both', function()
  _G.rsync_command = { _G.onprem_sync_command, _G.ec2_sync_command }
  vim.api.nvim_echo({ { 'Rsync destination set to BOTH (onprem + ec2)', 'None' } }, false, {})
end, {})

-- Switch rsync destination to EC2
vim.api.nvim_create_user_command('Ec2', function()
  _G.rsync_command = _G.ec2_sync_command
  vim.api.nvim_echo({ { 'Rsync destination set to EC2', 'None' } }, false, {})
end, {})

-- Switch rsync destination to onprem
vim.api.nvim_create_user_command('Onprem', function()
  _G.rsync_command = _G.onprem_sync_command
  vim.api.nvim_echo({ { 'Rsync destination set to Onprem', 'None' } }, false, {})
end, {})

-- Shared runner used by autocmds and manual commands
local function run_rsync()
  local sys = vim.system or function(cmd, opts, on_exit)
    -- Fallback for older Neovim: use jobstart if vim.system is unavailable
    local job_id = vim.fn.jobstart(cmd, {
      stdout_buffered = true,
      stderr_buffered = true,
      on_stdout = function(_, _)
        if opts and opts.stdout then
          opts.stdout()
        end
      end,
      on_stderr = function(_, _)
        if opts and opts.stderr then
          opts.stderr()
        end
      end,
      on_exit = function(_, _)
        if on_exit then
          on_exit()
        end
      end,
    })
    return job_id
  end

  local cmds
  if type(_G.rsync_command[1]) == 'string' then
    cmds = { _G.rsync_command }
  else
    cmds = _G.rsync_command
  end

  local function run_next(index)
    local cmd = cmds[index]
    if not cmd then
      vim.schedule(function()
        vim.api.nvim_echo({ { 'synced successfully', 'None' } }, false, {})
      end)
      return
    end
    sys(cmd, {
      stdout = function() end,
      stderr = function() end,
    }, function()
      run_next(index + 1)
    end)
  end

  run_next(1)
end

-- Manage rsync-on-save enable/disable
local rsync_augroup = vim.api.nvim_create_augroup('custom-rsync-on-save', { clear = true })
_G.rsync_on_save_enabled = true

local function enable_rsync_autocmd()
  vim.api.nvim_clear_autocmds { group = rsync_augroup }
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = rsync_augroup,
    pattern = project_root .. '/*',
    callback = function()
      run_rsync()
    end,
  })
end

local function disable_rsync_autocmd()
  vim.api.nvim_clear_autocmds { group = rsync_augroup }
end

-- Initialize with rsync-on-save enabled
enable_rsync_autocmd()

-- Manual trigger
vim.api.nvim_create_user_command('RsyncNow', function()
  run_rsync()
end, {})

-- Disable rsync-on-save
vim.api.nvim_create_user_command('RsyncDisable', function()
  if _G.rsync_on_save_enabled then
    _G.rsync_on_save_enabled = false
    disable_rsync_autocmd()
  end
  vim.api.nvim_echo({ { 'Rsync on save: DISABLED', 'None' } }, false, {})
end, {})

-- Enable rsync-on-save (optional convenience)
vim.api.nvim_create_user_command('RsyncEnable', function()
  if not _G.rsync_on_save_enabled then
    _G.rsync_on_save_enabled = true
    enable_rsync_autocmd()
  end
  vim.api.nvim_echo({ { 'Rsync on save: ENABLED', 'None' } }, false, {})
end, {})


