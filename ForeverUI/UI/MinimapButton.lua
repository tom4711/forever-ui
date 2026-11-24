local _,ns=...
local UI,T=ns.UI,ns.Theme
ns.MinimapButton={}

local function updatePosition(button,angle)
    angle=angle or ns.db.minimapButton.angle
    local radians=math.rad(angle)
    local radius=Minimap:GetWidth()/2+4
    button:ClearAllPoints()
    button:SetPoint("CENTER",Minimap,"CENTER",math.cos(radians)*radius,math.sin(radians)*radius)
end

function ns.MinimapButton.Refresh()
    local button = ns.MinimapButton.button
    if button then updatePosition(button) end
end

function ns.MinimapButton.Init()
    if ns.MinimapButton.button or not Minimap then return end
    local button=UI.CreateIconButton(Minimap,"ForeverUI_SettingsMinimapButton",true)
    button:SetSize(36,36)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel()+8)
    button.icon:SetTexture(T.icons.settings)
    button:RegisterForClicks("LeftButtonUp","RightButtonUp")
    button:RegisterForDrag("LeftButton")
    UI.Tooltip(button,ns.L.OPTIONS)
    button:HookScript("OnEnter", function()
        if ns.db.minimapButton.collect then
            GameTooltip:AddLine(ns.L.MINIMAP_ADDONS_HINT, 0.78, 0.84, 0.84)
            GameTooltip:Show()
        end
    end)
    button:SetScript("OnHide", ns.MinimapMenu.Close)
    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            ns.MinimapMenu.Toggle()
        else
            ns.MinimapMenu.Close()
            ns.Options.Toggle()
        end
    end)
    button:SetScript("OnDragStart",function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate",function(moving)
            local cursorX,cursorY=GetCursorPosition()
            local scale=Minimap:GetEffectiveScale()
            cursorX,cursorY=cursorX/scale,cursorY/scale
            local centerX,centerY=Minimap:GetCenter()
            local angle=math.deg(math.atan2(cursorY-centerY,cursorX-centerX))%360
            ns.db.minimapButton.angle=angle
            updatePosition(moving,angle)
        end)
    end)
    button:SetScript("OnDragStop",function(self)
        self:SetScript("OnUpdate",nil)
        updatePosition(self)
    end)
    updatePosition(button)
    button:Show()
    ns.MinimapButton.button=button
    ns.MinimapMenu.Init(button)
end
