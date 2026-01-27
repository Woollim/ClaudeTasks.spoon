# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClaudeTasks.spoon is a Hammerspoon Spoon that provides a floating WebView-based task viewer for Claude Code tasks stored in `~/.claude/tasks/`.

## Architecture

Single-file Spoon architecture in `init.lua` (~1200 lines) with these key sections:

1. **Configuration** (lines 19-34): UI dimensions, debounce timing, external tool paths
2. **Discovery** (lines 40-66): Auto-discovers `claude` CLI, terminal app, shell
3. **State Management** (lines 72-197): Persists session ID to `state.json`
4. **Task Loading** (lines 203-253): Reads JSON task files from session directories
5. **HTML Rendering** (lines 259-768): Dark-themed HTML/CSS/JS for WebView
6. **WebView** (lines 774-844): Floating HUD window management
7. **File Watching** (lines 850-907): Debounced `hs.pathwatcher` for auto-refresh
8. **Public API** (lines 914-1205): Spoon methods (`start`, `stop`, `show`, `toggle`, etc.)

### JS-Lua Bridge

WebView communicates with Lua via `hs.webview.usercontent`. JavaScript calls `webkit.messageHandlers.hammerspoon.postMessage()` which triggers the `userContentController` callback in Lua.

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

- **State persistence**: Only `currentTaskListId` is persisted (to `state.json`)
- **External tools**: Always auto-discovered, never hardcoded paths
- **Task sorting**: Numeric IDs first, then string IDs alphabetically
- **Debounce pattern**: Timer-based debounce for file watcher events (0.2s default)

## Dependencies

- Hammerspoon (macOS)
- Claude Code CLI (`claude` command)
- Terminal: Ghostty, iTerm2, or Terminal.app
