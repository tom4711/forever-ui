local _, ns = ...
local UI,T=ns.UI,ns.Theme
ns.Options={}
local frame,refreshers
local function check(parent,label,y,read,write)
    local button=CreateFrame("CheckButton",nil,parent)
    button:SetSize(22,22);button:SetPoint("TOPLEFT",24,y);UI.DecorateControl(button)
    button:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
    local tick=button:GetCheckedTexture();tick:ClearAllPoints();tick:SetPoint("TOPLEFT",1,-1);tick:SetPoint("BOTTOMRIGHT",-1,1)
    tick:SetVertexColor(1,0.85,0.5)
    local text=UI.Text(parent,13,T.text);text:SetPoint("LEFT",button,"RIGHT",10,0);text:SetText(label)
    refreshers[#refreshers+1]=function() button:SetChecked(read()) end
    button:SetScript("OnClick",function()
        write(not read());ns.Refresh();ns.Options.Refresh()
    end)
end
local function scale(parent,moduleName,label,y)
    local text=UI.Text(parent,13,T.text);text:SetPoint("TOPLEFT",24,y);text:SetText(label)
    local value=UI.Text(parent,13,T.goldLight);value:SetPoint("TOPRIGHT",-65,y)
    refreshers[#refreshers+1]=function() value:SetText(math.floor(ns.db[moduleName].scale*100+0.5).." %") end
    for _,direction in ipairs({-1,1}) do
        local b=UI.Button(parent,direction==-1 and "-" or "+",25)
        b:SetSize(25,24);b:SetPoint("TOPRIGHT",direction==-1 and -130 or -25,y+5)
        b:SetScript("OnClick",function()
            ns.db[moduleName].scale=math.max(0.5,math.min(2,ns.db[moduleName].scale+direction*0.05))
            ns.Refresh();ns.Options.Refresh()
        end)
    end
end
local function opacity(parent, config, y, apply)
    local label = UI.Text(parent, 13, T.text)
    label:SetPoint("TOPLEFT", 24, y)
    label:SetText(ns.L.BACKGROUND_OPACITY)
    local value = UI.Text(parent, 13, T.goldLight)
    value:SetPoint("TOPRIGHT", -24, y)
    local slider = CreateFrame("Slider", nil, parent)
    slider:SetOrientation("HORIZONTAL")
    slider:SetHeight(20)
    slider:SetPoint("TOPLEFT", 24, y - 20)
    slider:SetPoint("TOPRIGHT", -24, y - 20)
    slider:SetMinMaxValues(0, 100)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    local track = UI.Rect(slider, T.inset, "BACKGROUND")
    track:SetPoint("LEFT", 4, 0)
    track:SetPoint("RIGHT", -4, 0)
    track:SetHeight(4)
    local thumb = UI.Rect(slider, T.gold, "OVERLAY")
    thumb:SetSize(10, 14)
    slider:SetThumbTexture(thumb)

    local syncing = false
    slider:SetScript("OnValueChanged", function(_, percent)
        percent = math.floor(percent + 0.5)
        value:SetText(percent .. " %")
        if syncing or config.opacity == percent / 100 then return end
        config.opacity = percent / 100
        apply()
    end)
    refreshers[#refreshers + 1] = function()
        local percent = math.floor(config.opacity * 100 + 0.5)
        syncing = true
        slider:SetValue(percent)
        value:SetText(percent .. " %")
        syncing = false
    end
end

local function choice(parent,label,key,y)
    local text=UI.Text(parent,13,T.text);text:SetPoint("TOPLEFT",24,y);text:SetText(label)
    local value=UI.Text(parent,13,T.goldLight);value:SetPoint("TOPRIGHT",-65,y)
    refreshers[#refreshers+1]=function() value:SetText(ns.db.xp[key]=="percent" and ns.L.DISPLAY_PERCENT or ns.L.DISPLAY_XP) end
    local button=UI.Button(parent,">",26);button:SetSize(25,24);button:SetPoint("TOPRIGHT",-25,y+5)
    button:SetScript("OnClick",function()
        ns.db.xp[key]=ns.db.xp[key]=="xp" and "percent" or "xp"
        ns.Refresh();ns.Options.Refresh()
    end)
end
local function equipmentSet(parent,key,label,y)
    local text=UI.Text(parent,13,T.text);text:SetPoint("TOPLEFT",24,y);text:SetText(label)
    local value=UI.Text(parent,12,T.goldLight);value:SetPoint("TOPRIGHT",-65,y);value:SetJustifyH("RIGHT")
    local function setIDs()
        local api=C_EquipmentSet
        if not api or type(api.GetEquipmentSetIDs)~="function"or type(api.GetEquipmentSetInfo)~="function"then return nil end
        local ok,ids=pcall(api.GetEquipmentSetIDs)
        return ok and type(ids)=="table"and ids or nil
    end
    local function selectedName()
        local id=ns.db.paladin.weaponSets[key]
        if id==nil then return ns.L.SET_NONE end
        local ids=setIDs()
        if not ids then return ns.L.SET_UNAVAILABLE end
        local exists=false
        for _,candidate in ipairs(ids)do if candidate==id then exists=true;break end end
        if not exists then return ns.L.SET_NONE end
        local ok,name=pcall(C_EquipmentSet.GetEquipmentSetInfo,id)
        if ok and type(name)=="string"and name~=""then return name end
        return ns.L.SET_UNAVAILABLE
    end
    refreshers[#refreshers+1]=function()value:SetText(selectedName())end
    local button=UI.Button(parent,">",25);button:SetSize(25,24);button:SetPoint("TOPRIGHT",-25,y+5)
    button:SetScript("OnClick",function()
        if not MenuUtil or not MenuUtil.CreateContextMenu then ns.Print(ns.L.SET_MENU_UNAVAILABLE);return end
        MenuUtil.CreateContextMenu(button,function(_,root)
            root:CreateTitle(label)
            root:CreateRadio(ns.L.SET_NONE,function()return ns.db.paladin.weaponSets[key]==nil end,function()
                ns.db.paladin.weaponSets[key]=nil;ns.Refresh();ns.Options.Refresh()
            end)
            local api=C_EquipmentSet
            local ids=setIDs()or {}
            for _,id in ipairs(ids)do
                local ok,name=pcall(api.GetEquipmentSetInfo,id)
                if not ok then name=nil end
                if type(name)=="string" and name~="" then
                    local setID=id
                    root:CreateRadio(name,function()return ns.db.paladin.weaponSets[key]==setID end,function()
                        ns.db.paladin.weaponSets[key]=setID;ns.Refresh();ns.Options.Refresh()
                    end)
                end
            end
            if not C_EquipmentSet or type(C_EquipmentSet.GetEquipmentSetIDs)~="function"or type(C_EquipmentSet.GetEquipmentSetInfo)~="function"then root:CreateButton(ns.L.SET_UNAVAILABLE):SetEnabled(false)
            elseif #ids==0 then root:CreateButton(ns.L.SET_EMPTY):SetEnabled(false)end
        end)
    end)
end
local classOptions = {
    HUNTER = {enable = "ENABLE_HUNTER", groups = {
        {"aspectGroup", "SHOW_ASPECTS"},
        {"petGroup", "SHOW_PET_ACTIONS"},
    }},
    PALADIN = {enable = "ENABLE_PALADIN", scale = "PALADIN_SCALE", groups = {
        {"auraGroup", "SHOW_PALADIN_AURAS"},
        {"blessingGroup", "SHOW_PALADIN_BLESSINGS"},
        {"weaponGroup", "SHOW_PALADIN_WEAPONS"},
        {"macroGroup", "SHOW_QUICK_CASTS"},
        {"friendlyGroup", "SHOW_FRIENDLY_BUFFS"},
    }},
    WARLOCK = {enable = "ENABLE_WARLOCK", scale = "WARLOCK_SCALE", groups = {
        {"summonGroup", "SHOW_WARLOCK_SUMMONS"},
        {"macroGroup", "SHOW_QUICK_CASTS"},
        {"friendlyGroup", "SHOW_FRIENDLY_BUFFS"},
    }},
    PRIEST = {enable = "ENABLE_PRIEST", groups = {
        {"buffGroup", "SHOW_PRIEST_BUFFS"},
        {"supportGroup", "SHOW_PRIEST_SUPPORT"},
        {"macroGroup", "SHOW_PRIEST_MACROS"},
    }},
    MAGE = {enable = "ENABLE_MAGE", groups = {
        {"buffGroup", "SHOW_FRIENDLY_BUFFS"},
        {"utilityGroup", "SHOW_CLASS_UTILITY"},
        {"interruptGroup", "SHOW_INTERRUPTS"},
    }},
    SHAMAN = {enable = "ENABLE_SHAMAN", groups = {
        {"totemGroup", "SHOW_SHAMAN_TOTEMS"},
        {"buffGroup", "SHOW_FRIENDLY_BUFFS"},
        {"utilityGroup", "SHOW_CLASS_UTILITY"},
        {"interruptGroup", "SHOW_INTERRUPTS"},
    }},
    DRUID = {enable = "ENABLE_DRUID", groups = {}},
    ROGUE = {enable = "ENABLE_ROGUE", groups = {{"interruptGroup", "SHOW_INTERRUPTS"}}},
    WARRIOR = {enable = "ENABLE_WARRIOR", groups = {
        {"stanceGroup", "SHOW_WARRIOR_STANCES"}, {"interruptGroup", "SHOW_INTERRUPTS"},
    }},
}

local function heading(parent, label, y)
    local text = UI.Text(parent, 15, T.goldLight)
    text:SetPoint("TOPLEFT", 6, y)
    text:SetText(label)
end

local function ammoOptions(parent, y)
    local label = UI.Text(parent, 12, T.text)
    label:SetPoint("TOPLEFT", 24, y)
    label:SetText(ns.L.AMMO_WARNING)
    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetSize(75, 24)
    input:SetPoint("TOPRIGHT", -10, y + 8)
    input:SetAutoFocus(false)
    input:SetNumeric(true)
    input:SetMaxLetters(6)
    refreshers[#refreshers + 1] = function()
        if not input:HasFocus() then input:SetText(ns.db.hunter.ammoWarning) end
    end
    input:SetScript("OnEnterPressed", function(self)
        local value = tonumber(self:GetText())
        if not value or value < 0 or value > 100000 then ns.Print(ns.L.INVALID_AMMO); return end
        ns.db.hunter.ammoWarning = math.floor(value)
        self:ClearFocus()
        ns.Refresh()
        ns.Options.Refresh()
    end)
    input:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        ns.Options.Refresh()
    end)
    return input
end

local function buildClassOptions(parent)
    local L = ns.L
    local name, class = UnitClass("player")
    heading(parent, name or L.TAB_CLASSES, -4)
    local options = classOptions[class]
    if not options then
        local message = UI.Text(parent, 13, T.muted)
        message:SetPoint("TOPLEFT", 6, -34)
        message:SetText(L.CLASS_SETTINGS_EMPTY)
        return 76
    end

    local moduleName = class:lower()
    local config = ns.db[moduleName]
    check(parent, L[options.enable], -32, function() return config.enabled end,
        function(value) config.enabled = value end)
    scale(parent, moduleName, L[options.scale] or name .. " · " .. L.SCALE, -64)

    local y, input = -98
    if class == "HUNTER" then
        input = ammoOptions(parent, y)
        heading(parent, L.HUNTER_GROUPS, y - 34)
        y = y - 62
    elseif class == "PALADIN" then
        equipmentSet(parent, "shield", L.SHIELD_SET, y)
        equipmentSet(parent, "twoHand", L.TWO_HAND_SET, y - 33)
        y = y - 66
    end
    for _, group in ipairs(options.groups) do
        local settings = config[group[1]]
        check(parent, L[group[2]], y, function() return settings.enabled end,
            function(value) settings.enabled = value end)
        y = y - 32
    end
    if class == "SHAMAN" then
        check(parent, L.SHOW_TOTEM_STATUS, y, function() return config.showTotemStatus end,
            function(value) config.showTotemStatus = value end)
        y = y - 32
    elseif class == "HUNTER" or class == "WARLOCK" then
        heading(parent, L.COMPANION, y - 4)
        check(parent, L.SHOW_COMPANION_FRAME, y - 30, function() return ns.db.companion.enabled end,
            function(value) ns.db.companion.enabled = value end)
        scale(parent, "companion", L.COMPANION .. " · " .. L.SCALE, y - 62)
        y = y - 94
    end
    return -y + 10, input
end

local function scrollPage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints(parent)
    local scroll = CreateFrame("ScrollFrame", nil, page)
    scroll:SetPoint("TOPLEFT", 18, -92)
    scroll:SetPoint("BOTTOMRIGHT", -34, 145)
    scroll:EnableMouseWheel(true)
    if scroll.SetPropagateMouseWheel then scroll:SetPropagateMouseWheel(true) end
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(364, 1)
    scroll:SetScrollChild(content)

    local bar = CreateFrame("Slider", nil, page)
    bar:SetOrientation("VERTICAL")
    bar:SetWidth(12)
    bar:SetPoint("TOPRIGHT", -12, -96)
    bar:SetPoint("BOTTOMRIGHT", -12, 150)
    local track = UI.Rect(bar, T.inset, "BACKGROUND")
    track:SetPoint("TOPLEFT", 3, -3)
    track:SetPoint("BOTTOMRIGHT", -3, 3)
    local thumb = UI.Rect(bar, T.gold, "OVERLAY")
    thumb:SetSize(8, 42)
    bar:SetThumbTexture(thumb)
    bar:SetValueStep(1)
    bar:SetObeyStepOnDrag(true)
    bar:SetScript("OnValueChanged", function(_, value) scroll:SetVerticalScroll(value) end)

    local function updateRange()
        local maximum = scroll:GetVerticalScrollRange()
        bar:SetMinMaxValues(0, maximum)
        bar:SetShown(maximum > 0)
        if bar:GetValue() > maximum then bar:SetValue(maximum) end
    end
    scroll:SetScript("OnScrollRangeChanged", updateRange)
    scroll:SetScript("OnShow", updateRange)
    scroll:SetScript("OnMouseWheel", function(_, delta)
        local _, maximum = bar:GetMinMaxValues()
        bar:SetValue(math.max(0, math.min(maximum, bar:GetValue() - delta * 48)))
    end)
    updateRange()
    return content, page
end

local function build()
    local L=ns.L
    refreshers={}
    frame=UI.CreatePanel(UIParent,"ForeverUI_Options");frame:SetSize(430,760);frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG");frame:SetMovable(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart",function(self) if not InCombatLockdown() then self:StartMoving() end end)
    frame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
    local title=UI.Text(frame,21,T.goldLight);title:SetPoint("TOPLEFT",24,-20);title:SetText(L.TITLE)
    UI.CloseButton(frame,function() frame:Hide() end)

    local general, generalPage = scrollPage(frame)
    local appearance, appearancePage = scrollPage(frame)
    local classes, classesPage = scrollPage(frame)
    local classHeight, input = buildClassOptions(classes)
    local bindings = CreateFrame("Frame", nil, classes)
    bindings:SetPoint("TOPLEFT", classes, "TOPLEFT", 0, -classHeight)
    local bindingHeight = UI.BuildBindingOptions(bindings, frame, refreshers)
    bindings:SetSize(364, math.max(1, bindingHeight))
    classes:SetHeight(classHeight + bindingHeight)

    local function divider(parent,y)
        local line=UI.Rect(parent,{0.55,0.36,0.16,0.65},"BORDER")
        line:SetPoint("TOPLEFT",6,y);line:SetPoint("TOPRIGHT",-6,y);line:SetHeight(1)
    end
    local generalTab = UI.Button(frame, L.TAB_GENERAL, 120)
    generalTab:SetSize(120, 30)
    generalTab:SetPoint("TOPLEFT", 24, -50)
    local classesTab = UI.Button(frame, L.TAB_CLASSES, 120)
    classesTab:SetSize(120, 30)
    classesTab:SetPoint("TOP", 0, -50)
    local appearanceTab = UI.Button(frame, L.TAB_APPEARANCE, 120)
    appearanceTab:SetSize(120, 30)
    appearanceTab:SetPoint("TOPRIGHT", -24, -50)
    local function selectTab(selected)
        if selected~="classes" and input and input:HasFocus() then input:ClearFocus() end
        generalPage:SetShown(selected == "general")
        classesPage:SetShown(selected == "classes")
        appearancePage:SetShown(selected == "appearance")
        generalTab.label:SetTextColor(unpack(selected=="general" and T.goldLight or T.muted))
        classesTab.label:SetTextColor(unpack(selected=="classes" and T.goldLight or T.muted))
        appearanceTab.label:SetTextColor(unpack(selected == "appearance" and T.goldLight or T.muted))
    end
    generalTab:SetScript("OnClick",function()selectTab("general")end)
    classesTab:SetScript("OnClick",function()selectTab("classes")end)
    appearanceTab:SetScript("OnClick", function() selectTab("appearance") end)

    heading(general,L.EXPERIENCE,-4)
    check(general,L.ENABLE_XP,-32,function()return ns.db.xp.enabled end,function(v)ns.db.xp.enabled=v end)
    check(general,L.ENABLE_PLAYER_FRAME,-64,function()return ns.db.player.enabled end,function(v)ns.Player.SetReplacementEnabled(v)end)
    scale(general,"player",L.PLAYER_FRAME_SCALE,-96)
    check(general,L.SHOW_AT_CAP,-128,function()return ns.db.xp.showAtCap end,function(v)ns.db.xp.showAtCap=v end)
    scale(general,"xp",L.EXPERIENCE.." · "..L.SCALE,-160)
    local widthLabel=UI.Text(general,13,T.text);widthLabel:SetPoint("TOPLEFT",24,-193);widthLabel:SetText(L.XP_WIDTH)
    local widthValue=UI.Text(general,13,T.goldLight);widthValue:SetPoint("TOPRIGHT",-65,-193)
    refreshers[#refreshers+1]=function()widthValue:SetText(ns.db.xp.width.." px")end
    for _,direction in ipairs({-1,1})do
        local step=UI.Button(general,direction==-1 and "-"or "+",25)
        step:SetSize(25,24);step:SetPoint("TOPRIGHT",direction==-1 and -130 or -25,-188)
        step:SetScript("OnClick",function()
            ns.db.xp.width=math.max(620,math.min(1600,ns.db.xp.width+direction*40))
            ns.Refresh();ns.Options.Refresh()
        end)
    end
    choice(general,L.QUEST_DISPLAY,"questDisplay",-232)
    choice(general,L.RESTED_DISPLAY,"restedDisplay",-265)
    divider(general,-302)
    heading(general,L.LOCK,-323)
    check(general,L.LOCK,-352,function()return ns.db.locked end,function(v)ns.db.locked=v end)

    divider(general,-388)
    heading(general,L.CAST_BAR,-408)
    check(general,L.ENABLE_CAST_BAR,-434,function()return ns.db.castBar.enabled end,function(v)ns.db.castBar.enabled=v end)
    scale(general,"castBar",L.CAST_BAR_SCALE,-470)

    divider(general, -508)
    heading(general, L.TARGET_FRAME, -524)
    check(general, L.ENABLE_TARGET_FRAME, -550, function() return ns.db.target.enabled end,
        function(value) ns.db.target.enabled = value end)
    scale(general, "target", L.TARGET_FRAME .. " · " .. L.SCALE, -588)
    divider(general, -622)
    heading(general, L.PARTY_FRAMES, -638)
    check(general, L.SHOW_PARTY_FRAMES, -664, function() return ns.db.party.enabled end,
        function(value) ns.db.party.enabled = value end)
    check(general, L.REPLACE_BLIZZARD_PARTY, -696, function() return ns.db.party.replaceBlizzard end,
        function(value) ns.db.party.replaceBlizzard = value end)
    scale(general, "party", L.PARTY_FRAMES .. " · " .. L.SCALE, -732)
    general:SetHeight(772)

    heading(appearance, L.ACTION_BARS, -4)
    check(appearance, L.STYLE_ACTION_BARS, -32, function() return ns.db.actionBars.enabled end,
        function(value) ns.db.actionBars.enabled = value end)
    opacity(appearance, ns.db.actionBars, -70, ns.ActionBars.Refresh)

    divider(appearance, -128)
    heading(appearance, L.INVENTORY, -146)
    check(appearance, L.STYLE_INVENTORY, -174, function() return ns.db.inventory.enabled end,
        function(value) ns.db.inventory.enabled = value end)
    opacity(appearance, ns.db.inventory, -212, ns.Inventory.Refresh)
    appearance:SetHeight(274)

    local preview=UI.Button(frame,L.PREVIEW_SHOW,175);preview:SetPoint("BOTTOMLEFT",24,95)
    preview:SetScript("OnClick",function() ns.Preview.SetEnabled(not ns.Preview.IsEnabled()) end)
    refreshers[#refreshers+1]=function()preview.label:SetText(ns.Preview.IsEnabled() and L.PREVIEW_HIDE or L.PREVIEW_SHOW)end
    local reset=UI.Button(frame,L.RESET,185);reset:SetPoint("BOTTOMRIGHT",-24,95)
    reset:SetScript("OnClick",function()
        local fresh=ns.Settings.Load(nil)
        ns.db.castBar.position=fresh.castBar.position
        ns.db.target.position = fresh.target.position
        ns.db.party.position = fresh.party.position
        ns.db.companion.position = fresh.companion.position
        ns.db.player.position=fresh.player.position;ns.db.hunter.position=fresh.hunter.position;ns.db.xp.position=fresh.xp.position
        ns.db.paladin.position=fresh.paladin.position;ns.db.warlock.position=fresh.warlock.position
        ns.db.priest.position=fresh.priest.position
        for _, moduleName in ipairs({"mage", "shaman", "druid", "rogue", "warrior"}) do
            local current, defaults = ns.db[moduleName], fresh[moduleName]
            current.position = defaults.position
            for _, key in ipairs({"totemGroup", "buffGroup", "utilityGroup", "stanceGroup", "interruptGroup"}) do
                if defaults[key] then current[key].position = defaults[key].position end
            end
        end
        for _, key in ipairs({"auraGroup", "blessingGroup", "weaponGroup", "macroGroup", "friendlyGroup"}) do
            ns.db.paladin[key].position = fresh.paladin[key].position
        end
        for _, key in ipairs({"summonGroup", "macroGroup", "friendlyGroup"}) do
            ns.db.warlock[key].position = fresh.warlock[key].position
        end
        ns.db.hunter.aspectGroup.position=fresh.hunter.aspectGroup.position
        ns.db.hunter.petGroup.position=fresh.hunter.petGroup.position
        ns.db.priest.buffGroup.position=fresh.priest.buffGroup.position
        ns.db.priest.supportGroup.position=fresh.priest.supportGroup.position
        ns.db.priest.macroGroup.position=fresh.priest.macroGroup.position
        ns.Refresh();ns.Options.Refresh()
    end)
    local hint=UI.Text(frame,11,T.muted);hint:SetPoint("BOTTOMLEFT",24,64);hint:SetText(IsMacClient and IsMacClient() and L.MOVE_HINT_MAC or L.MOVE_HINT)
    local note=UI.Text(frame,11,T.muted);note:SetPoint("BOTTOMLEFT",24,22);note:SetWidth(380);note:SetText(L.ALPHA_NOTE)
    selectTab("general")
    frame:Hide()
end
function ns.Options.Refresh()
    if refreshers then for _,refresh in ipairs(refreshers)do refresh()end end
end
function ns.Options.Toggle()
    if not frame then build() end
    frame:SetShown(not frame:IsShown());ns.Options.Refresh()
end
