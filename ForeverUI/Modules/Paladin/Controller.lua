local _,ns=...
local R,M=ns.Read,ns.PaladinModel
ns.Paladin={}
local view,events,isPaladin
local function boolean(fn,...)return R.Boolean(R.Call(fn,...))end
local function equipmentName(id)
    if type(id)~="number"or not C_EquipmentSet or type(C_EquipmentSet.GetEquipmentSetIDs)~="function"or type(C_EquipmentSet.GetEquipmentSetInfo)~="function"then return nil end
    local ok,ids=R.Try(C_EquipmentSet.GetEquipmentSetIDs)
    if not ok or type(ids)~="table"then return nil end
    local found=false
    for _,candidate in ipairs(ids)do if candidate==id then found=true;break end end
    if not found then return nil end
    local success,name=R.Try(C_EquipmentSet.GetEquipmentSetInfo,id)
    if success and type(name)=="string"and name~=""then return name end
end
local function auraState(actions)
    return M.ActiveAura(actions,function(id)
        local api=C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID
        if type(api)~="function"then return nil end
        local ok,aura=R.Try(api,id)
        if not ok then return nil end
        return aura~=nil
    end)
end
local function readState()
    local config=ns.db.paladin
    local learned={}
    for _,group in ipairs(M.SpellGroups)do for _,id in ipairs(group.spells)do learned[id]=R.SpellKnown(id)end end
    local actions=M.Actions(learned)
    local shieldName=equipmentName(config.weaponSets and config.weaponSets.shield)
    local twoHandName=equipmentName(config.weaponSets and config.weaponSets.twoHand)
    local macro=M.EquipmentMacro(shieldName,twoHandName)
    local shieldQuery=C_Item and C_Item.IsEquippedItemType
    if type(shieldQuery)~="function"then shieldQuery=IsEquippedItemType end
    local hasShield=boolean(shieldQuery,"Shields")
    local data={visible=config.enabled==true and not ns.Preview.IsEnabled(),shield=hasShield,activeAura=auraState(actions),
        shieldState=hasShield==nil and "unknown"or hasShield and "shield"or "twohand"}
    return config,actions,macro,data
end
function ns.Paladin.Refresh()
    if not isPaladin then return end
    local config,actions,macro,data=readState()
    local preview=ns.Preview.IsEnabled()
    if view.RenderStatus then view.RenderStatus(data)end
    ns.CombatQueue.Request("paladin",function()view.RenderActions(data,actions,macro,preview,config)end)
end
function ns.Paladin.Init()
    local _,class=UnitClass("player")
    isPaladin=class=="PALADIN"
    if not isPaladin then return end
    view=ns.PaladinView.Create("ForeverUI_Paladin")
    events=CreateFrame("Frame")
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_EQUIPMENT_CHANGED","EQUIPMENT_SETS_CHANGED","UNIT_AURA","SPELLS_CHANGED","LEARNED_SPELL_IN_SKILL_LINE"})do events:RegisterEvent(event)end
    events:SetScript("OnEvent",function(_,event,unit)
        if event=="UNIT_AURA"and unit~="player"then return end
        ns.Paladin.Refresh()
    end)
    ns.Paladin.Refresh()
end
