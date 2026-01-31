# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClaudeTasks.spoon is a Hammerspoon Spoon that provides a floating WebView-based task viewer for Claude Code tasks stored in `~/.claude/tasks/`.

## Architecture

Modular Spoon architecture with coordinator pattern:

```
ClaudeTasks.spoon/
├── init.lua              # Thin coordinator (~490 lines)
├── lib/
│   ├── utils.lua         # Pure utilities: log, file ops, JSON, HTML escape
│   ├── discovery.lua     # CLI/terminal app discovery
│   ├── state.lua         # State persistence and session management
│   ├── tasks.lua         # Task loading and CWD extraction
│   ├── html.lua          # HTML/CSS/JS generation
│   ├── webview.lua       # WebView management and UI components
│   ├── watcher.lua       # File system watcher
│   └── updater.lua       # GitHub release update checker
├── state.json
└── docs.json
```

### Module Loading

Hammerspoon Spoons cannot use `require()`. Uses `loadfile()` pattern:
```lua
local function loadModule(name)
    local path = obj.spoonPath .. "/lib/" .. name .. ".lua"
    local f, err = loadfile(path)
    if not f then error("Failed to load " .. name .. ": " .. err) end
    return f()
end
```

### Circular Dependency Solution

WebView callbacks reference `obj` methods. Solved via action handler injection:
```lua
-- init.lua: Action handler passed to webview module
local function actionHandler(action, params)
    if action == "setSession" then obj:setTaskListId(params.value)
    elseif action == "createTask" then obj:createTask(params.subject)
    -- ...
    end
end

-- webview.lua: Receives callback, no direct obj reference
function M.createUserContent(actionHandler, log)
    usercontent:setCallback(function(msg)
        actionHandler(msg.body.action, msg.body)
    end)
end
```

### JS-Lua Bridge

WebView communicates with Lua via `hs.webview.usercontent`. JavaScript calls `webkit.messageHandlers.taskBridge.postMessage()` which triggers the `userContentController` callback in Lua.

### Task File Structure

Tasks are stored in `~/.claude/tasks/{sessionId}/*.json`. Each session directory contains individual task JSON files.

## Development Commands

No build/test/lint commands. This is a pure Lua Spoon.

**Testing**: Reload in Hammerspoon console with:
```lua
hs.loadSpoon("ClaudeTasks")
spoon.ClaudeTasks:start()
```

**Debug mode**: Enable logging via `spoon.ClaudeTasks:configure({debugMode = true})`

## Key Conventions

- **State persistence**: `currentTaskListId` and `lastUpdateCheck` persisted to `state.json`
- **External tools**: Always auto-discovered, never hardcoded paths
- **Task sorting**: Numeric IDs first, then string IDs alphabetically
- **Debounce pattern**: Timer-based debounce for file watcher events (0.2s default)

## Update Checker

Built-in update checker uses GitHub API to check for new releases:

- **Auto-check**: Runs on `start()` with 24-hour interval (configurable)
- **Manual check**: `spoon.ClaudeTasks:checkForUpdates(true)`
- **Disable**: `spoon.ClaudeTasks:configure({checkForUpdates = false})`

SpoonInstall compatible via `docs.json` metadata file.

## Public API

See README.md for complete API documentation. Key methods:
- `obj:start()`, `obj:stop()`, `obj:show()`, `obj:hide()`, `obj:toggle()`
- `obj:refresh()`, `obj:setTaskListId()`, `obj:createTask()`, `obj:quickTaskUpdate()`
- `obj:launchClaudeWithTaskList()`, `obj:configure()`, `obj:checkForUpdates()`, `obj:status()`, `obj:bindHotkeys()`

## Dependencies

- Hammerspoon (macOS)
- Claude Code CLI (`claude` command)
- Terminal: Ghostty, iTerm2, or Terminal.app
