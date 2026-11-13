local _,ns=...
local UI,T=ns.UI,ns.Theme
ns.HunterView={}
function ns.HunterView.Create(name,preview)
    local L=ns.L
    local frame=UI.CreatePanel(UIParent,name);frame:SetSize(620,100)
    local portrait=UI.CreateIconButton(frame);portrait:SetPoint("TOPLEFT",18,-19);portrait:SetSize(62,62);portrait.icon:SetTexture(T.icons.hunter)
    local function label(size,color,x,y,value)
        local text=UI.Text(frame,size,color);text:SetPoint("TOPLEFT",x,y);text:SetText(value or "");return text
    end
    label(11,T.gold,98,-17,L.RANGE_LABEL)
    local range=label(23,T.goldLight,98,-35)
    local hint=label(12,T.good,98,-65);hint:SetWidth(265)
    label(11,T.muted,380,-23,L.AMMO)
    local ammoIcon=frame:CreateTexture(nil,"ARTWORK");ammoIcon:SetSize(17,17);ammoIcon:SetPoint("TOPLEFT",378,-49)
    local ammo=label(22,T.text,402,-43)
    label(11,T.muted,495,-23,L.PET)
    local moodIcon=frame:CreateTexture(nil,"ARTWORK");moodIcon:SetSize(17,17);moodIcon:SetPoint("TOPLEFT",493,-50)
    local mood=label(13,T.good,516,-49)
    local sample=label(10,T.muted,495,-72,preview and L.PREVIEW or "")
    local menu=UI.CreateIconButton(frame);menu:SetPoint("TOPLEFT",289,-111);menu.icon:SetTexture(T.icons.bag)
    UI.Tooltip(menu,L.FOOD,preview and L.PREVIEW_HINT or nil)
    menu:SetScript("OnClick",function()if not preview and ns.HunterFeed then ns.HunterFeed.ShowMenu(menu)end end)
    local settings=UI.CreateIconButton(frame);settings:SetPoint("TOPLEFT",346,-111);settings.icon:SetTexture(T.icons.settings)
    UI.Tooltip(settings,L.OPTIONS)
    settings:SetScript("OnClick",function()ns.Options.Toggle()end)
    if preview then
        local food=UI.CreateIconButton(frame);food:SetPoint("TOPLEFT",232,-111);food.icon:SetTexture(T.icons.food)
        UI.Tooltip(food,L.FEED,L.PREVIEW_HINT)
    end
    UI.MakeMovable(frame,"hunter")
    local view={frame=frame}
    function view.Render(data)
        local zone=data.zone or "unknown"
        range:SetText(L["ZONE_"..zone])
        hint:SetText(L["HINT_"..zone])
        local color=zone=="ranged" and T.good or zone=="deadzone" and {1,0.35,0.27,1} or zone=="melee" and T.goldLight or T.muted
        hint:SetTextColor(unpack(color))
        ammo:SetText(data.ammoCount and ns.Format.Number(data.ammoCount) or "–")
        ammo:SetTextColor(unpack(data.ammoLow and {1,0.35,0.27,1} or T.text))
        ammoIcon:SetTexture(data.ammoIcon or T.icons.ammo)
        local state=data.petState or "unknown"
        mood:SetText(L["PET_"..state])
        mood:SetTextColor(unpack(state=="happy" and T.good or state=="unhappy" and {1,0.35,0.27,1} or T.muted))
        local atlas=({unhappy="UI-PetMad",content="UI-PetNeutral",happy="UI-PetHappiness"})[state]
        if atlas and C_Texture and C_Texture.GetAtlasInfo(atlas) then moodIcon:SetAtlas(atlas)
        else moodIcon:SetTexture(T.icons.pet)end
        moodIcon:SetDesaturated(state=="missing" or state=="dead")
    end
    frame:Hide()
    return view
end
