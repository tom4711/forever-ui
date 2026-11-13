local _,ns=...
local R,M=ns.Read,ns.HunterModel
local A=ns.HunterActionModel
ns.Hunter={}
local view,events,isHunter,previousLow
local ammoCount,ammoIcon
local function boolean(fn,...)return R.Boolean(R.Call(fn,...))end
local function number(fn,...)return R.Number(R.Call(fn,...))end
local function range()
    local exists=boolean(UnitExists,"target")
    if exists==false then return "none" end
    local attack=boolean(UnitCanAttack,"player","target")
    local dead=boolean(UnitIsDead,"target")
    local valid
    if exists==false or attack==false or dead==true then valid=false
    elseif exists==true and attack==true and dead==false then valid=true end
    if valid~=true then return M.ResolveZone(valid)end
    return M.ResolveZone(valid,
        boolean(C_Spell and C_Spell.IsSpellInRange,75,"target"),
        boolean(C_Item and C_Item.IsItemInRange,8149,"target"),
        boolean(CheckInteractDistance,"target",3))
end
local function updateAmmo()
    local ok,id=R.Try(GetInventoryItemID,"player",INVSLOT_AMMO or 0)
    if not ok then ammoCount=nil;ammoIcon=nil;return end
    if id==nil then ammoCount=0;ammoIcon=nil;return end
    ammoCount=number(GetInventoryItemCount,"player",INVSLOT_AMMO or 0)
    ammoIcon=R.Call(GetInventoryItemTexture,"player",INVSLOT_AMMO or 0)
end
local function update()
    if not view or not view.frame:IsShown() then return end
    local low,warn=M.AmmoTransition(previousLow,ammoCount,ns.db.hunter.ammoWarning)
    previousLow=low
    if warn then
        local message=string.format(ns.L.AMMO_LOW,ns.Format.Number(ammoCount))
        ns.Print(message)
        if UIErrorsFrame then UIErrorsFrame:AddMessage(message,1,0.3,0.2,1)end
    end
    view.Render({zone=range(),ammoCount=ammoCount,ammoIcon=ammoIcon,ammoLow=low,
        petState=M.ResolvePet(boolean(UnitExists,"pet"),boolean(UnitIsDeadOrGhost,"pet"),
            number(C_PetInfo and C_PetInfo.GetPetHappiness))})
end
function ns.Hunter.Refresh()
    if not view then return end
    local visible=isHunter and ns.db.hunter.enabled and not ns.Preview.IsEnabled()
    ns.UI.Place(view.frame,"hunter");view.frame:SetShown(visible)
    if visible then updateAmmo();update()end
    if ns.HunterFeed then ns.HunterFeed.Refresh(ns.db.hunter)end
    if ns.HunterActions then
        local learned={}
        for _,group in ipairs(A.SpellIDs)do
            for _,id in ipairs(group.spells)do learned[id]=boolean(IsPlayerSpell,id)==true or boolean(IsSpellKnown,id)==true end
        end
        ns.HunterActions.Refresh(ns.db.hunter,A.Aspects(learned),view.frame,ns.Preview.IsEnabled())
    end
end
function ns.Hunter.GetFrame()return view and view.frame end
function ns.Hunter.Init()
    local _,class=UnitClass("player");isHunter=class=="HUNTER"
    if not isHunter then return end
    previousLow=false
    view=ns.HunterView.Create("ForeverUI_Hunter",false)
    if C_Item and C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(8149)end
    events=CreateFrame("Frame")
    for _,event in ipairs({"PLAYER_TARGET_CHANGED","BAG_UPDATE_DELAYED","PLAYER_EQUIPMENT_CHANGED","UNIT_PET","UNIT_FLAGS","PLAYER_ENTERING_WORLD","GET_ITEM_INFO_RECEIVED","SPELLS_CHANGED","LEARNED_SPELL_IN_TAB"})do events:RegisterEvent(event)end
    events:SetScript("OnEvent",function(_,event)
        if event=="BAG_UPDATE_DELAYED" or event=="PLAYER_EQUIPMENT_CHANGED" or event=="PLAYER_ENTERING_WORLD" then updateAmmo()end
        if event=="SPELLS_CHANGED" or event=="LEARNED_SPELL_IN_TAB" then ns.Hunter.Refresh() else update() end
    end)
    local elapsed=0
    events:SetScript("OnUpdate",function(_,dt)
        if not view.frame:IsShown() then return end
        elapsed=elapsed+dt
        if elapsed>=0.2 then elapsed=0;update()end
    end)
    ns.Hunter.Refresh()
    if ns.HunterFeed then ns.HunterFeed.Init()end
end
