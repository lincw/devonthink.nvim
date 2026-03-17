# devonthink.nvim

A lightweight Neovim plugin to bridge the gap between DEVONthink and Neovim on macOS.

## 📥 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "lincw/devonthink.nvim",
  dependencies = { 
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim" 
  },
  config = function()
    require("devonthink").setup()
  end
}
```

## ⚙️ Configuration

### Default Configuration

```lua
require("devonthink").setup({
  -- Path to the DEVONthink Global Inbox
  inbox_path = "~/Library/Application Support/DEVONthink/Inbox/",

  -- Default mappings (set to nil to disable)
  mappings = {
    search = "<leader>ds", -- Open search in DEVONthink app
    find   = "<leader>df", -- Search DEVONthink inside Neovim (Telescope)
    inbox  = "<leader>di", -- Save current buffer to Inbox
  }
})
```

## 🚀 Usage

### Commands

| Command | Description |
| :--- | :--- |
| `:DTFind` | **Search DEVONthink inside Neovim** (via Telescope). |
| `:DTSearch <query>` | Open DEVONthink app and search for the given query. |
| `:DTInbox` | Save the current buffer to the DEVONthink Global Inbox. |

### Default Mappings

- `<leader>df`: **Search DEVONthink from Neovim.** Shows a list of matching files in Telescope.
- `<leader>ds`: Prompt for a search query and open results in the DEVONthink app.
- `<leader>di`: Save current file to DEVONthink Inbox.

### DEVONthink Integration ("Open in Neovim")

To open files from DEVONthink directly in your Neovim instance:

1. Open `scripts/Open in Neovim.applescript` from this repository.
2. In DEVONthink, go to the **Scripts menu** (icon in the menu bar) > **Open Scripts Folder**.
3. Save the script as `Open in Neovim.scpt`.
4. Now you can select any record in DEVONthink and run this script to open it in Neovim.

## 📋 Requirements

- **OS:** macOS
- **App:** DEVONthink 3
- **Neovim Plugin:** `telescope.nvim` (required for `:DTFind`)
- **Terminal:** iTerm2 (default for the AppleScript)

## 💡 Idea

The goal of this plugin is to treat DEVONthink as a powerful backend for document management while using Neovim as the primary interface for editing and searching. By leveraging DEVONthink's AppleScript API, we can fetch results directly into Neovim, providing a distraction-free workflow.

## 📄 License

MIT
