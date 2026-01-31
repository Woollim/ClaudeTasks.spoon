-- lib/tasks.lua
-- Task loading and CWD extraction

local M = {}

-- CWD cache (module-level)
local cwdCache = {}

-- Decode CWD path from encoded directory name
function M.decodeCwdPath(encodedDir)
    -- Encoding: / -> -, /. -> --
    local path = encodedDir:gsub("%-%-", "\001")  -- -- -> temp marker
    path = path:gsub("^%-", "/")                   -- leading - -> /
    path = path:gsub("%-", "/")                    -- remaining - -> /
    path = path:gsub("\001", "/.")                 -- temp marker -> /.
    return path
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
