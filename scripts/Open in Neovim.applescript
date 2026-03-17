-- Open selected DEVONthink records in Neovim
tell application id "DNtp"
    try
        set theSelection to the selection
        if theSelection is {} then error "Please select a record."
        
        repeat with theRecord in theSelection
            set thePath to (path of theRecord) as string
            if thePath is not "" then
                my openInNeovim(thePath)
            end if
        end repeat
    on error error_message
        display alert "DEVONthink" message error_message
    end try
end tell

on openInNeovim(thePath)
    -- This assumes you use iTerm2. Change to "Terminal" if needed.
    tell application "iTerm"
        activate
        if (count of windows) = 0 then
            create window with default profile
        end if
        tell current session of current window
            -- If you use nvr (neovim-remote), you can change this to:
            -- write text "nvr --remote-silent " & quoted form of thePath
            write text "nvim " & quoted form of thePath
        end tell
    end tell
end openInNeovim
