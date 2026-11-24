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
    local thumb = UI.Rect(slider, "edge", "OVERLAY")
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

local function auraPinOption(parent, y)
    local L, R = ns.L, ns.Read
    local button = UI.Button(parent, L.AURA_PINS, 220)
    button:SetPoint("TOPLEFT", 24, y)
    local count = UI.Text(parent, 12, T.muted)
    count:SetPoint("LEFT", button, "RIGHT", 10, 0)
    refreshers[#refreshers + 1] = function()
        count:SetFormattedText("%d / 8", #ns.db.player.priorityAuras)
    end

    local function spellLabel(id, name)
        name = name or R.Call(C_Spell and C_Spell.GetSpellName, id)
        return type(name) == "string" and name or L.AURA_SPELL:format(id)
    end
    local function changed()
        ns.Refresh()
        ns.Options.Refresh()
    end

    button:SetScript("OnClick", function(self)
        if not MenuUtil or not MenuUtil.CreateContextMenu then return end
        MenuUtil.CreateContextMenu(self, function(_, menu)
            local pinned = ns.db.player.priorityAuras
            local shown = {}
            for _, id in ipairs(pinned) do
                local spell = id
                shown[spell] = true
                menu:CreateButton(L.AURA_UNPIN:format(spellLabel(spell)), function()
                    for index, selected in ipairs(ns.db.player.priorityAuras) do
                        if selected == spell then
                            table.remove(ns.db.player.priorityAuras, index)
                            changed()
                            return
                        end
                    end
                end)
            end
            if #pinned >= 8 then
                menu:CreateTitle(L.AURA_PIN_LIMIT)
                return
            end

            local readAura = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
            local found = false
            for index = 1, 40 do
                local ok, aura = R.Try(readAura, "player", index, "HELPFUL")
                if ok and not aura then break end
                local id = type(aura) == "table" and R.Number(aura.spellId)
                if id and id > 0 and not shown[id] then
                    local spell = id
                    shown[spell], found = true, true
                    local name = R.Call(function() return aura.name end)
                    menu:CreateButton(L.AURA_PIN:format(spellLabel(spell, name)), function()
                        local selected = ns.db.player.priorityAuras
                        if #selected < 8 then
                            for _, other in ipairs(selected) do if other == spell then return end end
                            selected[#selected + 1] = spell
                            changed()
                        end
                    end)
                end
            end
            if not found then menu:CreateTitle(L.AURA_PIN_EMPTY) end
        end)
    end)
end

local function judgementSealOption(parent, y)
    local L = ns.L
    local config = ns.db.paladin
    local label = UI.Text(parent, 13, T.text)
    label:SetPoint("TOPLEFT", 24, y)
    label:SetText(L.PALADIN_JUDGEMENT_SEAL)
    local button = UI.Button(parent, L.SET_NONE, 162)
    button:SetPoint("TOPRIGHT", -16, y + 6)
    button.label:SetWidth(150)
    button.label:SetWordWrap(false)
    button.label:SetJustifyH("CENTER")
    local function selected(seals) return ns.PaladinModel.SelectSeal(seals, config.judgementSeal) end
    refreshers[#refreshers + 1] = function()
        local seal = selected(ns.Paladin.Seals())
        button.label:SetText(seal and seal.name or L.SET_NONE)
    end
    button:SetScript("OnClick", function()
        if not MenuUtil or not MenuUtil.CreateContextMenu then return end
        local seals = ns.Paladin.Seals()
        MenuUtil.CreateContextMenu(button, function(_, root)
            root:CreateTitle(L.PALADIN_JUDGEMENT_SEAL)
            local current = selected(seals)
            for _, seal in ipairs(seals) do
                root:CreateRadio(seal.name, function() return current == seal end, function()
                    config.judgementSeal = seal.id
                    ns.Refresh()
                    ns.Options.Refresh()
                end)
            end
        end)
    end)
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
        judgementSealOption(parent, y - 70)
        y = y - 108
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

local function buildProfileOptions(parent)
    local L, profiles = ns.L, ns.Profiles
    local description = UI.Text(parent, 12, T.muted)
    description:SetPoint("TOPLEFT", 24, -6)
    description:SetWidth(324)
    description:SetText(L.PROFILE_SCOPE)

    local label = UI.Text(parent, 13, T.text)
    label:SetPoint("TOPLEFT", 24, -54)
    label:SetText(L.PROFILE_NAME)
    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetSize(182, 26)
    input:SetPoint("TOPLEFT", 24, -76)
    input:SetAutoFocus(false)
    input:SetMaxBytes(64)
    input:SetScript("OnEnterPressed", input.ClearFocus)
    input:SetScript("OnEscapePressed", input.ClearFocus)

    local picker = UI.Button(parent, L.PROFILE_PICK, 131)
    picker:SetPoint("TOPRIGHT", -14, -75)
    local save = UI.Button(parent, L.PROFILE_SAVE, 150)
    save:SetPoint("TOPLEFT", 24, -124)
    local load = UI.Button(parent, L.PROFILE_LOAD, 150)
    load:SetPoint("TOPRIGHT", -14, -124)
    local status = UI.Text(parent, 12, T.muted)
    status:SetPoint("TOPLEFT", 24, -173)
    status:SetWidth(324)

    local pending = false
    local function refresh()
        local name = profiles.Name(input:GetText())
        local exists = profiles.Exists(name)
        save.label:SetText(exists and L.PROFILE_UPDATE or L.PROFILE_SAVE)
        save:SetEnabled(name ~= nil and not pending)
        load:SetEnabled(exists and not pending)
        picker:SetEnabled(not pending and MenuUtil ~= nil and #profiles.List() > 0)
    end
    refreshers[#refreshers + 1] = refresh
    input:SetScript("OnTextChanged", refresh)

    picker:SetScript("OnClick", function()
        MenuUtil.CreateContextMenu(picker, function(_, menu)
            for _, name in ipairs(profiles.List()) do
                menu:CreateRadio(name, function() return profiles.Name(input:GetText()) == name end, function()
                    input:SetText(name)
                    input:ClearFocus()
                end)
            end
        end)
    end)
    save:SetScript("OnClick", function()
        local name = profiles.Save(input:GetText(), ns.db)
        if not name then return end
        input:SetText(name)
        input:ClearFocus()
        status:SetText(L.PROFILE_SAVED:format(name))
        refresh()
    end)
    load:SetScript("OnClick", function()
        local name = profiles.Name(input:GetText())
        if not profiles.Exists(name) then return end
        input:ClearFocus()
        if InCombatLockdown() then
            pending = true
            status:SetText(L.PROFILE_PENDING)
            refresh()
        end
        ns.CombatQueue.Request("load-profile", function()
            pending = false
            if profiles.Apply(name, ns.db) then
                T.SetClassAccent(ns.db.classAccent)
                ns.MinimapButton.Refresh()
                ns.Refresh()
                status:SetText(L.PROFILE_LOADED:format(name))
            end
            ns.Options.Refresh()
        end)
    end)
    parent:SetHeight(232)
    return input
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
    local thumb = UI.Rect(bar, "edge", "OVERLAY")
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
    local profiles, profilesPage = scrollPage(frame)
    local classHeight, input = buildClassOptions(classes)
    local profileInput = buildProfileOptions(profiles)
    local bindings = CreateFrame("Frame", nil, classes)
    bindings:SetPoint("TOPLEFT", classes, "TOPLEFT", 0, -classHeight)
    local bindingHeight = UI.BuildBindingOptions(bindings, frame, refreshers)
    bindings:SetSize(364, math.max(1, bindingHeight))
    classes:SetHeight(classHeight + bindingHeight)

    local function divider(parent,y)
        local line=UI.Rect(parent,{0.55,0.36,0.16,0.65},"BORDER")
        line:SetPoint("TOPLEFT",6,y);line:SetPoint("TOPRIGHT",-6,y);line:SetHeight(1)
    end
    local tabs = {
        {key = "general", label = L.TAB_GENERAL, page = generalPage},
        {key = "classes", label = L.TAB_CLASSES, page = classesPage},
        {key = "appearance", label = L.TAB_APPEARANCE, page = appearancePage},
        {key = "profiles", label = L.TAB_PROFILES, page = profilesPage},
    }
    local function selectTab(selected)
        if selected ~= "classes" and input and input:HasFocus() then input:ClearFocus() end
        if selected ~= "profiles" and profileInput:HasFocus() then profileInput:ClearFocus() end
        for _, tab in ipairs(tabs) do
            local active = tab.key == selected
            tab.page:SetShown(active)
            tab.button.label:SetTextColor(unpack(active and T.goldLight or T.muted))
        end
    end
    for index, tab in ipairs(tabs) do
        local button = UI.Button(frame, tab.label, 91)
        button:SetHeight(30)
        button:SetPoint("TOPLEFT", 24 + (index - 1) * 97, -50)
        button:SetScript("OnClick", function() selectTab(tab.key) end)
        tab.button = button
    end

    heading(general,L.EXPERIENCE,-4)
    check(general,L.ENABLE_XP,-32,function()return ns.db.xp.enabled end,function(v)ns.db.xp.enabled=v end)
    check(general,L.SHOW_AT_CAP,-64,function()return ns.db.xp.showAtCap end,function(v)ns.db.xp.showAtCap=v end)
    scale(general,"xp",L.EXPERIENCE.." · "..L.SCALE,-96)
    local widthLabel=UI.Text(general,13,T.text);widthLabel:SetPoint("TOPLEFT",24,-129);widthLabel:SetText(L.XP_WIDTH)
    local widthValue=UI.Text(general,13,T.goldLight);widthValue:SetPoint("TOPRIGHT",-65,-129)
    refreshers[#refreshers+1]=function()widthValue:SetText(ns.db.xp.width.." px")end
    for _,direction in ipairs({-1,1})do
        local step=UI.Button(general,direction==-1 and "-"or "+",25)
        step:SetSize(25,24);step:SetPoint("TOPRIGHT",direction==-1 and -130 or -25,-124)
        step:SetScript("OnClick",function()
            ns.db.xp.width=math.max(620,math.min(1600,ns.db.xp.width+direction*40))
            ns.Refresh();ns.Options.Refresh()
        end)
    end
    choice(general,L.QUEST_DISPLAY,"questDisplay",-168)
    choice(general,L.RESTED_DISPLAY,"restedDisplay",-201)
    divider(general,-238)

    heading(general, L.PLAYER_FRAME, -254)
    check(general,L.ENABLE_PLAYER_FRAME,-280,function()return ns.db.player.enabled end,function(v)ns.Player.SetReplacementEnabled(v)end)
    check(general, L.HIDE_BLIZZARD_AURAS, -312, function() return ns.db.player.hideBlizzardAuras end,
        function(value) ns.db.player.hideBlizzardAuras = value end)
    scale(general,"player",L.PLAYER_FRAME_SCALE,-348)
    auraPinOption(general, -379)
    divider(general, -421)

    heading(general, L.LAYOUT, -437)
    check(general, L.LOCK, -463, function() return ns.db.locked end, function(value) ns.db.locked = value end)
    check(general, L.LAYOUT_GRID, -495, function() return ns.db.layout.grid end, function(value) ns.db.layout.grid = value end)
    check(general, L.LAYOUT_SNAP, -527, function() return ns.db.layout.snap end, function(value) ns.db.layout.snap = value end)
    check(general, L.LAYOUT_DOCK_CLASS, -559, function() return ns.db.layout.attachClass end,
        function(value) ns.db.layout.attachClass = value end)
    local editLayout = UI.Button(general, L.LAYOUT_EDIT, 220)
    editLayout:SetPoint("TOPLEFT", 24, -592)
    editLayout:SetScript("OnClick", function()
        if ns.Layout.SetEditing(true) then frame:Hide() end
    end)

    divider(general, -638)
    heading(general, L.CAST_BAR, -654)
    check(general, L.ENABLE_CAST_BAR, -680, function() return ns.db.castBar.enabled end,
        function(value) ns.db.castBar.enabled = value end)
    scale(general, "castBar", L.CAST_BAR_SCALE, -716)

    divider(general, -754)
    heading(general, L.TARGET_FRAME, -770)
    check(general, L.ENABLE_TARGET_FRAME, -796, function() return ns.db.target.enabled end,
        function(value) ns.db.target.enabled = value end)
    check(general, L.TARGET_OWN_AURA_TIMERS, -828, function() return ns.db.target.showOwnAuraTimers end,
        function(value) ns.db.target.showOwnAuraTimers = value end)
    check(general, L.SHOW_TARGET_THREAT, -860, function() return ns.db.target.showThreat end,
        function(value) ns.db.target.showThreat = value end)
    scale(general, "target", L.TARGET_FRAME .. " · " .. L.SCALE, -896)

    divider(general, -930)
    heading(general, L.PARTY_FRAMES, -946)
    check(general, L.SHOW_PARTY_FRAMES, -972, function() return ns.db.party.enabled end,
        function(value) ns.db.party.enabled = value end)
    check(general, L.REPLACE_BLIZZARD_PARTY, -1004, function() return ns.db.party.replaceBlizzard end,
        function(value) ns.db.party.replaceBlizzard = value end)
    check(general, L.PARTY_COMPACT, -1036, function() return ns.db.party.compact end,
        function(value) ns.db.party.compact = value end)
    check(general, L.PARTY_SHOW_PORTRAITS, -1068, function() return ns.db.party.showPortrait end,
        function(value) ns.db.party.showPortrait = value end)
    check(general, L.PARTY_SHOW_MISSING_BUFF, -1100, function() return ns.db.party.showMissingBuff end,
        function(value) ns.db.party.showMissingBuff = value end)
    scale(general, "party", L.PARTY_FRAMES .. " · " .. L.SCALE, -1136)

    divider(general, -1170)
    heading(general, L.COMFORT, -1186)
    check(general, L.AUTO_REPAIR, -1212, function() return ns.db.comfort.autoRepair end,
        function(value) ns.db.comfort.autoRepair = value end)
    check(general, L.SELL_JUNK, -1244, function() return ns.db.comfort.sellJunk end,
        function(value) ns.db.comfort.sellJunk = value end)
    check(general, L.SHOW_TOOLTIP_ITEM_LEVEL, -1276, function() return ns.db.comfort.tooltipItemLevel end,
        function(value) ns.db.comfort.tooltipItemLevel = value end)
    general:SetHeight(1318)

    check(appearance, L.CLASS_ACCENT, -6, function() return ns.db.classAccent end,
        function(value)
            ns.db.classAccent = value
            T.SetClassAccent(value)
        end)
    divider(appearance, -42)
    heading(appearance, L.ACTION_BARS, -56)
    check(appearance, L.STYLE_ACTION_BARS, -84, function() return ns.db.actionBars.enabled end,
        function(value) ns.db.actionBars.enabled = value end)
    check(appearance, L.HIDE_EMPTY_ACTION_SLOTS, -116, function() return ns.db.actionBars.hideEmpty end,
        function(value) ns.db.actionBars.hideEmpty = value end)
    opacity(appearance, ns.db.actionBars, -154, ns.ActionBars.Refresh)

    divider(appearance, -212)
    heading(appearance, L.INVENTORY, -230)
    check(appearance, L.STYLE_INVENTORY, -258, function() return ns.db.inventory.enabled end,
        function(value) ns.db.inventory.enabled = value end)
    opacity(appearance, ns.db.inventory, -296, ns.Inventory.Refresh)
    divider(appearance, -354)
    heading(appearance, L.UNIT_FRAME_APPEARANCE, -372)
    check(appearance, L.STYLE_RAID_FRAMES, -401, function() return ns.db.raidFrameStyle end,
        function(value) ns.db.raidFrameStyle = value end)
    check(appearance, L.STYLE_ENEMY_FRAMES, -433, function() return ns.db.enemyFrameStyle end,
        function(value) ns.db.enemyFrameStyle = value end)
    divider(appearance, -470)
    heading(appearance, L.MINIMAP, -486)
    check(appearance, L.MINIMAP_COLLECT_ADDONS, -512, function() return ns.db.minimapButton.collect end,
        function(value) ns.db.minimapButton.collect = value end)
    appearance:SetHeight(554)

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
        for _, moduleName in ipairs({"hunter", "paladin", "warlock", "priest", "mage", "shaman", "druid", "rogue", "warrior"}) do
            ns.db[moduleName].dockPosition = fresh[moduleName].dockPosition
        end
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
