local M = {}

-- Internal configuration state
M.config = {
  inbox_path = "~/Library/Application Support/DEVONthink/Inbox/",
  mappings = {
    search = "<leader>ds", -- Open search in DEVONthink app
    find = "<leader>df",   -- Search DEVONthink inside Neovim (Telescope)
    open = "<leader>dl",   -- Open DEVONthink link in Neovim
    inbox = "<leader>di",
    copy_link = "<leader>dc", -- Search and copy item link to clipboard
  }
}

-- API ---------------------------------------------------------------------

--- Search DEVONthink using the x-devonthink:// scheme (Opens the App)
function M.search(query)
  if not query or query == "" then
    query = vim.fn.input('DEVONthink Search: ')
  end

  if query and query ~= "" then
    local url = "x-devonthink://search?query=" .. query
    vim.fn.system({ "open", url })
  end
end

--- Resolve a DEVONthink link/UUID to a path and open it in Neovim
--- @param link string The x-devonthink-item:// link or UUID
--- @param cmd? string The vim command to use (default: edit)
function M.open_link(link, cmd)
  cmd = cmd or "edit"
  if not link or link == "" then
    link = vim.fn.input('DEVONthink Link/UUID: ')
  end
  if link == "" then return end

  local script = [[
    on run argv
      tell application id "DNtp"
        set theRecord to get record with uuid (item 1 of argv)
        if theRecord is not missing value then
          return path of theRecord
        end if
      end tell
      return ""
    end run
  ]]

  local path = vim.fn.system({ "osascript", "-e", script, "--", link }):gsub("%s+$", "")
  
  if path ~= "" then
    vim.cmd(cmd .. " " .. vim.fn.fnameescape(path))
  else
    print("DEVONthink record not found or has no file path.")
  end
end

--- Handle mouse click on a DEVONthink link
function M.handle_click()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  
  -- Find the link under the cursor
  local start_idx, end_idx, link = line:find("(x%-devonthink%-item://[%w%-]+)", 1)
  while start_idx do
    if col >= start_idx and col <= end_idx then
      M.open_link(link, "tabedit")
      return
    end
    start_idx, end_idx, link = line:find("(x%-devonthink%-item://[%w%-]+)", end_idx + 1)
  end
  
  -- If no link found, perform default click behavior (move cursor)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<LeftMouse>", true, false, true), "n", true)
end

--- Internal function to query DEVONthink via AppleScript
local function query_devonthink(query)
  -- Use ASCII character 9 (real tab byte) as delimiter.
  -- AppleScript's `tab` constant outputs the literal string "tab" via osascript, not a tab byte.
  local script = [[
    on run argv
      tell application id "DNtp"
        set theResults to search (item 1 of argv)
        set sep to (ASCII character 9)
        set out to ""
        repeat with theRecord in theResults
          set theName to name of theRecord
          set thePath to path of theRecord
          set theUUID to uuid of theRecord
          if thePath is not "" then
            set out to out & theUUID & sep & theName & sep & thePath & "\n"
          end if
        end repeat
        return out
      end tell
    end run
  ]]

  local output = vim.fn.system({ "osascript", "-e", script, "--", query })
  local lines = {}
  for line in output:gmatch("[^\r\n]+") do
    -- UUID is first (no tabs in UUIDs), then name, then path (path may contain tabs on exotic setups but is last)
    local uuid, name, path = line:match("^([^\t]+)\t([^\t]+)\t(.+)$")
    if uuid and name and path then
      table.insert(lines, { name = name, path = path, uuid = uuid })
    end
  end
  return lines
end

--- Copy a DEVONthink item link to the system clipboard
--- @param uuid string The record UUID
--- @param name? string Optional record name (used when inserting formatted link)
function M.copy_link(uuid, name)
  local link = "x-devonthink-item://" .. uuid
  -- Pipe directly to pbcopy for guaranteed system clipboard access on macOS.
  -- setreg alone is unreliable when called during Telescope teardown.
  vim.fn.system({ "pbcopy" }, link)
  -- Defer Vim register writes until after Telescope has fully closed,
  -- otherwise its async teardown overwrites them.
  vim.schedule(function()
    vim.fn.setreg('"', link) -- unnamed register → p
    vim.fn.setreg("0", link) -- yank register   → "0p
    print("Copied: " .. link)
  end)
end

