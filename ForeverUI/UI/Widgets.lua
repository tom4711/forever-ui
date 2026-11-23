local _, ns = ...
local UI, T = ns.UI, ns.Theme
local deferredMoves={}
function UI.Rect(parent, color, layer, opacity)
    local texture=parent:CreateTexture(nil,layer or "ARTWORK")
    if type(color) == "string" then
        T.BindAccent(texture, color, opacity)
    else
        texture:SetColorTexture(unpack(color))
    end
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
local function stroke(frame, inset, color, thickness, opacity)
    local top=UI.Rect(frame,color,"BORDER",opacity)
    top:SetPoint("TOPLEFT",inset,-inset);top:SetPoint("TOPRIGHT",-inset,-inset);top:SetHeight(thickness)
    local bottom=UI.Rect(frame,color,"BORDER",opacity)
    bottom:SetPoint("BOTTOMLEFT",inset,inset);bottom:SetPoint("BOTTOMRIGHT",-inset,inset);bottom:SetHeight(thickness)
    local left=UI.Rect(frame,color,"BORDER",opacity)
    left:SetPoint("TOPLEFT",inset,-inset);left:SetPoint("BOTTOMLEFT",inset,inset);left:SetWidth(thickness)
    local right=UI.Rect(frame,color,"BORDER",opacity)
    right:SetPoint("TOPRIGHT",-inset,-inset);right:SetPoint("BOTTOMRIGHT",-inset,inset);right:SetWidth(thickness)
end
function UI.Decorate(frame)
    local bg=UI.Rect(frame,T.background,"BACKGROUND");bg:SetAllPoints()
    stroke(frame,0,{0.055,0.035,0.01,1},5)
    stroke(frame,2,"dark",3)
    stroke(frame,3,"edge",1)
    stroke(frame,5,"shadow",1)
    stroke(frame,7,{0.04,0.15,0.17,1},1)
    local sheen=UI.Rect(frame,{0.22,0.35,0.33,0.12},"BACKGROUND")
    sheen:SetPoint("TOPLEFT",9,-9);sheen:SetPoint("TOPRIGHT",-9,-9);sheen:SetHeight(3)
    for _,point in ipairs({"TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT"}) do
        local corner=UI.Rect(frame,"dark","OVERLAY");corner:SetSize(10,10);corner:SetPoint(point,frame,point,0,0)
        corner:SetRotation(math.pi/4)
        local jewel=UI.Rect(frame,"edge","OVERLAY");jewel:SetSize(5,5);jewel:SetPoint("CENTER",corner,"CENTER");jewel:SetRotation(math.pi/4)
    end
end
function UI.DecorateControl(frame)
    local bg=UI.Rect(frame,T.inset,"BACKGROUND");bg:SetAllPoints()
    stroke(frame,0,"dark",2)
    stroke(frame,1,"edge",1)
    stroke(frame,3,{0.05,0.15,0.17,1},1)
end
function UI.DecorateActionButton(frame)
    local bg=UI.Rect(frame,T.inset,"BACKGROUND");bg:SetAllPoints()
    stroke(frame,0,"dark",2)
    stroke(frame,2,"edge",1)
    stroke(frame,4,{0.05,0.15,0.17,1},1)
    for _,point in ipairs({"TOPLEFT","TOPRIGHT","BOTTOMLEFT","BOTTOMRIGHT"})do
        local stud=UI.Rect(frame,"dark","OVERLAY");stud:SetSize(3,3);stud:SetPoint(point,frame,point,point:find("LEFT") and 2 or -2,point:find("TOP") and -2 or 2)
    end
