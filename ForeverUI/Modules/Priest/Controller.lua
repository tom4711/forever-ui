local _,ns=...
local R,M=ns.Read,ns.PriestModel
ns.Priest={}
local view,events,isPriest
local function boolean(fn,...)return R.Boolean(R.Call(fn,...))end
local function known(spellID)
    local spellbook=C_SpellBook
    if spellbook and type(spellbook.IsSpellKnown)=="function"and boolean(spellbook.IsSpellKnown,spellID)==true then return true end
    return boolean(IsPlayerSpell,spellID)==true or boolean(IsSpellKnown,spellID)==true
end
local function auraQuery(spellID)
    local api=C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
    if type(api)~="function"then return nil end
    local ok,aura=R.Try(api,spellID)
    if not ok then return nil end
    return aura~=nil
end
local function hasFortitude(unit)
    local getAura = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    if not getAura then return nil end
    local incomplete = boolean(C_Secrets and C_Secrets.ShouldAurasBeSecret) == true
    for index = 1, 80 do
        local ok, aura = R.Try(getAura, unit, index, "HELPFUL")
        if not ok then return nil end
        if aura == nil then
            if not incomplete then return false end
            return nil
        end
        if type(aura) ~= "table" then return nil end
        local id = R.Number(R.Call(function() return aura.spellId end))
        if id then
            if M.IsFortitudeAura(id) then return true end
        else
            incomplete = true
        end
    end
    return nil
end

local function updateFortitudeHint()
    local spellID = view.GetFortitudeSpell()
    if not spellID then return end
    local unit = "mouseover"
    local canAssist = boolean(UnitCanAssist, "player", unit)
    local dead = boolean(UnitIsDeadOrGhost, unit)
    if boolean(UnitExists, unit) == false or canAssist == false or dead == true then
        view.RenderFortitudeHint()
        return
    end
    local name = R.Call(UnitName, unit)
    if canAssist == nil or dead == nil then
        view.RenderFortitudeHint(true, name)
        return
    end
    local inRange = boolean(C_Spell and C_Spell.IsSpellInRange, spellID, unit)
    view.RenderFortitudeHint(true, name, inRange, hasFortitude(unit))
end

local function readState()
    local config=ns.db.priest
    local learned={}
    for _,entry in ipairs(M.SpellActions)do
        for _,spellID in ipairs(entry.spells)do learned[spellID]=known(spellID)end
    end
    local actions=M.Actions(learned)
    local buffs=M.ActiveBuffs(actions.buffs,auraQuery)
    local data = {visible = config.enabled == true and not ns.Preview.IsEnabled()}
    return config,actions,buffs,data
end
function ns.Priest.Refresh()
    if not isPriest then return end
    local config,actions,buffs,data=readState()
    local preview=ns.Preview.IsEnabled()
    ns.CombatQueue.Request("priest",function()
        view.RenderActions(data,actions,buffs,preview,config)
        if not view.frame.dragging then ns.UI.Place(view.frame,"priest") end
    end)
end
function ns.Priest.Init()
    local _,class=UnitClass("player")
    isPriest=class=="PRIEST"
    if not isPriest then return end
    view=ns.PriestView.Create("ForeverUI_Priest")
    local elapsed = 0
    view.groups.macros:SetScript("OnShow", function()
        elapsed = 0
        updateFortitudeHint()
    end)
    view.groups.macros:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed < 0.25 then return end
        elapsed = 0
        updateFortitudeHint()
    end)
    events=CreateFrame("Frame")
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","UNIT_AURA","SPELLS_CHANGED","LEARNED_SPELL_IN_SKILL_LINE"})do events:RegisterEvent(event)end
    events:SetScript("OnEvent",function(_,event,unit)
        if event == "UNIT_AURA" and unit ~= "player" then return end
        ns.Priest.Refresh()
    end)
    ns.Priest.Refresh()
end
