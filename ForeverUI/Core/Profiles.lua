local _, ns = ...
local Profiles = {}
ns.Profiles = Profiles

local profiles = {}
local point = {point = true, relativePoint = true, x = true, y = true}
local frame = {enabled = true, scale = true, position = point}
local group = {position = {x = true, y = true}}

local function classLayout(...)
    local fields = {scale = true, position = point, dockPosition = {x = true, y = true}}
    for index = 1, select("#", ...) do
        fields[select(index, ...)] = group
    end
    return fields
end

-- Only these fields travel between characters. Keep the character table and its nested
-- settings objects in place because settings controls keep references to them.
local fields = {
    locked = true, classAccent = true, raidFrameStyle = true, enemyFrameStyle = true,
    layout = {grid = true, snap = true, attachClass = true},
    player = {enabled = true, scale = true, position = point, hideBlizzardAuras = true, priorityAuras = "spellIDs"},
    target = {enabled = true, scale = true, position = point, showOwnAuraTimers = true, showThreat = true},
    companion = frame, castBar = frame,
    party = {enabled = true, scale = true, position = point, replaceBlizzard = true, compact = true,
        showPortrait = true, showMissingBuff = true},
    xp = {enabled = true, scale = true, position = point, width = true, showAtCap = true,
        questDisplay = true, restedDisplay = true},
    actionBars = {enabled = true, opacity = true, hideEmpty = true},
    inventory = {enabled = true, opacity = true},
    comfort = {autoRepair = true, sellJunk = true, tooltipItemLevel = true},
    minimapButton = {angle = true, collect = true},
    hunter = classLayout("aspectGroup", "petGroup"),
    paladin = classLayout("auraGroup", "blessingGroup", "weaponGroup", "macroGroup", "friendlyGroup"),
    warlock = classLayout("summonGroup", "macroGroup", "friendlyGroup"),
    priest = classLayout("buffGroup", "supportGroup", "macroGroup"),
    mage = classLayout("buffGroup", "utilityGroup", "interruptGroup"),
    shaman = classLayout("totemGroup", "buffGroup", "utilityGroup", "interruptGroup"),
    druid = classLayout("buffGroup"),
    rogue = classLayout("interruptGroup"),
    warrior = classLayout("stanceGroup", "interruptGroup"),
}

local function copyFields(source, destination, allowed)
    for key, rule in pairs(allowed) do
        local value = source[key]
        local kind = type(value)
        if rule == true then
            if kind == "boolean" or kind == "number" or kind == "string" then
                destination[key] = value
            end
        elseif rule == "spellIDs" and kind == "table" then
            destination[key] = ns.Settings.LoadPriorityAuras(value)
        elseif kind == "table" then
            local target = destination[key]
            if type(target) ~= "table" then
                target = {}
                destination[key] = target
            end
            copyFields(value, target, rule)
        end
    end
end

function Profiles.Name(value)
    if type(value) ~= "string" then return end
    local name = value:match("^%s*(.-)%s*$")
    if name ~= "" and #name <= 64 and not name:find("[|%c]") then return name end
end

function Profiles.Init(saved)
    profiles = {}
    if type(saved) == "table" and type(saved.profiles) == "table" then
        for name, data in pairs(saved.profiles) do
            local validName = Profiles.Name(name)
            if validName and validName == name and type(data) == "table" then
                profiles[name] = {}
                copyFields(data, profiles[name], fields)
            end
        end
    end
    return {profiles = profiles}
end

function Profiles.Exists(value)
    local name = Profiles.Name(value)
    return name ~= nil and profiles[name] ~= nil
end

function Profiles.List()
    local names = {}
    for name in pairs(profiles) do names[#names + 1] = name end
    table.sort(names)
    return names
end

function Profiles.Save(value, current)
    local name = Profiles.Name(value)
    if not name then return end
    local snapshot = {}
    copyFields(current, snapshot, fields)
    profiles[name] = snapshot
    return name
end

function Profiles.Apply(value, current)
    local name = Profiles.Name(value)
    local snapshot = name and profiles[name]
    if not snapshot then return false end

    local candidate = {}
    copyFields(current, candidate, fields)
    copyFields(snapshot, candidate, fields)
    -- These coordinates already use the compact layout. Do not repeat the legacy migration.
    candidate.hunter = candidate.hunter or {}
    candidate.hunter.compactLayout = true
    copyFields(ns.Settings.Load(candidate), current, fields)
    return true
end
