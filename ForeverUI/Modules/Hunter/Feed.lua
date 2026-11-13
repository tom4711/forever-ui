local _,ns=...
local R,UI,T=ns.Read,ns.UI,ns.Theme
ns.HunterFeed={}
local button,events,dragging
local requested={}
local function number(fn,...)return R.Number(R.Call(fn,...))end
local function boolean(fn,...)return R.Boolean(R.Call(fn,...))end
local function itemName(id)
    if not id then return nil end
    local name=R.Call(C_Item and C_Item.GetItemNameByID,id)
    if type(name)=="string" and name~=""then return name end
    if not requested[id] and C_Item and C_Item.RequestLoadItemDataByID then
        requested[id]=true;C_Item.RequestLoadItemDataByID(id)
    end
end
local function count(id)
    if not id then return 0 end
    return number(C_Item and C_Item.GetItemCount,id,false,false,false,false)
end
local function currentState()
    local id=ns.db.hunter.food
    local name=itemName(id)
    local amount=count(id)
    local state=ns.FoodModel.State({known=boolean(IsPlayerSpell,6991),petExists=boolean(UnitExists,"pet"),
        petDead=boolean(UnitIsDeadOrGhost,"pet"),foodID=id,name=name,count=amount,
        canEat=id and boolean(C_PetInfo and C_PetInfo.CanPetEatItem,id)})
    return state,name,amount
end
local function updateCount()
    if not button then return end
    local id=ns.db.hunter.food
    local state,_,amount=currentState()
    button.icon:SetTexture(id and R.Call(C_Item and C_Item.GetItemIconByID,id) or T.icons.food)
    button.icon:SetDesaturated(state~="ready")
    button.count:SetText(id and ns.Format.Number(amount) or "")
end
function ns.HunterFeed.Foods()
    if boolean(UnitExists,"pet")~=true then return {}end
    local items={}
    for bag=0,NUM_BAG_SLOTS or 4 do
        local slots=number(C_Container and C_Container.GetContainerNumSlots,bag)or 0
        for slot=1,slots do
            local info=R.Call(C_Container and C_Container.GetContainerItemInfo,bag,slot)
            if type(info)=="table"then
                local id=R.Number(info.itemID)
                if id then
                    items[#items+1]={id=id,count=R.Number(info.stackCount),icon=R.Call(C_Item and C_Item.GetItemIconByID,id),
                        name=itemName(id),canEat=boolean(C_PetInfo and C_PetInfo.CanPetEatItem,id)}
                end
            end
        end
    end
    return ns.FoodModel.Filter(items)
end
local function choose(id)
    if InCombatLockdown()then ns.Print(ns.L.COMBAT);return end
    ns.db.hunter.food=id
    ns.HunterFeed.Refresh(ns.db.hunter)
end
function ns.HunterFeed.ShowMenu(anchor)
    if InCombatLockdown()then ns.Print(ns.L.COMBAT);return end
    if not MenuUtil or not MenuUtil.CreateContextMenu then ns.Print(ns.L.MENU_UNAVAILABLE);return end
    MenuUtil.CreateContextMenu(anchor or button,function(_,root)
        root:CreateTitle(ns.L.FOOD)
        if boolean(UnitExists,"pet")==false then root:CreateButton(ns.L.FEED_STATE_missing):SetEnabled(false);return end
        if boolean(UnitIsDeadOrGhost,"pet")==true then root:CreateButton(ns.L.FEED_STATE_dead):SetEnabled(false);return end
        local foods=ns.HunterFeed.Foods()
        for _,entry in ipairs(foods)do
            local label=entry.name or ns.L.ITEM_LOADING
            label=label.." ("..ns.Format.Number(entry.count)..")"
            if entry.ready then
                local id=entry.id
                root:CreateRadio(label,function()return ns.db.hunter.food==id end,function()choose(id)end)
            else root:CreateButton(label):SetEnabled(false)end
        end
        if #foods==0 then root:CreateButton(ns.L.NO_FOOD):SetEnabled(false)end
    end)
end
local function create()
    button=CreateFrame("Button","ForeverUI_Feed",UIParent,"SecureActionButtonTemplate")
    button:SetSize(48,48);UI.Decorate(button)
    button.icon=button:CreateTexture(nil,"ARTWORK");button.icon:SetPoint("TOPLEFT",6,-6);button.icon:SetPoint("BOTTOMRIGHT",-6,6);button.icon:SetTexCoord(0.07,0.93,0.07,0.93)
    button.count=UI.Text(button,11,T.text);button.count:SetPoint("BOTTOMRIGHT",-5,5)
    button:RegisterForClicks("LeftButtonUp","RightButtonUp")
    button:SetAttribute("useOnKeyDown",false)
    button:SetAttribute("spell",6991)
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    button:SetClampedToScreen(true)
    button:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_TOP");GameTooltip:SetText(ns.L.FEED,1,0.82,0.42)
        local state,name=currentState()
        if name then GameTooltip:AddLine(name,0.79,0.85,0.84,true)end
        GameTooltip:AddLine(state=="ready" and ns.L.FEED_HINT or ns.L["FEED_STATE_"..state],0.79,0.85,0.84,true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function()GameTooltip:Hide()end)
    button:SetScript("PostClick",function(_,mouse)
        if mouse=="RightButton"then ns.HunterFeed.ShowMenu(button)
        else
            local state=currentState()
            if state~="ready"then ns.Print(ns.L["FEED_STATE_"..state])end
        end
    end)
    button:Hide()
end
function ns.HunterFeed.Refresh(config)
    ns.CombatQueue.Request("feed",function()
        if not button then create()end
        config=ns.db.hunter
        local id=config.food
        local state,name=currentState()
        local ready=state=="ready"
        button:SetAttribute("type1",ready and "spell"or nil)
        button:SetAttribute("target-item",ready and name or nil)
        button:ClearAllPoints();button:SetScale(config.scale)
        local anchor=ns.Hunter.GetFrame()
        local p=anchor and ns.FoodModel.FeedPosition({left=R.Number(anchor:GetLeft()),top=R.Number(anchor:GetTop()),
            scale=R.Number(anchor:GetEffectiveScale()),parentScale=R.Number(UIParent:GetEffectiveScale()),
            parentLeft=R.Number(UIParent:GetLeft()),parentBottom=R.Number(UIParent:GetBottom())})
        if not p then button:Hide();return end
        button:SetPoint(p.point,UIParent,p.relativePoint,p.x,p.y)
        button:SetShown(config.enabled and not dragging and not ns.Preview.IsEnabled() and boolean(IsPlayerSpell,6991)==true)
        updateCount()
    end)
end
function ns.HunterFeed.SetDragging(value)
    dragging=value;ns.HunterFeed.Refresh(ns.db.hunter)
end
function ns.HunterFeed.Init()
    events=CreateFrame("Frame")
    for _,event in ipairs({"BAG_UPDATE_DELAYED","GET_ITEM_INFO_RECEIVED","SPELLS_CHANGED","UNIT_PET","UNIT_FLAGS","PLAYER_ENTERING_WORLD"})do events:RegisterEvent(event)end
    events:SetScript("OnEvent",function(_,event,unit)
        if event=="UNIT_FLAGS" and unit~="pet"then return end
        if event=="GET_ITEM_INFO_RECEIVED" and unit~=ns.db.hunter.food then return end
        updateCount();ns.HunterFeed.Refresh(ns.db.hunter)
    end)
    ns.HunterFeed.Refresh(ns.db.hunter)
end
