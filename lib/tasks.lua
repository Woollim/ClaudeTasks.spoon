-- lib/tasks.lua
-- Task loading and CWD extraction

local M = {}

-- CWD cache (module-level)
local cwdCache = {}

-- Decode CWD path from encoded directory name
-- Claude encodes paths: / → -, /. → --
-- Problem: hyphens in dir names (e.g. team-attention) are ambiguous.
-- Solution: walk the filesystem to resolve the correct path.
function M.decodeCwdPath(encodedDir)
    local parts = {}
    -- Split on '-' but first handle '--' (encoded /.)
    local encoded = encodedDir:gsub("%-%-", "\001")
    -- Remove leading '-' (represents root /)
    if encoded:sub(1,1) == "-" then
        encoded = encoded:sub(2)
    elseif encoded:sub(1,1) == "\001" then
        -- leading -- means /.
        encoded = encoded:sub(2)
        parts[1] = "."
    end
    local segments = {}
    for seg in encoded:gmatch("[^\001]+") do
        table.insert(segments, seg)
    end
    -- For each '--' separated segment, resolve dash ambiguity via filesystem
    local function resolveSegment(basePath, segment)
        local tokens = {}
        for t in segment:gmatch("[^%-]+") do
            table.insert(tokens, t)
        end
        if #tokens == 0 then return basePath end
        -- Try greedily matching longest existing directory names
        local function tryResolve(idx, currentPath)
            if idx > #tokens then return currentPath end
            local accumulated = tokens[idx]
            for j = idx, #tokens do
                if j > idx then
                    accumulated = accumulated .. "-" .. tokens[j]
                end
                local candidate = currentPath .. "/" .. accumulated
                if j == #tokens then
                    -- Last possible combo, must use it
                    return candidate
                end
                if hs.fs.attributes(candidate, "mode") == "directory" then
                    local result = tryResolve(j + 1, candidate)
                    if result then return result end
                end
            end
            -- Fallback: treat each token as a directory
            return tryResolve(idx + 1, currentPath .. "/" .. tokens[idx])
        end
        return tryResolve(1, basePath)
    end
    local result = ""
    for i, seg in ipairs(segments) do
        local actualSeg = seg
        if i > 1 or (parts[1] == ".") then
            actualSeg = "." .. seg
        end
        result = resolveSegment(result, actualSeg)
    end
    return result
end

-- Get CWD from session ID by scanning projects directory
function M.getCwdFromSessionId(sessionId, utils)
    if cwdCache[sessionId] then return cwdCache[sessionId] end

    local projectsDir = os.getenv("HOME") .. "/.claude/projects"
    if not utils.fileExists(projectsDir) then return nil end

    for _, encodedDir in ipairs(utils.listDir(projectsDir)) do
        local sessionFile = projectsDir .. "/" .. encodedDir .. "/" .. sessionId .. ".jsonl"
        if utils.fileExists(sessionFile) then
            local cwd = M.decodeCwdPath(encodedDir)
            cwdCache[sessionId] = cwd
            return cwd
        end
    end
    return nil
end

-- Load all tasks from session directories
function M.loadAllTasks(config, utils, log)
    local tasks = {}
    local tasksDir = utils.getTasksDir()

    if not utils.fileExists(tasksDir) then
        log("Tasks directory does not exist: " .. tasksDir)
        return tasks
    end

    -- Load specific session or all sessions
    local sessions = {}
    if config.taskListId then
        sessions = {config.taskListId}
    else
        sessions = utils.listDir(tasksDir)
    end

    for _, sessionId in ipairs(sessions) do
        local sessionDir = tasksDir .. "/" .. sessionId
        local files = utils.listDir(sessionDir)

        for _, filename in ipairs(files) do
            if filename:match("%.json$") then
                local filepath = sessionDir .. "/" .. filename
                local content = utils.readFile(filepath)

                if content then
                    local task = utils.parseJSON(content)
                    if task then
                        task._sessionId = sessionId
                        task._filepath = filepath
                        task._cwd = M.getCwdFromSessionId(sessionId, utils)
                        table.insert(tasks, task)
                    end
                end
            end
        end
    end

    -- Sort by ID (numeric first, then string)
    table.sort(tasks, function(a, b)
        local aNum = tonumber(a.id)
        local bNum = tonumber(b.id)
        if aNum and bNum then
            return aNum < bNum
        end
        return tostring(a.id) < tostring(b.id)
    end)

    log("Loaded " .. #tasks .. " tasks")
    return tasks
end

-- Clear CWD cache
function M.clearCache()
    cwdCache = {}
end

return M
