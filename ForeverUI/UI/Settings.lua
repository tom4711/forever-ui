local _, ns = ...
local UI,T=ns.UI,ns.Theme
ns.Options={}
local frame,refreshers
local function check(parent,label,y,read,write)
    local button=UI.Button(parent,"",22);button:SetSize(22,22);button:SetPoint("TOPLEFT",24,y)
    local tick=UI.Text(button,17,T.goldLight);tick:SetPoint("CENTER");tick:SetText("✓")
    local text=UI.Text(parent,13,T.text);text:SetPoint("LEFT",button,"RIGHT",10,0);text:SetText(label)
    refreshers[#refreshers+1]=function() tick:SetShown(read()) end
    button:SetScript("OnClick",function()
        write(not read());ns.Refresh();ns.Options.Refresh()
    end)
end
local function scale(parent,moduleName,label,y)
    local text=UI.Text(parent,13,T.text);text:SetPoint("TOPLEFT",24,y);text:SetText(label)
    local value=UI.Text(parent,13,T.goldLight);value:SetPoint("TOPRIGHT",-65,y)
    refreshers[#refreshers+1]=function() value:SetText(math.floor(ns.db[moduleName].scale*100+0.5).." %") end
    for _,direction in ipairs({-1,1}) do
        local b=UI.Button(parent,direction==-1 and "−" or "+",25)
        b:SetSize(25,24);b:SetPoint("TOPRIGHT",direction==-1 and -105 or -25,y+5)
        b:SetScript("OnClick",function()
                ns.db[moduleName].scale=math.max(0.5,math.min(2,ns.db[moduleName].scale+direction*0.05))
            ns.Refresh();ns.Options.Refresh()
        end)
    end
end
local function build()
    local L=ns.L
    refreshers={}
    frame=UI.CreatePanel(UIParent,"ForeverUI_Options");frame:SetSize(430,420);frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG");frame:SetMovable(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",function(self) if not InCombatLockdown() then self:StartMoving() end end)
    frame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
    local title=UI.Text(frame,21,T.goldLight);title:SetPoint("TOPLEFT",24,-22);title:SetText(L.TITLE)
    UI.CloseButton(frame,function() frame:Hide() end)
    check(frame,L.ENABLE_HUNTER,-70,function()return ns.db.hunter.enabled end,function(v)ns.db.hunter.enabled=v end)
    check(frame,L.ENABLE_XP,-102,function()return ns.db.xp.enabled end,function(v)ns.db.xp.enabled=v end)
    check(frame,L.LOCK,-134,function()return ns.db.locked end,function(v)ns.db.locked=v end)
    scale(frame,"hunter",L.HUNTER.." · "..L.SCALE,-182)
    scale(frame,"xp",L.EXPERIENCE.." · "..L.SCALE,-215)
    local threshold=UI.Text(frame,12,T.text);threshold:SetPoint("TOPLEFT",24,-253);threshold:SetText(L.AMMO_WARNING)
    local input=CreateFrame("EditBox",nil,frame,"InputBoxTemplate");input:SetSize(75,24);input:SetPoint("TOPRIGHT",-28,-245)
    input:SetAutoFocus(false);input:SetNumeric(true);input:SetMaxLetters(6)
    refreshers[#refreshers+1]=function()if not input:HasFocus() then input:SetText(ns.db.hunter.ammoWarning) end end
    input:SetScript("OnEnterPressed",function(self)
        local value=tonumber(self:GetText())
        if not value or value<0 or value>100000 then ns.Print(L.INVALID_AMMO);return end
        ns.db.hunter.ammoWarning=math.floor(value);self:ClearFocus();ns.Refresh();ns.Options.Refresh()
    end)
    input:SetScript("OnEscapePressed",function(self)self:ClearFocus();ns.Options.Refresh()end)
    local preview=UI.Button(frame,L.PREVIEW_SHOW,175);preview:SetPoint("BOTTOMLEFT",24,95)
    preview:SetScript("OnClick",function() ns.Preview.SetEnabled(not ns.Preview.IsEnabled()) end)
    refreshers[#refreshers+1]=function()preview.label:SetText(ns.Preview.IsEnabled() and L.PREVIEW_HIDE or L.PREVIEW_SHOW)end
    local reset=UI.Button(frame,L.RESET,185);reset:SetPoint("BOTTOMRIGHT",-24,95)
    reset:SetScript("OnClick",function()
        local fresh=ns.Settings.Load(nil)
        ns.db.hunter.position=fresh.hunter.position;ns.db.xp.position=fresh.xp.position
        ns.Refresh()
    end)
    local hint=UI.Text(frame,11,T.muted);hint:SetPoint("BOTTOMLEFT",24,64);hint:SetText(L.MOVE_HINT)
    local note=UI.Text(frame,11,T.muted);note:SetPoint("BOTTOMLEFT",24,22);note:SetWidth(380);note:SetText(L.SOON)
    frame:Hide()
end
function ns.Options.Refresh()
    if refreshers then for _,refresh in ipairs(refreshers)do refresh()end end
end
function ns.Options.Toggle()
    if not frame then build() end
    frame:SetShown(not frame:IsShown());ns.Options.Refresh()
end
