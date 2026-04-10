# devonthink.nvim

A lightweight Neovim plugin to bridge the gap between DEVONthink and Neovim on macOS.

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "lincw/devonthink.nvim",
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim",
  },
  config = function()
    require("devonthink").setup()
  end,
}
```

## Configuration

```lua
require("devonthink").setup({
  -- Path to the DEVONthink Global Inbox
  inbox_path = "~/Library/Application Support/DEVONthink/Inbox/",

  -- Default mappings (set any to nil to disable)
  mappings = {
    search    = "<leader>ds", -- Open search in DEVONthink app
    find      = "<leader>df", -- Search DEVONthink inside Neovim (Telescope)
    open      = "<leader>dl", -- Open a DEVONthink link in Neovim
    inbox     = "<leader>di", -- Save current buffer to Inbox
    copy_link = "<leader>dc", -- Search and copy an item link to clipboard
  }
})
```

## Usage

### Commands

| Command | Description |
| :--- | :--- |
| `:DTFind` | Search DEVONthink inside Neovim via Telescope. |
| `:DTOpen [link]` | Open a DEVONthink link or UUID in a Neovim buffer. |
| `:DTSearch [query]` | Open the DEVONthink app and run a search. |
| `:DTInbox` | Save the current buffer to the DEVONthink Global Inbox. |
| `:DTCopyLink <UUID>` | Copy a known UUID as an `x-devonthink-item://` link to clipboard. |

### Default Mappings

| Mapping | Description |
| :--- | :--- |
| `<leader>df` | Search DEVONthink from Neovim (Telescope picker). |
| `<leader>dc` | Search DEVONthink and copy the selected item link. |
| `<leader>dl` | Prompt for a link/UUID and open it in Neovim. |
| `<leader>ds` | Open DEVONthink app with a search query. |
| `<leader>di` | Save current buffer to DEVONthink Inbox. |

### Telescope Picker Actions

When the Telescope picker is open (`:DTFind` / `<leader>df`):

| Key | Action |
| :--- | :--- |
| `<CR>` | Open the selected record in Neovim. |
| `<C-y>` | Copy the item's `x-devonthink-item://` link to clipboard. |
| `<C-g>` | Insert `[name](x-devonthink-item://UUID)` at the cursor position. |

**Copy link workflow:**
1. `<leader>df` — open the Telescope search picker
2. Type your query, navigate to the item
3. `<C-y>` — copies the link and closes the picker
4. `p` — paste the link wherever you need it

### Handling Links

- **Open a link**: `:DTOpen x-devonthink-item://UUID` resolves the UUID to a local file path and opens it in Neovim.
- **Mouse click**: Clicking on an `x-devonthink-item://` link opens that record in a new Neovim tab.
- **Jump to app**: Neovim's `gx` on an `x-devonthink://` link opens the record in the DEVONthink app.

### DEVONthink → Neovim ("Open in Neovim" script)

To open records from DEVONthink directly into your Neovim instance:

1. Open `scripts/Open in Neovim.applescript` from this repository.
2. In DEVONthink, go to **Scripts menu** > **Open Scripts Folder**.
3. Save the script there as `Open in Neovim.scpt`.
4. Select any record in DEVONthink and run the script to open it in Neovim.

## Requirements

- macOS
- DEVONthink 3
- Neovim with `telescope.nvim` (required for `:DTFind`)
- iTerm2 (default for the "Open in Neovim" AppleScript; change to `Terminal` if needed)

## License

MIT
