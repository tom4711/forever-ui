local _, ns = ...
local R = ns.Read
local M = {}
ns.TargetModel = M

function M.Present(value)
    return (issecretvalue and issecretvalue(value)) or value ~= nil
end

function M.Value(api, ...)
    if type(api) ~= "function" then return nil end
    local ok, value = pcall(api, ...)
    if ok then return value end
end

local function castData(channel, name, label, icon, startMs, endMs, notInterruptible, empowered)
    local empoweredCast = R.Boolean(empowered) == true
    local duration
    if channel then
        if empoweredCast then duration = M.Value(UnitEmpoweredChannelDuration, "target") end
        if not M.Present(duration) then duration = M.Value(UnitChannelDuration, "target") end
    else
        duration = M.Value(UnitCastingDuration, "target")
    end
    if not M.Present(name) and not M.Present(label) and not M.Present(duration) then return nil end
    local startTime, endTime = R.Number(startMs), R.Number(endMs)
    if startTime and endTime and endTime > startTime then
        startTime, endTime = startTime / 1000, endTime / 1000
        if empoweredCast then
            endTime = endTime + (R.Number(R.Call(GetUnitEmpowerHoldAtMaxTime, "target")) or 0) / 1000
        end
    else
        startTime, endTime = nil, nil
    end
    local interruptible
    local locked = R.Boolean(notInterruptible)
    if locked ~= nil then interruptible = not locked end
    return {
        name = M.Present(label) and label or name, icon = icon,
        startTime = startTime, endTime = endTime, duration = duration,
        channel = channel and not empoweredCast, interruptible = interruptible,
        notInterruptible = notInterruptible,
    }
end

function M.Cast()
    if R.Call(UnitCanAttack, "player", "target") ~= true then return nil end
    local ok, name, label, icon, startMs, endMs, _, _, locked = pcall(UnitCastingInfo, "target")
    if not ok then name = nil end
    local casting = castData(false, name, label, icon, startMs, endMs, locked)
    if casting then return casting end
    local _, empowered
    ok, name, label, icon, startMs, endMs, _, locked, _, empowered = pcall(UnitChannelInfo, "target")
    if not ok then name = nil end
    return castData(true, name, label, icon, startMs, endMs, locked, empowered)
end

function M.CastProgress(cast, now)
    if not cast.endTime or now >= cast.endTime then return nil end
    local progress = math.max(0, (now - cast.startTime) / (cast.endTime - cast.startTime))
    return cast.channel and 1 - progress or progress
end

local function field(data, key)
    return M.Value(function() return data[key] end)
end

local function isOwnAura(data)
    if R.Boolean(field(data, "isFromPlayerOrPlayerPet")) == true then return true end
    local source = R.Call(field, data, "sourceUnit")
    if type(source) ~= "string" then return false end
    return source == "player" or source == "pet" or source == "vehicle"
        or R.Call(UnitIsUnit, "player", source) == true
        or R.Call(UnitIsOwnerOrControllerOfUnit, "player", source) == true
end

function M.Debuffs(limit)
    local own, other = {}, {}
    local api = C_UnitAuras
    if not api or type(api.GetAuraDataByIndex) ~= "function" then return own end

    for index = 1, 40 do
        local ok, aura = pcall(api.GetAuraDataByIndex, "target", index, "HARMFUL")
        if not ok or not M.Present(aura) then break end
        local readable = R.Try(function() return aura end)
        if readable and type(aura) == "table" then
            local isOwn = isOwnAura(aura)
            local list = isOwn and own or other
            if #list < limit then
                list[#list + 1] = {data = aura, index = index, own = isOwn}
            end
            if #own == limit then break end
        end
    end

    for index = 1, math.min(limit - #own, #other) do
        own[#own + 1] = other[index]
    end

    for index, aura in ipairs(own) do
        local data = aura.data
        local instanceID = R.Number(field(data, "auraInstanceID"))
        own[index] = {
            index = aura.index, own = aura.own, instanceID = instanceID,
            name = field(data, "name"), icon = field(data, "icon"),
            applications = field(data, "applications"), duration = R.Number(field(data, "duration")),
            expirationTime = R.Number(field(data, "expirationTime")), timeMod = R.Number(field(data, "timeMod")),
            durationObject = instanceID and M.Value(api.GetAuraDuration, "target", instanceID),
        }
    end
    return own
end
