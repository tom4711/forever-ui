local _, ns = ...
local B = {}
ns.Bindings = B

local catalog = {
    HUNTER = {
        {"HunterMend", "MEND_PET"},
        {"HunterRevive", "REVIVE_PET"},
        {"HunterCall", "CALL_PET"},
        {"HunterDismiss", "DISMISS_PET"},
        {"HunterFeed", "FEED"},
        {"HunterMarkAttack", "HUNTER_MARK_ATTACK"},
    },
    PALADIN = {
        {"PaladinProtection", "BIND_PROTECTION_SELF"},
        {"PaladinFreedom", "BIND_FREEDOM_SELF"},
        {"PaladinWeapons", "WEAPON_SET"},
        {"PaladinMight", "BIND_MIGHT"},
        {"PaladinWisdom", "BIND_WISDOM"},
        {"PaladinKings", "BIND_KINGS"},
    },
    WARLOCK = {
        {"WarlockFunnel", "WARLOCK_HEALTH_FUNNEL"},
        {"WarlockHealthstone", "WARLOCK_HEALTHSTONE"},
        {"WarlockBreath", "BIND_UNENDING_BREATH"},
    },
    PRIEST = {
        {"PriestFortitudeNearby", "BIND_FORTITUDE_NEARBY"},
        {"PriestFortitudeSelf", "BIND_FORTITUDE_SELF"},
        {"PriestShieldSelf", "BIND_SHIELD_SELF"},
        {"PriestRenewSelf", "BIND_RENEW_SELF"},
        {"PriestShieldMouseover", "BIND_SHIELD_MOUSEOVER"},
        {"PriestRenewMouseover", "BIND_RENEW_MOUSEOVER"},
        {"PriestShadowProtection", "BIND_SHADOW_PROTECTION"},
        {"PriestSpirit", "BIND_DIVINE_SPIRIT"},
        {"PriestSilence", "PRIEST_SILENCE"},
    },
    MAGE = {
        {"MageIntellect", "BIND_ARCANE_INTELLECT"},
        {"MageCounterspell", "MAGE_COUNTERSPELL"},
    },
    SHAMAN = {
        {"ShamanWaterWalking", "BIND_WATER_WALKING"},
        {"ShamanWaterBreathing", "BIND_WATER_BREATHING"},
        {"ShamanEarthShock", "SHAMAN_EARTH_SHOCK"},
    },
    DRUID = {
        {"DruidMark", "BIND_MARK_OF_THE_WILD"},
        {"DruidThorns", "BIND_THORNS"},
    },
    ROGUE = {{"RogueKick", "ROGUE_KICK"}},
    WARRIOR = {
        {"WarriorBattle", "BATTLE_STANCE"},
        {"WarriorDefensive", "DEFENSIVE_STANCE"},
        {"WarriorBerserker", "BERSERKER_STANCE"},
        {"WarriorPummel", "WARRIOR_PUMMEL"},
        {"WarriorShieldBash", "WARRIOR_SHIELD_BASH"},
    },
}
local actionIDs = {}
for _, actions in pairs(catalog) do
    for _, action in ipairs(actions) do actionIDs[action[1]] = true end
end

local ignored = {
    UNKNOWN = true, ESCAPE = true, LSHIFT = true, RSHIFT = true, LCTRL = true, RCTRL = true,
    LALT = true, RALT = true, LMETA = true, RMETA = true, SHIFT = true, CTRL = true, ALT = true, META = true,
}
local function validKey(key)
    if type(key) ~= "string" or key == "" or #key > 48 or key:find("[%c%s]") then return false end
    local base = key
    for _, prefix in ipairs({"ALT-", "CTRL-", "SHIFT-", "META-"}) do
        if base:sub(1, #prefix) == prefix then base = base:sub(#prefix + 1) end
    end
    return base ~= "" and not ignored[base]
end

function B.Load(saved)
    local result, used = {}, {}
    if type(saved) ~= "table" then return result end
    for _, actions in pairs(catalog) do
        for _, action in ipairs(actions) do
            local id = action[1]
            local key = saved[id]
            if validKey(key) and not used[key] then
                result[id], used[key] = key, true
            end
        end
    end
    return result
end

function B.Actions()
    local _, class = UnitClass("player")
    return catalog[class] or {}
end

function B.ReadKey(key)
    if not validKey(key) then return nil end
    local alt = IsAltKeyDown() and "ALT-" or ""
    local ctrl = IsControlKeyDown() and "CTRL-" or ""
    local shift = IsShiftKeyDown() and "SHIFT-" or ""
    local meta = IsMetaKeyDown and IsMetaKeyDown() and "META-" or ""
    return alt .. ctrl .. shift .. meta .. key
end

local owner, sequence, applying = nil, 0, false
local buttons, applied = {}, {}

function B.ButtonName(id)
    if not actionIDs[id] then return nil end
    sequence = sequence + 1
    return "ForeverUI_Bind_" .. id .. "_" .. sequence
end

function B.Watch(id, button)
    if actionIDs[id] then buttons[id] = button end
end

local function clickCommand(name)
    return "CLICK " .. name .. ":LeftButton"
end

local function conflict(key)
    local normal = GetBindingAction(key)
    if normal and normal ~= "" then return true end
    local effective = GetBindingAction(key, true)
    return effective and effective ~= "" and (not applied[key] or effective ~= clickCommand(applied[key]))
end

local function sameBindings(a, b)
    for key, name in pairs(a) do if b[key] ~= name then return false end end
    for key, name in pairs(b) do if a[key] ~= name then return false end end
    return true
end

local function refresh()
    if not owner or applying then return end
    local nextBindings = {}
    for id, key in pairs(ns.db.bindings) do
        local button = buttons[id]
        if button and button:IsVisible() and not conflict(key) then
            nextBindings[key] = button:GetName()
        end
    end
    if sameBindings(applied, nextBindings) then return end

    applying = true
    ClearOverrideBindings(owner)
    applied = {}
    for key, name in pairs(nextBindings) do
        if not conflict(key) and SetOverrideBindingClick(owner, false, key, name, "LeftButton") ~= false then
            applied[key] = name
        end
    end
    applying = false
end

function B.Refresh()
    if owner and not applying then ns.CombatQueue.Request("keybindings", refresh) end
end

function B.Set(id, key)
    if InCombatLockdown() then return false, ns.L.BIND_COMBAT end
    if not owner or not actionIDs[id] then return false, ns.L.BIND_UNAVAILABLE end
    if key then
        if not validKey(key) then return false, ns.L.BIND_UNAVAILABLE end
        if conflict(key) then return false, ns.L.BIND_CONFLICT end
        for action, assigned in pairs(ns.db.bindings) do
            if action ~= id and assigned == key then return false, ns.L.BIND_CONFLICT end
        end
    end
    ns.db.bindings[id] = key
    B.Refresh()
    return true
end

function B.Status(id)
    local key = ns.db.bindings[id]
    if not key then return nil end
    if not owner then return ns.L.BIND_UNAVAILABLE end
    if conflict(key) then return ns.L.BIND_CONFLICT end
    if not applied[key] then return ns.L.BIND_INACTIVE end
end

function B.Init()
    if owner or not (GetBindingAction and SetOverrideBindingClick and ClearOverrideBindings) then return end
    owner = CreateFrame("Frame")
    owner:RegisterEvent("UPDATE_BINDINGS")
    owner:SetScript("OnEvent", function()
        if applying then return end
        B.Refresh()
        if ns.Options then ns.Options.Refresh() end
    end)
    B.Refresh()
end
