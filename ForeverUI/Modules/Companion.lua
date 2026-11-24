local _, ns = ...
local UI, T, R, L = ns.UI, ns.Theme, ns.Read, ns.L
local M = {}
ns.Companion = M

local classes = {HUNTER = true, WARLOCK = true}
local live, demo
local active = false
local stockFrame, stockParent, hiddenParent

local function secret(value)
    return issecretvalue and issecretvalue(value)
end

local function readUnit(api, unit)
    if type(api) ~= "function" then return nil end
    local ok, value = pcall(api, unit)
    if ok then return value end
end

local function setName(label, value, fallback)
    if secret(value) then
        if pcall(label.SetText, label, value) then return end
    elseif type(value) == "string" and value ~= "" then
        label:SetText(value)
        return
    end
    label:SetText(fallback)
end

local function setHealth(view, current, maximum)
    local currentSecret, maximumSecret = secret(current), secret(maximum)
    local readableCurrent, readableMaximum = R.Number(current), R.Number(maximum)
    if not maximumSecret and (not readableMaximum or readableMaximum <= 0) then
        view.health:SetMinMaxValues(0, 1)
        view.health:SetValue(0)
        view.amount:SetText("– / –")
        return
    end

    if not pcall(view.health.SetMinMaxValues, view.health, 0, maximum) then
        view.health:SetMinMaxValues(0, 1)
    end
    if currentSecret or readableCurrent then
        if not pcall(view.health.SetValue, view.health, current) then view.health:SetValue(0) end
    else
        view.health:SetValue(0)
    end

    local left, right = current, maximum
    if not currentSecret then left = ns.Format.Number(readableCurrent) end
    if not maximumSecret then right = ns.Format.Number(readableMaximum) end
    if not pcall(view.amount.SetFormattedText, view.amount, "%s / %s", left, right) then
        view.amount:SetText("– / –")
    end
end

local function openPetMenu(frame, unit)
    if type(UnitPopup_OpenMenu) == "function" then
        UnitPopup_OpenMenu("PET", {ownerFrame = frame, unit = unit})
    end
end

local function createView(name, preview)
    local frame
    if preview then
        frame = UI.CreatePanel(UIParent, name)
    else
        frame = CreateFrame("Button", name, UIParent, "SecureUnitButtonTemplate")
        frame:SetClampedToScreen(true)
        UI.Decorate(frame)
        SecureUnitButton_OnLoad(frame, "pet", openPetMenu)
    end
    frame:SetSize(228, 64)
    UI.MakeMovable(frame, "companion")

    local portrait = frame:CreateTexture(nil, "ARTWORK")
    portrait:SetPoint("TOPLEFT", 11, -11)
    portrait:SetSize(30, 30)
    portrait:SetTexture(T.icons.pet)

    local petName = UI.Text(frame, 12, T.goldLight)
    petName:SetPoint("TOPLEFT", 49, -13)
    petName:SetPoint("TOPRIGHT", -92, -13)
    petName:SetWordWrap(false)
    local amount = UI.Text(frame, 10, T.text)
    amount:SetPoint("TOPLEFT", 145, -14)
    amount:SetPoint("TOPRIGHT", -11, -14)
    amount:SetJustifyH("RIGHT")
    amount:SetWordWrap(false)

    local track = UI.Rect(frame, T.inset, "BACKGROUND")
    track:SetPoint("TOPLEFT", 49, -33)
    track:SetPoint("TOPRIGHT", -11, -33)
    track:SetHeight(6)
    local health = CreateFrame("StatusBar", nil, frame)
    health:SetAllPoints(track)
    health:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
    health:SetStatusBarColor(unpack(T.good))

    local caption = UI.Text(frame, 10, T.muted)
    caption:SetPoint("TOPLEFT", 11, -46)
    caption:SetText(L.COMPANION_TARGET)
    local target = UI.Text(frame, 10, T.text)
    target:SetPoint("TOPLEFT", caption, "TOPRIGHT", 8, 0)
    target:SetPoint("TOPRIGHT", -11, -46)
    target:SetWordWrap(false)

    frame:Hide()
    return {frame = frame, portrait = portrait, name = petName, target = target, amount = amount, health = health}
end

