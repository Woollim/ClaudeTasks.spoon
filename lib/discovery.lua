-- lib/discovery.lua
-- CLI and terminal app discovery functions

local M = {}

-- Discover Claude CLI path
function M.discoverClaudePath(configPath)
    if configPath then return configPath end
    -- GUI apps have limited PATH, search common install locations
    local candidates = {
        os.getenv("HOME") .. "/.local/bin/claude",
        "/usr/local/bin/claude",
        "/opt/homebrew/bin/claude",
    }
    for _, path in ipairs(candidates) do
        if hs.fs.attributes(path) then return path end
    end
    return nil
end

-- Discover terminal application
function M.discoverTerminalApp(configPath)
    if configPath then return configPath end
    local candidates = {
        "/Applications/Ghostty.app/Contents/MacOS/ghostty",
        "/Applications/iTerm.app/Contents/MacOS/iTerm2",
        "/Applications/Utilities/Terminal.app/Contents/MacOS/Terminal"
    }
    for _, path in ipairs(candidates) do
        if hs.fs.attributes(path) then return path end
    end
    return nil
end

-- Get shell path
function M.getShell(configShell)
    return configShell or os.getenv("SHELL") or "/bin/zsh"
end

return M