--- Insert a DEVONthink item link at the current cursor position
--- Format: [name](x-devonthink-item://UUID)
--- @param uuid string The record UUID
--- @param name string The record name
function M.insert_link(uuid, name)
  local link = "x-devonthink-item://" .. uuid
  local formatted = "[" .. name .. "](" .. link .. ")"
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local new_line = line:sub(1, col) .. formatted .. line:sub(col + 1)
  vim.api.nvim_set_current_line(new_line)
  vim.api.nvim_win_set_cursor(0, { row, col + #formatted })
end

--- Search DEVONthink and show results in Telescope
function M.telescope_search()
  local has_telescope, _ = pcall(require, "telescope")
  if not has_telescope then
    print("Telescope is required for this feature.")
    return
  end

  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local pickers = require("telescope.pickers")
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  local query = vim.fn.input("Search DEVONthink: ")
  if query == "" then return end

  local results = query_devonthink(query)
  if #results == 0 then
    print("No results found in DEVONthink.")
    return
  end

  pickers.new({}, {
    prompt_title = "DEVONthink: " .. query .. "  [<CR> open | <C-y> copy link | <C-g> insert link]",
    finder = finders.new_table {
      results = results,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.name,
          ordinal = entry.name,
          path = entry.path,
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    previewer = conf.file_previewer({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        vim.cmd("edit " .. vim.fn.fnameescape(selection.path))
      end)
      -- <C-y>: copy x-devonthink-item:// link to clipboard (y = yank)
      map("i", "<C-y>", function()
        local selection = action_state.get_selected_entry()
        local uuid = selection.value.uuid
        local name = selection.value.name
        actions.close(prompt_bufnr)
        M.copy_link(uuid, name)
      end)
      map("n", "<C-y>", function()
        local selection = action_state.get_selected_entry()
        local uuid = selection.value.uuid
        local name = selection.value.name
        actions.close(prompt_bufnr)
        M.copy_link(uuid, name)
      end)
      -- <C-g>: insert [name](x-devonthink-item://UUID) at cursor
      -- (<C-s> is intercepted by terminals as XOFF and never reaches Neovim)
      map("i", "<C-g>", function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        M.insert_link(selection.value.uuid, selection.value.name)
      end)
      map("n", "<C-g>", function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        M.insert_link(selection.value.uuid, selection.value.name)
      end)
      return true
    end,
  }):find()
end

--- Write the current buffer to the DEVONthink Inbox
function M.write_to_inbox()
  local filename = vim.fn.input('DEVONthink filename: ')
  if filename == "" then return end

  local expanded_inbox = vim.fn.expand(M.config.inbox_path)
  if not expanded_inbox:match("/$") then
    expanded_inbox = expanded_inbox .. "/"
  end

  local full_path = expanded_inbox .. filename
  vim.cmd('write ' .. vim.fn.fnameescape(vim.fn.expand(full_path)))
  print("Written to DEVONthink Inbox: " .. filename)
end

-- Internals ---------------------------------------------------------------

local function create_commands()
  vim.api.nvim_create_user_command('DTSearch', function(args)
    M.search(args.args)
  end, { nargs = '?', desc = 'Search DEVONthink (Opens App)' })

  vim.api.nvim_create_user_command('DTFind', function()
    M.telescope_search()
  end, { desc = 'Search DEVONthink (In Neovim)' })

  vim.api.nvim_create_user_command('DTOpen', function(args)
    M.open_link(args.args)
  end, { nargs = '?', desc = 'Open DEVONthink link in Neovim' })

  vim.api.nvim_create_user_command('DTInbox', function()
    M.write_to_inbox()
  end, { desc = 'Write to DEVONthink Inbox' })

  vim.api.nvim_create_user_command('DTCopyLink', function(args)
    M.copy_link(args.args)
  end, { nargs = 1, desc = 'Copy DEVONthink item link (UUID) to clipboard' })
end

local function apply_mappings()
  local maps = M.config.mappings
  if maps.search then
    vim.keymap.set('n', maps.search, function() M.search() end, { desc = 'Search DEVONthink (App)' })
  end
  if maps.find then
    vim.keymap.set('n', maps.find, function() M.telescope_search() end, { desc = 'Search DEVONthink (Neovim)' })
  end
  if maps.open then
    vim.keymap.set('n', maps.open, function() M.open_link() end, { desc = 'Open DEVONthink link in Neovim' })
  end
  if maps.inbox then
    vim.keymap.set('n', maps.inbox, function() M.write_to_inbox() end, { desc = 'Write to DEVONthink Inbox' })
  end
  if maps.copy_link then
    vim.keymap.set('n', maps.copy_link, function()
      -- Re-use telescope_search but focused on copy action
      M.telescope_search()
    end, { desc = 'Search DEVONthink and copy item link' })
  end
  
  -- Mouse click mapping
  vim.keymap.set('n', '<LeftMouse>', function() M.handle_click() end, { desc = 'Open DEVONthink link on click' })
end

-- Initialization ----------------------------------------------------------

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  create_commands()
  apply_mappings()
end

return M
