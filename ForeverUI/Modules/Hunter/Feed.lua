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
local function updateCount()
    if not button then return end
    local id=ns.db.hunter.food
    local amount=count(id)
    button.icon:SetTexture(id and R.Call(C_Item and C_Item.GetItemIconByID,id) or T.icons.food)
    button.icon:SetDesaturated(amount==nil or amount==0)
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
        local name=ns.db.hunter.food and R.Call(C_Item and C_Item.GetItemNameByID,ns.db.hunter.food)
        GameTooltip:AddLine(type(name)=="string" and name or ns.L.SELECT_FOOD,0.79,0.85,0.84,true)
        GameTooltip:AddLine(ns.L.FEED_HINT,0.79,0.85,0.84,true);GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function()GameTooltip:Hide()end)
    button:SetScript("PostClick",function(_,mouse)
        if mouse=="RightButton"then ns.HunterFeed.ShowMenu(button)
        elseif not ns.db.hunter.food then ns.Print(ns.L.SELECT_FOOD)
        elseif count(ns.db.hunter.food)==0 then ns.Print(ns.L.FOOD_EMPTY)end
    end)
    button:Hide()
end
function ns.HunterFeed.Refresh(config)
    ns.CombatQueue.Request("feed",function()
        if not button then create()end
        config=ns.db.hunter
        local id=config.food
        local name=itemName(id)
        local canEat=id and boolean(C_PetInfo and C_PetInfo.CanPetEatItem,id)
        local ready=name and canEat==true and (count(id)or 0)>0
        button:SetAttribute("type1",ready and "spell"or nil)
        button:SetAttribute("target-item",ready and name or nil)
        button:ClearAllPoints();button:SetScale(config.scale)
        local p=ns.FoodModel.FeedPosition(config.position)
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
    for _,event in ipairs({"BAG_UPDATE_DELAYED","GET_ITEM_INFO_RECEIVED","SPELLS_CHANGED","UNIT_PET","PLAYER_ENTERING_WORLD"})do events:RegisterEvent(event)end
    events:SetScript("OnEvent",function()updateCount();ns.HunterFeed.Refresh(ns.db.hunter)end)
    ns.HunterFeed.Refresh(ns.db.hunter)
end
