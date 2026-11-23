local _,ns=...
local R,M=ns.Read,ns.WarlockModel
ns.Warlock={}
local view,events,isWarlock
local function boolean(fn,...)return R.Boolean(R.Call(fn,...))end
local function number(fn,...)return R.Number(R.Call(fn,...))end
local function itemCount(id)
    local api=C_Item and C_Item.GetItemCount
    if type(api)=="function"then
        local ok,count=R.Try(api,id,false,false,false,false)
        if ok and type(count)=="number"then return count end
    end
    return R.Call(GetItemCount,id,false,false)
end
local function readState()
    local config=ns.db.warlock
    local demon=M.DemonState(boolean(UnitExists,"pet"),boolean(UnitIsDeadOrGhost,"pet"),R.Call(UnitName,"pet"),number(UnitHealth,"pet"),number(UnitHealthMax,"pet"))
    local shards=M.SoulShards(itemCount(6265))
    local learned={}
    for _,spell in ipairs(M.SummonSpells)do learned[spell.spellID]=R.SpellKnown(spell.spellID)end
    for _, action in ipairs(M.QuickSpells) do
        for _, id in ipairs(action.ranks) do learned[id] = R.SpellKnown(id) end
    end
    local data = {visible = config.enabled == true and not ns.Preview.IsEnabled(), demon = demon, shards = shards,
        quickActions = M.QuickActions(learned), knowsBreath = R.SpellKnown(5697)}
    return data, M.SummonActions(learned)
end
function ns.Warlock.Refresh()
    if not isWarlock then return end
    local data,actions=readState()
    local preview=ns.Preview.IsEnabled()
    if view.RenderStatus then view.RenderStatus(data)end
    ns.CombatQueue.Request("warlock",function()
        view.RenderActions(data,actions,preview)
        if not view.frame.dragging then ns.UI.Place(view.frame,"warlock") end
    end)
end
function ns.Warlock.Init()
    local _,class=UnitClass("player")
    isWarlock=class=="WARLOCK"
    if not isWarlock then return end
    view=ns.WarlockView.Create("ForeverUI_Warlock")
    events=CreateFrame("Frame")
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","UNIT_PET","UNIT_HEALTH","UNIT_MAXHEALTH","UNIT_FLAGS","BAG_UPDATE_DELAYED","SPELLS_CHANGED","LEARNED_SPELL_IN_SKILL_LINE"})do events:RegisterEvent(event)end
    events:SetScript("OnEvent",function(_,event,unit)
        if event=="UNIT_PET"and unit~="player"then return end
        if (event=="UNIT_HEALTH"or event=="UNIT_MAXHEALTH"or event=="UNIT_FLAGS")and unit~="pet"then return end
        ns.Warlock.Refresh()
    end)
    ns.Warlock.Refresh()
end
