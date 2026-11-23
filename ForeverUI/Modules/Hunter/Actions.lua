local _,ns=...
local UI,T=ns.UI,ns.Theme
ns.HunterActions={}
local buttons,aspects,visible,preview,root,groups,toolbar,activeAspect={}, {}, false, false, nil, {}, ns.HunterActionModel.GroupLayout(0,0), "unknown"
local A = ns.HunterActionModel
local petLabels = {mend = "MEND_PET", revive = "REVIVE_PET", call = "CALL_PET", dismiss = "DISMISS_PET", markAttack = "HUNTER_MARK_ATTACK"}
local bindingIDs = {mend = "HunterMend", revive = "HunterRevive", call = "HunterCall", dismiss = "HunterDismiss", markAttack = "HunterMarkAttack"}
local function spellName(id)
    local name=ns.Read.Call(GetSpellInfo,id)
    if type(name)=="string" and name~=""then return name end
    local info=ns.Read.Call(C_Spell and C_Spell.GetSpellInfo,id)
    if type(info)=="table"then return info.name end
end
local function spellIcon(id)
    local icon=ns.Read.Call(GetSpellTexture,id)
    if icon then return icon end
    local info=ns.Read.Call(C_Spell and C_Spell.GetSpellInfo,id)
    return type(info)=="table" and info.iconID or T.icons.hunter
end
local function place(button,offset,parent)
    if not parent or not offset then return false end
    button:ClearAllPoints()
    button:SetScale(1)
    button:SetPoint("TOPLEFT",parent,"TOPLEFT",offset,-18)
    return true
end
local function tooltip(button,key,id)
    button:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_TOP")
        local name=spellName(id)or ns.L["ASPECT_"..key]or ns.L[petLabels[key]] or key
        GameTooltip:SetText(key == "markAttack" and ns.L.HUNTER_MARK_ATTACK or name,1,0.82,0.42)
        if key == "markAttack" then
            GameTooltip:AddLine(ns.L.HUNTER_MARK_ATTACK_HINT,0.79,0.85,0.84,true)
        elseif key=="mend"or key=="revive"then
            local exists=ns.Read.Boolean(ns.Read.Call(UnitExists,"pet"))
            local dead=ns.Read.Boolean(ns.Read.Call(UnitIsDeadOrGhost,"pet"))
            local state=ns.HunterActionModel.PetAvailability(exists,dead)
            GameTooltip:AddLine(state[key] and ns.L.PET_ACTION_READY or ns.L.PET_ACTION_UNAVAILABLE,0.79,0.85,0.84,true)
            GameTooltip:AddLine(ns.L.PET_ACTION_MANUAL,0.79,0.85,0.84,true)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave",function()GameTooltip:Hide()end)
end
local function create(key,id,index,parent)
    local bindingID = bindingIDs[key]
    local name = bindingID and ns.Bindings.ButtonName(bindingID)
    local button = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
    if name then ns.Bindings.Watch(bindingID, button) end
    button:SetSize(32,32);UI.DecorateActionButton(button)
    button.icon=button:CreateTexture(nil,"ARTWORK");button.icon:SetPoint("TOPLEFT",4,-4);button.icon:SetPoint("BOTTOMRIGHT",-4,4)
    button.icon:SetTexture(spellIcon(id));button.icon:SetTexCoord(0.07,0.93,0.07,0.93)
    button.aspectKey=not petLabels[key] and key or nil
    button.activeOutline=button.aspectKey and UI.ActionOutline(button)
    button:RegisterForClicks(unpack(ns.HunterActionModel.ClickEvents));button:EnableMouse(true);button:SetAttribute("useOnKeyDown",false)
    if petLabels[key] then
        local name = spellName(id)
        if key == "markAttack" and not name then name = ns.L.HUNTER_MARK end
        local action=A.PetAction(key,id,name)
        if action then
            button:SetAttribute("type1",action.type)
            if action.type=="macro" then button:SetAttribute("macrotext1",action.macrotext)
            else button:SetAttribute("spell",action.spell)end
        end
    else button:SetAttribute("type1","spell");button:SetAttribute("spell",id) end
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    button:SetClampedToScreen(true)
    if root then button:SetFrameLevel(root:GetFrameLevel()+5)end
    tooltip(button,key,id)
    local warning = (key == "mend" or key == "revive") and ns.L.NOT_ENOUGH_MANA or nil
    UI.TrackSpellCooldown(button, button.icon, id)
    UI.TrackSpellPower(button, button.icon, id, warning)
    button:Show();place(button,index,parent)
    return button
end
local function apply()
    if InCombatLockdown()then return false end
    local wanted={}
    for index,entry in ipairs(aspects)do
        local key="aspect_"..entry.key;wanted[key]=true
        local offset=toolbar.aspects.actions[index]
        local parent=groups.aspects
        if not buttons[key]or buttons[key].spellID~=entry.spellID then
            if buttons[key]then buttons[key]:Hide();buttons[key]=nil end
            buttons[key]=create(entry.key,entry.spellID,offset,parent);buttons[key].spellID=entry.spellID
        end
        if buttons[key]:GetParent()~=parent then buttons[key]:SetParent(parent)end
        place(buttons[key],offset,parent);buttons[key]:SetShown(visible and not preview)
    end
    local index=0
    for _,action in ipairs(A.PetActionOrder)do
        local knownRanks={}
        for _,candidate in ipairs(ns.HunterActionModel.PetSpells[action])do knownRanks[candidate]=ns.Read.SpellKnown(candidate)end
        local id=ns.HunterActionModel.HighestKnown(ns.HunterActionModel.PetSpells[action],knownRanks)
        if id then
            wanted[action]=true
            index=index+1
            local offset=toolbar.pet.actions[index]
            local parent=groups.pet
            if not buttons[action]or buttons[action].spellID~=id then
                if buttons[action]then buttons[action]:Hide()end
                buttons[action]=create(action,id,offset,parent);buttons[action].spellID=id
            end
            if buttons[action]:GetParent()~=parent then buttons[action]:SetParent(parent)end
            place(buttons[action],offset,parent);buttons[action]:SetShown(visible and not preview)
        end
    end
    for key,button in pairs(buttons)do if not wanted[key]then button:Hide();buttons[key]=nil end end
    for _,button in pairs(buttons)do
        local state=activeAspect=="unknown" and "unknown" or activeAspect==button.aspectKey and "active" or "inactive"
        UI.SetActionState(button.activeOutline,state)
    end
    ns.Bindings.Refresh()
    return true
end
function ns.HunterActions.Refresh(config,learned,groupFrames,layout,isPreview,active)
    groups=groupFrames or groups
    root=(groups.aspects and groups.aspects:GetParent())or root
    visible=config and config.enabled==true;preview=isPreview==true
    if learned then aspects=learned end
    if layout then toolbar=layout end
    activeAspect=active
    ns.CombatQueue.Request("hunterActions",apply)
end
function ns.HunterActions.Relayout()ns.HunterActions.Refresh(ns.db.hunter,aspects,groups,toolbar,ns.Preview.IsEnabled(),activeAspect)end
function ns.HunterActions.SetActiveAspect(value)
    activeAspect=value
    for _,button in pairs(buttons)do
        local state=value=="unknown" and "unknown" or value==button.aspectKey and "active" or "inactive"
        UI.SetActionState(button.activeOutline,state)
    end
end
function ns.HunterActions.SetPreview(value)
    preview=value==true;ns.CombatQueue.Request("hunterActions",apply)
end