end
function UI.ActionOutline(frame)
    local teal={}
    local top=UI.Rect(frame,T.teal,"OVERLAY");top:SetPoint("TOPLEFT",2,-2);top:SetPoint("TOPRIGHT",-2,-2);top:SetHeight(2);teal[#teal+1]=top
    local bottom=UI.Rect(frame,T.teal,"OVERLAY");bottom:SetPoint("BOTTOMLEFT",2,2);bottom:SetPoint("BOTTOMRIGHT",-2,2);bottom:SetHeight(2);teal[#teal+1]=bottom
    local left=UI.Rect(frame,T.teal,"OVERLAY");left:SetPoint("TOPLEFT",2,-2);left:SetPoint("BOTTOMLEFT",2,2);left:SetWidth(2);teal[#teal+1]=left
    local right=UI.Rect(frame,T.teal,"OVERLAY");right:SetPoint("TOPRIGHT",-2,-2);right:SetPoint("BOTTOMRIGHT",-2,2);right:SetWidth(2);teal[#teal+1]=right
    for _,texture in ipairs(teal)do texture:Hide()end
    return teal
end
function UI.SetActionState(outline,state)
    if not outline then return end
    local color=state=="active" and T.teal or T.muted
    for _,texture in ipairs(outline)do
        texture:SetVertexColor(unpack(color))
        texture:SetShown(state=="active" or state=="unknown")
    end
end
function UI.DecorateGroup(frame)
    local bg=UI.Rect(frame,{T.inset[1],T.inset[2],T.inset[3],0.72},"BACKGROUND");bg:SetAllPoints()
    stroke(frame,0,"dark",1,0.88)
    stroke(frame,2,"edge",1,0.42)
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
function UI.CreateIconButton(parent,id,compact)
    local button=CreateFrame("Button",id,parent)
    button:SetSize(48,48)
    if compact then UI.DecorateActionButton(button)else UI.Decorate(button)end
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
    local button=UI.Button(parent,"",26)
    button:SetSize(26,26);button:SetPoint("TOPRIGHT",-10,-10)
    local first=button:CreateLine(nil,"OVERLAY")
    first:SetColorTexture(unpack(T.goldLight));first:SetThickness(1.5)
    first:SetStartPoint("TOPLEFT",button,8,-8);first:SetEndPoint("BOTTOMRIGHT",button,-8,8)
    local second=button:CreateLine(nil,"OVERLAY")
    second:SetColorTexture(unpack(T.goldLight));second:SetThickness(1.5)
    second:SetStartPoint("BOTTOMLEFT",button,8,8);second:SetEndPoint("TOPRIGHT",button,-8,-8)
    UI.Tooltip(button,ns.L.CLOSE)
    button:SetScript("OnClick",callback)
    return button
end
function UI.MakeMovable(frame,moduleName,useGroupGrip)
    frame:SetMovable(true)
    local deferStop=false
    local function capture()
        if not frame.dragging then return false end
        frame:StopMovingOrSizing();frame.dragging=false;deferStop=false
        local point,_,relativePoint,x,y=frame:GetPoint()
        ns.db[moduleName].position={point=point,relativePoint=relativePoint,x=x,y=y}
        if moduleName=="hunter" and ns.HunterFeed then ns.HunterFeed.SetDragging(false)end
        return true
    end
    local function stopMoving()
        if not frame.dragging then return end
        if InCombatLockdown()then
            if not deferStop then deferStop=true;deferredMoves[frame]=function()return capture()end end
            return
        end
        if capture() and moduleName=="hunter" and ns.HunterActions then ns.HunterActions.Relayout()end
    end
    local function startMoving()
        if not ns.db.locked and IsAltKeyDown() and not InCombatLockdown() then
            if moduleName=="hunter" and ns.HunterFeed then ns.HunterFeed.SetDragging(true)end
            frame:StartMoving()
            frame.dragging=true
        end
    end
    if useGroupGrip then
        frame.groupDrag = {start = startMoving, stop = stopMoving}
    else
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart",startMoving)
        frame:SetScript("OnDragStop",stopMoving)
    end
    local events=CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:SetScript("OnEvent",function()
        if frame.dragging and not deferStop then deferStop=true;deferredMoves[frame]=function()return capture()end end
    end)
end
function UI.MakeGroupMovable(frame,groupName,moduleName)
    moduleName=moduleName or "hunter"
    frame:SetMovable(true);frame:SetClampedToScreen(true)
    local grip=CreateFrame("Button",nil,frame)
    grip:SetSize(14,24);grip:SetPoint("TOPLEFT",3,-17);grip:EnableMouse(true);grip:RegisterForDrag("LeftButton")
    for row=1,3 do
        for column=1,2 do
            local dot=UI.Rect(grip,"light","OVERLAY")
            dot:SetSize(2,2);dot:SetPoint("TOPLEFT",3+(column-1)*4,-7-(row-1)*4)
        end
    end
    local parentDrag = frame:GetParent().groupDrag
    UI.Tooltip(grip,ns.L.MOVE_GROUP,parentDrag and ns.L.MOVE_CLASS_GROUPS_HINT or ns.L.MOVE_GROUP_HINT)
    local deferStop=false
    local movingParent
    local function capture()
        if not frame.dragging then return false end
        frame:StopMovingOrSizing();frame.dragging=false
        deferStop=false
        local point,parent,relativePoint,x,y=frame:GetPoint()
        local root=frame:GetParent()
        if parent~=root or point~="TOPLEFT" or relativePoint~="TOPLEFT" then
            local left,rootLeft=ns.Read.Number(frame:GetLeft()),ns.Read.Number(root:GetLeft())
            local top,rootTop=ns.Read.Number(frame:GetTop()),ns.Read.Number(root:GetTop())
            if left and rootLeft and top and rootTop then
                local offset=ns.HunterActionModel.GroupOffset(left,top,rootLeft,rootTop)
                if offset then x=offset.x;y=offset.y end
            end
        end
        x=ns.Read.Number(x);y=ns.Read.Number(y)
        if not x or not y then return true end
        local moduleSettings=ns.db[moduleName]
        if not moduleSettings or not moduleSettings[groupName]then return true end
        moduleSettings[groupName].position={x=x,y=y}
        return true
    end
    local function stopMoving()
        if not frame.dragging then return end
        if InCombatLockdown()then
            if not deferStop then deferStop=true;deferredMoves[frame]=capture end
            return
        end
        local controller=ns[moduleName:sub(1,1):upper()..moduleName:sub(2)]
        if capture() then
            if controller and controller.Refresh then controller.Refresh()
            else ns.Refresh() end
        end
    end
    grip:SetScript("OnDragStart",function()
        if not ns.db.locked and IsAltKeyDown() and not InCombatLockdown() then
            movingParent = parentDrag and IsShiftKeyDown()
            if movingParent then
                parentDrag.start()
            else
                frame:StartMoving()
                frame.dragging=true
            end
        end
    end)
    grip:SetScript("OnDragStop",function()
        if movingParent then
            parentDrag.stop()
        else
            stopMoving()
        end
        movingParent = false
    end)
    local events=CreateFrame("Frame")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:SetScript("OnEvent",function()
        if frame.dragging and not deferStop then deferStop=true;deferredMoves[frame]=capture end
    end)
    frame.dragGrip=grip
end
function UI.FlushDeferredMoves()
    if InCombatLockdown()then return false end
    local pending=deferredMoves;deferredMoves={}
    local changed=false
    for _,capture in pairs(pending)do if capture()then changed=true end end
    return changed
end
function UI.Place(frame,moduleName)
    local config=ns.db[moduleName]
    frame:ClearAllPoints();frame:SetScale(config.scale)
    local p=config.position
    frame:SetPoint(p.point,UIParent,p.relativePoint,p.x,p.y)
end

function UI.CreateClassAnchor(name, moduleName, width, height)
    local root = CreateFrame("Frame", name, UIParent)
    root:SetSize(width, height)
    root:SetClampedToScreen(true)
    UI.MakeMovable(root, moduleName, true)
    return root
end

function UI.CreateClassGroup(root, moduleName, key, label)
    local frame = CreateFrame("Frame", nil, root)
    frame:SetSize(120, 60)
    UI.DecorateGroup(frame)
    local caption = UI.Text(frame, 9, T.muted)
    caption:SetPoint("TOPLEFT", 18, -4)
    caption:SetText(label)
    UI.MakeGroupMovable(frame, key, moduleName)
    frame:Hide()
    return {frame = frame, caption = caption, buttons = {}}
end

function UI.RenderClassGroup(group, config, entries, visible, makeButton)
    local frame = group.frame
    if not frame.dragging then
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", frame:GetParent(), "TOPLEFT", config.position.x, config.position.y)
    end
    local wanted = {}
    for index, entry in ipairs(entries) do
        wanted[entry.key] = true
        local button = group.buttons[entry.key]
        if not button or button.spellID ~= entry.spellID then
            if button then button:Hide() end
            button = makeButton(frame, entry)
            button.spellID = entry.spellID
            group.buttons[entry.key] = button
        end
        local column = (index - 1) % 5
        local row = math.floor((index - 1) / 5)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", 24 + column * 42, -18 - row * 42)
        button:Show()
    end
    for key, button in pairs(group.buttons) do
        if not wanted[key] then button:Hide() end
    end
    frame:SetSize(math.max(30 + group.caption:GetStringWidth(), 24 + math.min(#entries, 5) * 42),
        60 + math.max(0, math.ceil(#entries / 5) - 1) * 42)
    frame:SetShown(visible and config.enabled and #entries > 0)
end

function UI.CreateClassAction(parent, entry, preview, fallbackIcon, title, hint)
    local template = not preview and "SecureActionButtonTemplate" or nil
    local name = not preview and entry.bindingID and ns.Bindings.ButtonName(entry.bindingID) or nil
    local button = CreateFrame("Button", name, parent, template)
    if name then ns.Bindings.Watch(entry.bindingID, button) end
    button:SetSize(36, 36)
    UI.DecorateActionButton(button)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 4, -4)
    icon:SetPoint("BOTTOMRIGHT", -4, 4)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    local spellID = entry.spellID
    local texture, spellName
    if spellID then
        texture = ns.Read.Call(C_Spell and C_Spell.GetSpellTexture, spellID) or ns.Read.Call(GetSpellTexture, spellID)
        spellName = ns.Read.Call(C_Spell and C_Spell.GetSpellName, spellID) or ns.Read.Call(GetSpellInfo, spellID)
    end
    icon:SetTexture(texture or fallbackIcon)
    if not preview then
        button:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
        button:SetAttribute("useOnKeyDown", false)
        if entry.macro then
            button:SetAttribute("type1", "macro")
            button:SetAttribute("macrotext1", entry.macro)
        elseif spellID then
            button:SetAttribute("type1", "spell")
            button:SetAttribute("spell", spellID)
            if entry.unit then button:SetAttribute("unit", entry.unit) end
        end
    end
    UI.Tooltip(button, spellName or title, preview and ns.L.PREVIEW_HINT or hint)
    if not preview and spellID then
        UI.TrackSpellCooldown(button, icon, spellID)
        UI.TrackSpellPower(button, icon, spellID)
        if entry.interrupt then ns.InterruptCue.Track(button, spellID) end
    end
    return button
end
