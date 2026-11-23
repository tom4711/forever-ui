local _, ns = ...
local UI, T, R = ns.UI, ns.Theme, ns.Read
local S = {}
ns.ClassSupport = S

local classes = {
    MAGE = {module = "mage", label = "MAGE", groups = {
        {key = "buffGroup", label = "FRIENDLY_BUFFS", spells = {
            {friendlyBinding = "MageIntellect", ranks = {1459, 1460, 1461, 10156, 10157}},
        }},
        {key = "utilityGroup", label = "CLASS_UTILITY", spells = {
            {key = "frostArmor", self = true, ranks = {168, 7300, 7301, 7302, 7320, 10219, 10220}},
            {key = "mageArmor", self = true, ranks = {6117, 22782, 22783}},
            {key = "conjureWater", ranks = {5504, 5505, 5506, 6127, 10138, 10139, 10140}},
            {key = "conjureFood", ranks = {587, 597, 990, 6129, 10144, 10145, 28612}},
            {key = "removeCurse", ranks = {475}},
        }},
        {key = "interruptGroup", label = "INTERRUPTS", spells = {
            {key = "counterspell", binding = "MageCounterspell", interrupt = true, ranks = {2139}},
        }},
    }},
    SHAMAN = {module = "shaman", label = "SHAMAN", groups = {
        {key = "totemGroup", label = "SHAMAN_TOTEMS", spells = {
            {key = "callElements", ranks = {66842}},
            {key = "callAncestors", ranks = {66843}},
            {key = "callSpirits", ranks = {66844}},
            {key = "recallTotems", ranks = {36936}},
            {key = "strengthTotem", ranks = {8075, 8160, 8161, 10442, 25361}},
            {key = "searingTotem", ranks = {3599, 6363, 6364, 6365, 10437, 10438}},
            {key = "healingTotem", ranks = {5394, 6375, 6377, 10462, 10463}},
            {key = "manaTotem", ranks = {5675, 10495, 10496, 10497}},
            {key = "windfuryTotem", ranks = {8512, 10613, 10614}},
            {key = "tremorTotem", ranks = {8143}},
        }},
        {key = "buffGroup", label = "FRIENDLY_BUFFS", spells = {
            {friendlyBinding = "ShamanWaterWalking", ranks = {546}},
            {friendlyBinding = "ShamanWaterBreathing", ranks = {131}},
        }},
        {key = "utilityGroup", label = "CLASS_UTILITY", spells = {
            {key = "lightningShield", self = true, ranks = {324, 325, 905, 945, 8134, 10431, 10432}},
            {key = "ghostWolf", ranks = {2645}},
            {key = "curePoison", ranks = {526}},
            {key = "cureDisease", ranks = {2870}},
        }},
        {key = "interruptGroup", label = "INTERRUPTS", spells = {
            {key = "earthShock", binding = "ShamanEarthShock", interrupt = true,
                ranks = {8042, 8044, 8045, 8046, 10412, 10413, 10414}},
        }},
    }},
    DRUID = {module = "druid", label = "DRUID", groups = {
        {key = "buffGroup", label = "FRIENDLY_BUFFS", spells = {
            {friendlyBinding = "DruidMark", ranks = {1126, 5232, 6756, 5234, 8907, 9884, 9885}},
            {friendlyBinding = "DruidThorns", ranks = {467, 782, 1075, 8914, 9756, 9910}},
        }},
    }},
    ROGUE = {module = "rogue", label = "ROGUE", groups = {
        {key = "interruptGroup", label = "INTERRUPTS", spells = {
            {key = "kick", binding = "RogueKick", interrupt = true, ranks = {1766, 1767, 1768, 1769}},
        }},
    }},
    WARRIOR = {module = "warrior", label = "WARRIOR", groups = {
        {key = "stanceGroup", label = "STANCES", spells = {
            {key = "battle", binding = "WarriorBattle", ranks = {2457}},
            {key = "defensive", binding = "WarriorDefensive", ranks = {71}},
            {key = "berserker", binding = "WarriorBerserker", ranks = {2458}},
        }},
        {key = "interruptGroup", label = "INTERRUPTS", spells = {
            {key = "pummel", binding = "WarriorPummel", interrupt = true, ranks = {6552, 6554}},
            {key = "shieldBash", binding = "WarriorShieldBash", interrupt = true, ranks = {72, 1671, 1672}},
        }},
    }},
}

local stanceNames = {[2457] = "BATTLE_STANCE", [71] = "DEFENSIVE_STANCE", [2458] = "BERSERKER_STANCE"}
local comboPower = Enum and Enum.PowerType and Enum.PowerType.ComboPoints or 4

local function secret(value)
    return issecretvalue and issecretvalue(value)
end

local function pointValue(fn, ...)
    local ok, value = pcall(fn, ...)
    if not ok then return end
    if secret(value) then return value end
    return R.Number(value)
end

local function comboPoints()
    local current = pointValue(GetComboPoints, "player", "target")
    if not secret(current) and current == nil then current = pointValue(UnitPower, "player", comboPower) end
    local maximum = pointValue(UnitPowerMax, "player", comboPower)
    if not secret(maximum) and (not maximum or maximum <= 0) then maximum = 5 end
    return current, maximum
