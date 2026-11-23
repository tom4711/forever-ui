local _, ns = ...

local function reportError(key, message)
    local text = ("Forever UI [%s]: %s"):format(tostring(key), tostring(message))
    local handler = geterrorhandler and geterrorhandler() or ns.Print
    if handler then handler(text) end
end

local function new(isLocked, report)
    local pending = {}
    local queue = {}
    report = report or reportError

    local function run(key, apply)
        local ok, message = pcall(apply)
        if not ok then pcall(report, key, message) end
        return ok
    end

    function queue.Request(key, apply)
        if isLocked() then
            pending[key] = apply
            return false
        end
        pending[key] = nil
        return run(key, apply)
    end

    function queue.Flush()
        local complete = true
        for key, apply in pairs(pending) do
            if isLocked() then return false end
            pending[key] = nil
            if not run(key, apply) then complete = false end
        end
        return complete
    end

    return queue
end

ns.CombatQueue = new(function() return InCombatLockdown() end)
ns.CombatQueue.New = new
