local _,ns=...
local UI,T=ns.UI,ns.Theme
ns.HunterActions={}
local buttons,aspects,visible,preview,root={}, {}, false, false, nil
local function known(id)
    local value=ns.Read.Boolean(ns.Read.Call(IsPlayerSpell,id))
    if value==nil then value=ns.Read.Boolean(ns.Read.Call(IsSpellKnown,id))end
    return value==true
end
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
local function geometry()
    if not root then return end
    local left,top=ns.Read.Number(root:GetLeft()),ns.Read.Number(root:GetTop())
    local scale,parentScale=ns.Read.Number(root:GetEffectiveScale()),ns.Read.Number(UIParent:GetEffectiveScale())
    local parentLeft,parentBottom=ns.Read.Number(UIParent:GetLeft()),ns.Read.Number(UIParent:GetBottom())
    if not left or not top or not scale or not parentScale or not parentLeft or not parentBottom then return end
    return {left=left,top=top,scale=scale,parentScale=parentScale,parentLeft=parentLeft,parentBottom=parentBottom}
end
local function place(button,index)
    local g=geometry();if not g then return false end
    local position=ns.HunterActionModel.Position(g,index)
    if not position then return false end
    button:SetScale(position.scale)
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",position.x,position.y)
    return true
end
local function tooltip(button,key,id)
    button:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_TOP")
        local name=spellName(id)or ns.L["ASPECT_"..key]or ns.L[key=="mend" and "MEND_PET" or "REVIVE_PET"]
        GameTooltip:SetText(name,1,0.82,0.42)
        if key=="mend"or key=="revive"then
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
local function create(key,id,index)
    local button=CreateFrame("Button",nil,UIParent,"SecureActionButtonTemplate")
    button:SetSize(32,32);UI.Decorate(button)
    button.icon=button:CreateTexture(nil,"ARTWORK");button.icon:SetPoint("TOPLEFT",4,-4);button.icon:SetPoint("BOTTOMRIGHT",-4,4)
    button.icon:SetTexture(spellIcon(id));button.icon:SetTexCoord(0.07,0.93,0.07,0.93)
    button:RegisterForClicks("LeftButtonUp");button:SetAttribute("useOnKeyDown",false)
    if key=="mend"or key=="revive"then
        button:SetAttribute("type1","macro");button:SetAttribute("macrotext1",ns.HunterActionModel.PetMacro(key,spellName(id)))
    else button:SetAttribute("type1","spell");button:SetAttribute("spell",id) end
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
    button:SetClampedToScreen(true);tooltip(button,key,id)
    button:Show();place(button,index)
    return button
end
local function apply()
    if InCombatLockdown()then return false end
    local wanted={}
    for index,entry in ipairs(aspects)do
        local key="aspect_"..entry.key;wanted[key]=true
        if not buttons[key]or buttons[key].spellID~=entry.spellID then
            if buttons[key]then buttons[key]:Hide();buttons[key]=nil end
            buttons[key]=create(entry.key,entry.spellID,index-1);buttons[key].spellID=entry.spellID
        end
        place(buttons[key],index-1);buttons[key]:SetShown(visible and not preview)
    end
    local index=#aspects
    for _,action in ipairs({"mend","revive"})do
        local knownRanks={}
        for _,candidate in ipairs(ns.HunterActionModel.PetSpells[action])do knownRanks[candidate]=known(candidate)end
        local id=ns.HunterActionModel.HighestKnown(ns.HunterActionModel.PetSpells[action],knownRanks)
        if id then
            wanted[action]=true
            local slot=index;index=index+1
            if not buttons[action]or buttons[action].spellID~=id then
                if buttons[action]then buttons[action]:Hide()end
                buttons[action]=create(action,id,slot);buttons[action].spellID=id
            end
            place(buttons[action],slot);buttons[action]:SetShown(visible and not preview)
        end
    end
    for key,button in pairs(buttons)do if not wanted[key]then button:Hide();buttons[key]=nil end end
    return true
end
function ns.HunterActions.Refresh(config,learned,anchor,isPreview)
    root=anchor or root;visible=config and config.enabled==true;preview=isPreview==true
    if learned then aspects=learned end
    ns.CombatQueue.Request("hunterActions",apply)
end
function ns.HunterActions.Relayout()ns.HunterActions.Refresh(ns.db.hunter,aspects,root,ns.Preview.IsEnabled())end
function ns.HunterActions.SetPreview(value)
    preview=value==true;ns.CombatQueue.Request("hunterActions",apply)
end