local function replaceStock(enabled)
    if enabled then
        local frame = PetFrame
        if not frame then return true end
        if not hiddenParent then
            hiddenParent = CreateFrame("Frame", nil, UIParent)
            hiddenParent:Hide()
        end
        local parent = frame:GetParent()
        if parent ~= hiddenParent then
            -- Leave the native unit watch and child widgets intact under a hidden parent.
            pcall(frame.SetParent, frame, hiddenParent)
            if frame:GetParent() ~= hiddenParent then return false end
            stockFrame, stockParent = frame, parent
        end
        return true
    end

    if stockFrame then
        if stockFrame:GetParent() == hiddenParent then
            pcall(stockFrame.SetParent, stockFrame, stockParent)
            if stockFrame:GetParent() == hiddenParent then return true end
        end
        stockFrame, stockParent = nil, nil
    end
    return false
end

local function renderLive(portraitChanged)
    if not active or R.Boolean(R.Call(UnitExists, "pet")) ~= true then return end

    if (portraitChanged or not live.portraitReady) and type(SetPortraitTexture) == "function" then
        if not pcall(SetPortraitTexture, live.portrait, "pet") then live.portrait:SetTexture(T.icons.pet) end
        live.portraitReady = true
    end
    setName(live.name, readUnit(UnitName, "pet"), L.COMPANION)
    setHealth(live, readUnit(UnitHealth, "pet"), readUnit(UnitHealthMax, "pet"))

    local target
    if R.Boolean(R.Call(UnitExists, "pettarget")) == true then target = readUnit(UnitName, "pettarget") end
    setName(live.target, target, "–")
end

function M.Refresh(portraitChanged)
    if not live then return end
    if not InCombatLockdown() then
        local config = ns.db.companion
        local editMode = EditModeManagerFrame
            and R.Boolean(R.Call(EditModeManagerFrame.IsEditModeActive, EditModeManagerFrame))
        local driving = R.Boolean(R.Call(UnitInVehicle, "player")) == true
        local enabled = config and config.enabled and not ns.Preview.IsEnabled() and not editMode and not driving
        local replacing = replaceStock(enabled)
        if replacing ~= active then
            active = replacing
            if active then
                RegisterUnitWatch(live.frame)
                portraitChanged = true
            else
                UnregisterUnitWatch(live.frame)
                live.frame:Hide()
            end
        end
        if not live.frame.dragging then UI.Place(live.frame, "companion") end
    end
    renderLive(portraitChanged)
end

function M.Preview(enabled, classToken)
    local visible = enabled and classes[classToken] and ns.db.companion.enabled
    if not visible then
        if demo then demo.frame:Hide() end
        return
    end

    if not demo then demo = createView("ForeverUI_PreviewCompanion", true) end
    if not InCombatLockdown() and not demo.frame.dragging then UI.Place(demo.frame, "companion") end
    demo.name:SetText(classToken == "WARLOCK" and L.DEMON_SAMPLE or L.COMPANION_SAMPLE_PET)
    demo.target:SetText(L.COMPANION_SAMPLE_TARGET)
    setHealth(demo, 780, 940)
    demo.frame:Show()
end

function M.Init()
    if live then return end
    local _, class = UnitClass("player")
    if not classes[class] then return end

    live = createView("ForeverUI_Companion")
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("PET_UI_UPDATE")
    events:RegisterUnitEvent("UNIT_ENTERED_VEHICLE", "player")
    events:RegisterUnitEvent("UNIT_EXITED_VEHICLE", "player")
    events:RegisterUnitEvent("UNIT_PET", "player")
    events:RegisterUnitEvent("UNIT_TARGET", "pet")
    events:RegisterUnitEvent("UNIT_HEALTH", "pet")
    events:RegisterUnitEvent("UNIT_MAXHEALTH", "pet")
    events:RegisterUnitEvent("UNIT_NAME_UPDATE", "pet", "pettarget")
    events:RegisterUnitEvent("UNIT_PORTRAIT_UPDATE", "pet")
    events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_REGEN_ENABLED" or event == "UNIT_PET"
            or event == "PET_UI_UPDATE" or event == "UNIT_ENTERED_VEHICLE" or event == "UNIT_EXITED_VEHICLE" then
            M.Refresh(true)
        else
            renderLive(event == "UNIT_PORTRAIT_UPDATE")
        end
    end)
    if EventRegistry then
        EventRegistry:RegisterCallback("EditMode.Enter", function() M.Refresh() end, M)
        EventRegistry:RegisterCallback("EditMode.Exit", function() M.Refresh() end, M)
    end
    M.Refresh()
end