end

local function activeStance()
    local index = R.Number(R.Call(GetShapeshiftForm))
    if not index or index < 1 or not GetShapeshiftFormInfo then return end
    local ok, _, active, _, spellID = pcall(GetShapeshiftFormInfo, index)
    if ok and R.Boolean(active) == true then return R.Number(spellID) end
end

local function actions(group, preview)
    local entries = {}
    for _, spell in ipairs(group.spells) do
        for rank = #spell.ranks, 1, -1 do
            local id = spell.ranks[rank]
            if preview or R.SpellKnown(id) then
                local entry
                if spell.friendlyBinding then
                    entry = ns.FriendlyBuffs.Entry(spell.friendlyBinding, id, preview)
                else
                    entry = {key = spell.key, spellID = id, bindingID = spell.binding,
                        unit = spell.self and "player" or nil, interrupt = spell.interrupt}
                end
                if entry then entries[#entries + 1] = entry end
                break
            end
        end
    end
    return entries
end

local function createView(class, preview)
    local L = ns.L
    local root = UI.CreatePanel(UIParent, nil)
    root:SetSize(250, 31)
    local title = UI.Text(root, 13, T.goldLight)
    title:SetPoint("LEFT", 12, 0)
    title:SetText(L[class.label])
    UI.MakeMovable(root, class.module)
    root:Hide()
    local groups = {}
    for _, group in ipairs(class.groups) do
        groups[group.key] = UI.CreateClassGroup(root, class.module, group.key, L[group.label])
    end

    local status
    if class.module == "rogue" or class.module == "warrior" then
        status = UI.Text(root, 11, T.teal)
        status:SetPoint("RIGHT", -12, 0)
    end

    local function makeButton(parent, entry)
        local hint = entry.macro and L.PRIEST_MACRO_NEAR_HINT or L.CLASS_ACTION_HINT
        local button = UI.CreateClassAction(parent, entry, preview, T.icons.xp, L[class.label], hint)
        if stanceNames[entry.spellID] then button.activeOutline = UI.ActionOutline(button) end
        return button
    end

    local function updateStatus()
        if class.module == "rogue" then
            local current, maximum
            if preview then current, maximum = 3, 5 else current, maximum = comboPoints() end
            if secret(current) or secret(maximum) then
                if pcall(status.SetFormattedText, status, "%s %s/%s", L.COMBO_POINTS, current, maximum) then return end
                status:SetText(L.COMBO_POINTS .. " –")
            else
                local amount = current and (current .. "/" .. maximum) or "–"
                status:SetText(L.COMBO_POINTS .. " " .. amount)
            end
        elseif class.module == "warrior" then
            local id = preview and 2457 or activeStance()
            local name = id and L[stanceNames[id]]
            status:SetText(name or L.NO_ACTIVE_STANCE)
            for _, button in pairs(groups.stanceGroup.buttons) do
                UI.SetActionState(button.activeOutline, button.spellID == id and "active" or "inactive")
            end
        end
    end

    local totems
    if class.module == "shaman" then
        totems = ns.Totems.Create(root, preview)
        totems.frame:SetPoint("TOPLEFT", root, "TOPLEFT", 14, 72)
    end

    local function renderView(show)
        local config = ns.db[class.module]
        local visible = show and config.enabled
        local showRoot = false
        for _, group in ipairs(class.groups) do
            local settings = config[group.key]
            local entries = visible and settings.enabled and actions(group, preview) or {}
            UI.RenderClassGroup(groups[group.key], settings, entries, visible, makeButton)
            showRoot = showRoot or #entries > 0
        end
        local showTotems = totems and visible and config.showTotemStatus
        if totems then totems.Render(showTotems == true) end
        updateStatus()
        if not root.dragging then UI.Place(root, class.module) end
        root:SetShown(showRoot or (visible and status ~= nil) or showTotems == true)
        if not preview then ns.Bindings.Refresh() end
    end
    return renderView, updateStatus
end

local render, previewRender
function S.Refresh()
    if not render then return end
    ns.CombatQueue.Request("classSupport", function()
        render(not ns.Preview.IsEnabled())
    end)
end

function S.Preview(enabled, classToken)
    local class = classes[classToken]
    if not previewRender and enabled and class then previewRender = createView(class, true) end
    if previewRender then previewRender(enabled) end
end

function S.Init()
    local _, classToken = UnitClass("player")
    local class = classes[classToken]
    if not class then return end
    local updateStatus
    render, updateStatus = createView(class, false)
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("SPELLS_CHANGED")
    events:RegisterEvent("LEARNED_SPELL_IN_SKILL_LINE")
    if classToken == "ROGUE" then
        events:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
        events:RegisterUnitEvent("UNIT_MAXPOWER", "player")
        events:RegisterEvent("PLAYER_TARGET_CHANGED")
    elseif classToken == "WARRIOR" then
        events:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
        events:RegisterEvent("UPDATE_SHAPESHIFT_FORMS")
    end
    events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" or event == "SPELLS_CHANGED"
            or event == "LEARNED_SPELL_IN_SKILL_LINE" or event == "UPDATE_SHAPESHIFT_FORMS" then
            S.Refresh()
        else
            updateStatus()
        end
    end)
    S.Refresh()
end
