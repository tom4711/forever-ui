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

local function canReadThreat()
    return R.Call(UnitAffectingCombat, "player") == true
        and R.Call(UnitCanAttack, "player", "target") == true
        and R.Call(UnitIsPlayer, "target") ~= true
        and R.Call(UnitIsDead, "target") ~= true
end

local function readThreat(unit)
    local ok, tanking, status, scaled, _, rawThreat = pcall(UnitDetailedThreatSituation, unit, "target")
    if ok then return tanking, status, scaled, rawThreat end
end

local function isTank()
    if R.Call(UnitGroupRolesAssigned, "player") == "TANK" then return true end
    local specialization = R.Number(R.Call(GetSpecialization))
    return specialization ~= nil and R.Call(GetSpecializationRole, specialization) == "TANK"
end

function M.Threat()
    if not canReadThreat() then return end
    local holdingTarget, status, amount = readThreat("player")
    local tanking = R.Boolean(holdingTarget)
    local rank, percent = R.Number(status), R.Number(amount)
    if percent and percent < 0 then percent, amount = nil, nil end
    if tanking == nil and rank and rank >= 0 and rank <= 3 then tanking = rank >= 2 end
    if tanking == nil and not M.Present(amount) then return end

    local state = "normal"
    local tankRole = isTank()
    if tanking == true then
        local supported = R.Call(IsInGroup) == true or R.Call(UnitExists, "pet") == true
        state = supported and not tankRole and "warning" or "tanking"
    elseif (tanking == false and tankRole) or (percent and percent >= 90) then
        state = "warning"
    elseif (percent and percent >= 75) or rank == 1 then
        state = "attention"
    end
    return {percent = amount, tanking = tanking, state = state}
end

function M.ThreatRoster()
    local entries = {}
    if not canReadThreat() then return entries end

    local function add(unit)
        local tanking, _, _, rawThreat = readThreat(unit)
        local amount = R.Number(rawThreat)
        local name = R.Call(UnitName, unit)
        if amount and amount > 0 and type(name) == "string" and name ~= "" then
            entries[#entries + 1] = {unit = unit, name = name, amount = amount, tanking = R.Boolean(tanking) == true}
        end
    end
    local function addGroupMember(unit, ownUnit)
        if R.Call(UnitExists, unit) == true and R.Call(UnitIsUnit, unit, ownUnit) ~= true then add(unit) end
    end

    add("player")
    if R.Call(UnitExists, "pet") == true then add("pet") end
    if R.Call(IsInRaid) == true then
        local count = R.Number(R.Call(GetNumGroupMembers)) or 0
        for index = 1, math.min(count, 40) do
            addGroupMember("raid" .. index, "player")
            addGroupMember("raidpet" .. index, "pet")
        end
    elseif R.Call(IsInGroup) == true then
        for index = 1, 4 do
            addGroupMember("party" .. index, "player")
            addGroupMember("partypet" .. index, "pet")
        end
    end
    table.sort(entries, function(a, b)
        if a.amount ~= b.amount then return a.amount > b.amount end
        return a.unit < b.unit
    end)
    return entries
end

local function field(data, key)
    return M.Value(function() return data[key] end)
end

local function isOwnAura(data)
    local playerCast = R.Boolean(field(data, "isFromPlayerOrPlayerPet"))
    if playerCast == true then return true end
    local source = R.Call(field, data, "sourceUnit")
    if type(source) ~= "string" then return playerCast end
    return source == "player" or source == "pet" or source == "vehicle"
        or R.Call(UnitIsUnit, "player", source) == true
        or R.Call(UnitIsOwnerOrControllerOfUnit, "player", source) == true
end

function M.Auras(limit, filter, showTimers)
    local own, other = {}, {}
    local api = C_UnitAuras
    if not api or type(api.GetAuraDataByIndex) ~= "function" then return own, true end

    local restricted = false
    local helpful = filter == "HELPFUL"
    for index = 1, 40 do
        local ok, aura = pcall(api.GetAuraDataByIndex, "target", index, filter)
        if not ok then
            restricted = true
            break
        end
        if not M.Present(aura) then break end
        local readable = R.Try(function() return aura end)
        if readable and type(aura) == "table" then
            local isOwn = isOwnAura(aura)
            if showTimers and not helpful and isOwn == nil then restricted = true end
            local list = isOwn and own or other
            if #list < limit then
                list[#list + 1] = {data = aura, index = index, own = isOwn}
            end
            if #own == limit then break end
        elseif not readable then
            restricted = true
        end
    end

    for index = 1, math.min(limit - #own, #other) do
        own[#own + 1] = other[index]
    end

    for index, aura in ipairs(own) do
        local data = aura.data
        local instanceID = R.Number(field(data, "auraInstanceID"))
        local duration = field(data, "duration")
        local expirationTime = field(data, "expirationTime")
        local publicDuration, publicExpiration = R.Number(duration), R.Number(expirationTime)
        local durationObject = instanceID and M.Value(api.GetAuraDuration, "target", instanceID)
        if showTimers and (helpful or aura.own) then
            local secretTime = issecretvalue and (issecretvalue(duration) or issecretvalue(expirationTime))
            local objectOnly = M.Present(durationObject) and (not publicDuration or not publicExpiration)
            if secretTime or objectOnly then restricted = true end
        end
        own[index] = {
            index = aura.index, own = aura.own, instanceID = instanceID,
            name = field(data, "name"), icon = field(data, "icon"),
            applications = field(data, "applications"), duration = publicDuration,
            expirationTime = publicExpiration, timeMod = R.Number(field(data, "timeMod")),
            durationObject = durationObject,
        }
    end
    return own, restricted
end
