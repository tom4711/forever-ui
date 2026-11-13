local _, ns = ...
local UI,T=ns.UI,ns.Theme
ns.Preview={}
local enabled=false
local hunter,xp
local function text(parent,size,color,value,x,y)
    local label=UI.Text(parent,size,color);label:SetText(value);label:SetPoint("TOPLEFT",x,y);return label
end
local function icon(parent,texture,x,y,size)
    local button=UI.CreateIconButton(parent)
    button:SetSize(size,size);button:SetPoint("TOPLEFT",x,y);button.icon:SetTexture(texture)
    return button
end
local function build()
    local L=ns.L
    hunter=UI.CreatePanel(UIParent,"ForeverUI_PreviewHunter");hunter:SetSize(620,100)
    icon(hunter,T.icons.hunter,18,-19,62)
    text(hunter,11,T.gold,L.HUNTER,98,-17)
    text(hunter,23,T.goldLight,L.RANGED,98,-35)
    text(hunter,12,T.good,L.RANGE_HINT,98,-65)
    text(hunter,11,T.muted,L.AMMO,380,-23)
    text(hunter,23,T.text,"1.248",380,-42)
    text(hunter,11,T.muted,L.PET,495,-23)
    text(hunter,15,T.good,L.HAPPY,495,-47)
    text(hunter,10,T.muted,L.PREVIEW,495,-72)
    local labels={L.FEED,L.FOOD,L.OPTIONS}
    local textures={T.icons.food,T.icons.bag,T.icons.settings}
    for i=1,3 do
        local button=icon(hunter,textures[i],232+(i-1)*57,-111,48)
        UI.Tooltip(button,labels[i],i<3 and L.SOON or L.OPTIONS)
        if i==3 then button:SetScript("OnClick",function() ns.Options.Toggle() end) end
    end
    UI.MakeMovable(hunter,"hunter")
    hunter:Hide()
    xp=UI.CreatePanel(UIParent,"ForeverUI_PreviewXP");xp:SetSize(620,124)
    icon(xp,T.icons.xp,17,-17,48)
    text(xp,21,T.goldLight,L.LEVEL,82,-17)
    local percent=UI.Text(xp,16,T.teal);percent:SetPoint("TOPRIGHT",-20,-21);percent:SetText("58,5 %")
    local track=UI.Rect(xp,T.inset);track:SetPoint("TOPLEFT",82,-49);track:SetSize(518,16)
    local rested=UI.Rect(xp,T.rested);rested:SetPoint("TOPLEFT",track,"TOPLEFT",0,0);rested:SetSize(518*0.784516,16)
    local fill=UI.Rect(xp,T.xp);fill:SetPoint("TOPLEFT",track,"TOPLEFT",0,0);fill:SetSize(518*0.584516,16)
    local shine=UI.Rect(xp,{0.54,0.92,0.85,0.38});shine:SetPoint("TOPLEFT",fill,"TOPLEFT",0,0);shine:SetPoint("TOPRIGHT",fill,"TOPRIGHT",0,0);shine:SetHeight(2)
    text(xp,11,T.text,"36.240 / 62.000 XP",82,-70)
    local restedLabel=UI.Text(xp,11,T.muted);restedLabel:SetPoint("TOPRIGHT",-20,-70);restedLabel:SetText(L.RESTED.." +12.400")
    text(xp,11,T.muted,L.XP_HOUR..": |cffcbdad618.600|r",20,-99)
    text(xp,11,T.muted,L.TIME_LEFT..": |cffcbdad61h 23m|r",226,-99)
    local session=UI.Text(xp,11,T.muted);session:SetPoint("TOPRIGHT",-20,-99);session:SetText(L.SESSION..": |cffcbdad60:47:12|r")
    UI.MakeMovable(xp,"xp");UI.Tooltip(xp,L.EXPERIENCE,L.PREVIEW_HINT);xp:Hide()
end
function ns.Preview.IsEnabled() return enabled end
function ns.Preview.Refresh()
    if not hunter then return end
    UI.Place(hunter,"hunter");UI.Place(xp,"xp")
    hunter:SetShown(enabled and ns.db.hunter.enabled)
    xp:SetShown(enabled and ns.db.xp.enabled)
end
function ns.Preview.SetEnabled(value)
    if InCombatLockdown() then ns.Print(ns.L.COMBAT);return false end
    if not hunter then build() end
    enabled=value == true
    ns.Refresh()
    if ns.Options.Refresh then ns.Options.Refresh() end
    return true
end
