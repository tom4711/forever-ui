local _, ns = ...
local R = ns.Read
local LevelStats = {}
ns.LevelStats = LevelStats

local HISTORY_LENGTH = 3
local SAMPLE_INTERVAL = 1
local MAX_SAMPLE_GAP = 5
local REQUEST_INTERVAL = 10
local REPORT_MAX_AGE = 60

local state, events
local inWorld, lastTick, levelChangedAt, lastRequest, lastReport
local updateElapsed = 0

local function duration(value)
    value = R.Number(value)
    if value and value >= 0 then return value end
end

local function playerLevel(value)
    value = R.Number(value)
    if value and value >= 1 and value == math.floor(value) then return value end
end

local function copyHistory(history, level)
    local copy, seen = {}, {}
    if type(history) ~= "table" then return copy end
    for _, entry in ipairs(history) do
        if type(entry) == "table" then
            local completedLevel = playerLevel(entry.level)
            local seconds = duration(entry.seconds)
            if completedLevel and seconds and not seen[completedLevel] and (not level or completedLevel < level) then
                seen[completedLevel] = true
                copy[#copy + 1] = {level = completedLevel, seconds = seconds}
            end
        end
    end
    table.sort(copy, function(a, b) return a.level > b.level end)
    for i = #copy, HISTORY_LENGTH + 1, -1 do copy[i] = nil end
    return copy
end

function LevelStats.Load(saved)
    saved = type(saved) == "table" and saved or {}
    local level = playerLevel(saved.level)
    local seconds = level and duration(saved.seconds)
    local totalTime = duration(saved.totalTime)
    if seconds and totalTime and totalTime < seconds then totalTime = nil end
    return {
        level = level,
        seconds = seconds or 0,
        partial = not seconds or saved.partial ~= false,
        totalTime = totalTime,
        lastServerTotal = totalTime and duration(saved.lastServerTotal),
        levelStartTotal = level and totalTime and duration(saved.levelStartTotal),
        previousLevelStartTotal = level and totalTime and duration(saved.previousLevelStartTotal),
        history = copyHistory(saved.history, level),
    }
end

local function clock()
    return R.Number(R.Call(GetTime))
end

local function playing()
    return inWorld
        and (not IsPlayerInWorld or R.Boolean(R.Call(IsPlayerInWorld)) == true)
        and (not UnitIsConnected or R.Boolean(R.Call(UnitIsConnected, "player")) == true)
end

local function sample(now)
    local previous = lastTick
    lastTick = state.level and playing() and now or nil
    if not lastTick or not previous then return end
    local elapsed = lastTick - previous
    if elapsed < 0 or elapsed > MAX_SAMPLE_GAP then
        state.partial = true
    elseif elapsed > 0 then
        state.seconds = state.seconds + elapsed
        if state.totalTime then state.totalTime = state.totalTime + elapsed end
    end
end

local function saveSplit(level, seconds)
    local latest = state.history[1]
    if latest and latest.level == level then
        latest.seconds = seconds
    else
        table.insert(state.history, 1, {level = level, seconds = seconds})
        state.history[HISTORY_LENGTH + 1] = nil
    end
end

local function startLevel(level, observed, now)
    local adjacent = observed and state.level and level == state.level + 1
    if adjacent and not state.partial then saveSplit(state.level, state.seconds) end
    state.previousLevelStartTotal = adjacent and state.levelStartTotal or nil
    state.levelStartTotal = nil
    state.level, state.seconds, state.partial = level, 0, not observed
    levelChangedAt, lastReport = observed and now or nil, nil
end

local function timePlayed(now, total, atLevel)
    total, atLevel = duration(total), duration(atLevel)
    if not state.level or not playing() or not total or not atLevel or atLevel > total then return end
    if state.lastServerTotal and total < state.lastServerTotal then return end

    -- Replies have no level attached and may have been sent just before a level-up.
    if levelChangedAt and now and atLevel > now - levelChangedAt + 2 then return end
    local startedAt = total - atLevel
    if state.levelStartTotal and math.abs(startedAt - state.levelStartTotal) > 1 then return end
    local previousStart = state.previousLevelStartTotal
    if previousStart then
        if startedAt <= previousStart then return end
        saveSplit(state.level - 1, startedAt - previousStart)
        state.previousLevelStartTotal = nil
    end

    state.levelStartTotal, state.lastServerTotal = startedAt, total
    state.seconds, state.totalTime, state.partial = atLevel, total, false
    lastReport, lastTick = now, now
end

function LevelStats.Snapshot()
    if not state then return {history = {}} end
    sample(clock())
    return {
        level = state.level,
        currentLevelTime = state.level and state.seconds,
        currentLevelTimePartial = state.level and state.partial,
        totalTime = state.totalTime,
        history = copyHistory(state.history, state.level),
    }
end

function LevelStats.Request()
    -- A native reply prints in Blizzard chat, so this is for an explicit click.
    if not state or not state.level or not playing() or type(RequestTimePlayed) ~= "function" then return end
    local now = clock()
    if not now or (lastRequest and now - lastRequest < REQUEST_INTERVAL)
        or (lastReport and now - lastReport < REPORT_MAX_AGE) then return end
    lastRequest = now
    pcall(RequestTimePlayed)
end

function LevelStats.Init()
    if events then return end
    state = ns.db.levelStats or LevelStats.Load()
    ns.db.levelStats = state
    events = CreateFrame("Frame")
    for _, event in ipairs({"PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD", "PLAYER_LOGOUT",
        "PLAYER_LEVEL_UP", "TIME_PLAYED_MSG"}) do
        events:RegisterEvent(event)
    end
    events:SetScript("OnUpdate", function(_, elapsed)
        if not inWorld then return end
        updateElapsed = updateElapsed + elapsed
        if updateElapsed >= SAMPLE_INTERVAL then
            updateElapsed = 0
            sample(clock())
        end
    end)
    events:SetScript("OnEvent", function(_, event, ...)
        local now = clock()
        if event == "PLAYER_ENTERING_WORLD" then
            inWorld, lastTick, updateElapsed = true, nil, 0
            local level = playerLevel(R.Call(UnitLevel, "player"))
            if level and level ~= state.level then
                if state.level and level < state.level then state.history = copyHistory(state.history, level) end
                startLevel(level, false, now)
            end
            sample(now)
        elseif event == "PLAYER_LEAVING_WORLD" or event == "PLAYER_LOGOUT" then
            sample(now)
            inWorld, lastTick = false, nil
        elseif event == "PLAYER_LEVEL_UP" then
            local level = playerLevel(...)
            if level and playing() and (not state.level or level > state.level) then
                sample(now)
                startLevel(level, true, now)
                sample(now)
            end
        elseif event == "TIME_PLAYED_MSG" then
            timePlayed(now, ...)
        end
    end)
end
