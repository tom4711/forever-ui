local _, ns = ...
local UI, T = ns.UI, ns.Theme
function UI.Rect(parent, color, layer)
    local texture=parent:CreateTexture(nil,layer or "ARTWORK")
    texture:SetColorTexture(unpack(color))
    return texture
end
function UI.Text(parent, size, color)
    local label=parent:CreateFontString(nil,"OVERLAY")
    label:SetFont(T.font,size,"")
    label:SetTextColor(unpack(color or T.text))
    label:SetShadowColor(0,0,0,0.9)
    label:SetShadowOffset(1,-1)
    label:SetJustifyH("LEFT")
    return label
end
local function stroke(frame, inset, color, thickness)
    local top=UI.Rect(frame,color,"BORDER")
    top:SetPoint("TOPLEFT",inset,-inset);top:SetPoint("TOPRIGHT",-inset,-inset);top:SetHeight(thickness)
    local bottom=UI.Rect(frame,color,"BORDER")
    bottom:SetPoint("BOTTOMLEFT",inset,inset);bottom:SetPoint("BOTTOMRIGHT",-inset,inset);bottom:SetHeight(thickness)
    local left=UI.Rect(frame,color,"BORDER")
    left:SetPoint("TOPLEFT",inset,-inset);left:SetPoint("BOTTOMLEFT",inset,inset);left:SetWidth(thickness)
    local right=UI.Rect(frame,color,"BORDER")
    right:SetPoint("TOPRIGHT",-inset,-inset);right:SetPoint("BOTTOMRIGHT",-inset,inset);right:SetWidth(thickness)
end
function UI.Decorate(frame)
    local bg=UI.Rect(frame,T.background,"BACKGROUND");bg:SetAllPoints()
    stroke(frame,0,{0.055,0.035,0.01,1},5)
    stroke(frame,2,T.goldDark,3)
    stroke(frame,3,T.gold,1)
    stroke(frame,5,{0.47,0.32,0.11,1},1)
    stroke(frame,7,{0.04,0.15,0.17,1},1)
    local sheen=UI.Rect(frame,{0.22,0.35,0.33,0.12},"BACKGROUND")
    sheen:SetPoint("TOPLEFT",9,-9);sheen:SetPoint("TOPRIGHT",-9,-9);sheen:SetHeight(3)
    for _,point in ipairs({"TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT"}) do
        local corner=UI.Rect(frame,T.goldDark,"OVERLAY");corner:SetSize(10,10);corner:SetPoint(point,frame,point,0,0)
        corner:SetRotation(math.pi/4)
        local jewel=UI.Rect(frame,T.gold,"OVERLAY");jewel:SetSize(5,5);jewel:SetPoint("CENTER",corner,"CENTER");jewel:SetRotation(math.pi/4)
    end
end
function UI.DecorateControl(frame)
    local bg=UI.Rect(frame,T.inset,"BACKGROUND");bg:SetAllPoints()
    stroke(frame,0,T.goldDark,2)
    stroke(frame,1,T.gold,1)
    stroke(frame,3,{0.05,0.15,0.17,1},1)
end
function UI.CreatePanel(parent,id)
    local frame=CreateFrame("Frame",id,parent)
    frame:SetClampedToScreen(true)
    UI.Decorate(frame)
    frame.content=CreateFrame("Frame",nil,frame)
    frame.content:SetPoint("TOPLEFT",10,-10);frame.content:SetPoint("BOTTOMRIGHT",-10,10)
    return frame
end
function UI.Tooltip(frame,title,description)
    frame:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_TOP")
        GameTooltip:SetText(title,1,0.82,0.42)
        if description then GameTooltip:AddLine(description,0.79,0.85,0.84,true) end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave",function() GameTooltip:Hide() end)
end
function UI.CreateIconButton(parent,id)
    local button=CreateFrame("Button",id,parent)
    button:SetSize(48,48)
    UI.Decorate(button)
    button.icon=button:CreateTexture(nil,"ARTWORK")
    button.icon:SetPoint("TOPLEFT",6,-6);button.icon:SetPoint("BOTTOMRIGHT",-6,6)
    button.icon:SetTexCoord(0.07,0.93,0.07,0.93)
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    return button
end
function UI.Button(parent,text,width)
    local button=CreateFrame("Button",nil,parent)
    button:SetSize(width or 160,29)
    UI.DecorateControl(button)
    button.label=UI.Text(button,12,T.goldLight);button.label:SetPoint("CENTER");button.label:SetText(text)
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    return button
end
function UI.CloseButton(parent,callback)
    local button=UI.Button(parent,"×",26)
    button:SetSize(26,26);button:SetPoint("TOPRIGHT",-10,-10)
    local bg=UI.Rect(button,{0.4,0.065,0.025,1},"BACKGROUND");bg:SetPoint("TOPLEFT",6,-6);bg:SetPoint("BOTTOMRIGHT",-6,6)
    button:SetScript("OnClick",callback)
    return button
end
function UI.MakeMovable(frame,moduleName)
    frame:SetMovable(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",function(self)
        if not ns.db.locked and IsAltKeyDown() and not InCombatLockdown() then
            if moduleName=="hunter" and ns.HunterFeed then ns.HunterFeed.SetDragging(true)end
            self:StartMoving();self.dragging=true
        end
    end)
    frame:SetScript("OnDragStop",function(self)
        if not self.dragging then return end
        self:StopMovingOrSizing();self.dragging=false
        local point,_,relativePoint,x,y=self:GetPoint()
        ns.db[moduleName].position={point=point,relativePoint=relativePoint,x=x,y=y}
        if moduleName=="hunter" and ns.HunterFeed then ns.HunterFeed.SetDragging(false)end
    end)
end
function UI.Place(frame,moduleName)
    local config=ns.db[moduleName]
    frame:ClearAllPoints();frame:SetScale(config.scale)
    local p=config.position
    frame:SetPoint(p.point,UIParent,p.relativePoint,p.x,p.y)
end
