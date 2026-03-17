local M = {}

-- Internal configuration state
M.config = {
  inbox_path = "~/Library/Application Support/DEVONthink/Inbox/",
  mappings = {
    search = "<leader>ds", -- Open search in DEVONthink app
    find = "<leader>df",   -- Search DEVONthink inside Neovim (Telescope)
    inbox = "<leader>di",
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

--- Internal function to query DEVONthink via AppleScript
local function query_devonthink(query)
  local script = [[
    on run argv
      tell application id "DNtp"
        set theResults to search (item 1 of argv)
        set out to ""
        repeat with theRecord in theResults
          set theName to name of theRecord
          set thePath to path of theRecord
          if thePath is not "" then
            set out to out & theName & "::" & thePath & "\n"
          end if
        end repeat
        return out
      end tell
    end run
  ]]

  local output = vim.fn.system({ "osascript", "-e", script, "--", query })
  local lines = {}
  for line in output:gmatch("[^\r\n]+") do
    local name, path = line:match("^(.*)::(.*)$")
    if name and path then
      table.insert(lines, { name = name, path = path })
    end
  end
  return lines
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
    prompt_title = "DEVONthink Results: " .. query,
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

  vim.api.nvim_create_user_command('DTInbox', function()
    M.write_to_inbox()
  end, { desc = 'Write to DEVONthink Inbox' })
end

local function apply_mappings()
  local maps = M.config.mappings
  if maps.search then
    vim.keymap.set('n', maps.search, function() M.search() end, { desc = 'Search DEVONthink (App)' })
  end
  if maps.find then
    vim.keymap.set('n', maps.find, function() M.telescope_search() end, { desc = 'Search DEVONthink (Neovim)' })
  end
  if maps.inbox then
    vim.keymap.set('n', maps.inbox, function() M.write_to_inbox() end, { desc = 'Write to DEVONthink Inbox' })
  end
end

-- Initialization ----------------------------------------------------------

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
  create_commands()
  apply_mappings()
end

return M
