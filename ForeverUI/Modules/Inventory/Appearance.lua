local _, ns = ...
local UI, T, R = ns.UI, ns.Theme, ns.Read
local Inventory = {}
ns.Inventory = Inventory

local events = {
    "ADDON_LOADED",
    "BAG_UPDATE_DELAYED", "BAG_CONTAINER_UPDATE", "INPUT_DEVICE_INTERFACE_TRANSITION",
    "BANKFRAME_OPENED", "BANKFRAME_CLOSED", "BANK_TABS_CHANGED",
    "PLAYER_INTERACTION_MANAGER_FRAME_SHOW", "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",
    "PLAYER_REGEN_ENABLED",
}
local tabEvent = "BankPanelMixin.TriggerSetTabEffects"
local bagSkins = {}
local bankSkin, countLabel, eventFrame, listening, bankRefreshPending, tabRegistry

local function backgroundOpacity()
    local options = ns.db and ns.db.inventory
    return math.min(1, math.max(0, R.Number(options and options.opacity) or 0.92))
end

local function gamepadEnabled()
    return R.Boolean(R.Call(InputUtil and InputUtil.IsGamepadUIEnabled))
end

local function syncChrome(chrome, window)
    local strata, level, scale, alpha = window:GetFrameStrata(), window:GetFrameLevel(), window:GetScale(), window:GetAlpha()
    if chrome:GetFrameStrata() ~= strata then chrome:SetFrameStrata(strata) end
    if chrome:GetFrameLevel() ~= level then chrome:SetFrameLevel(level) end
    if chrome:GetScale() ~= scale then chrome:SetScale(scale) end
    if chrome:GetAlpha() ~= alpha then chrome:SetAlpha(alpha) end
end

local function showChrome(skin)
    local visible = skin.visible and skin.window:IsVisible()
    if visible then syncChrome(skin.chrome, skin.window) end
    skin.chrome:SetShown(not not visible)
end

local function horizontalTrim(chrome, edge, y, height, opacity)
    local trim = UI.Rect(chrome, "edge", "BORDER", opacity)
    trim:SetPoint(edge .. "LEFT", 0, y)
    trim:SetPoint(edge .. "RIGHT", 0, y)
    trim:SetHeight(height)
end

local function verticalTrim(chrome, edge)
    local trim = UI.Rect(chrome, "edge", "BORDER")
    trim:SetPoint("TOP" .. edge)
    trim:SetPoint("BOTTOM" .. edge)
    trim:SetWidth(2)
end

local function styleSlot(skin, slot)
    local rim = skin.rims[slot]
    if not rim then
        -- The item icon is on BORDER. Stack counts and state overlays draw over this rim.
        rim = slot:CreateTexture(nil, "ARTWORK", nil, -1)
        rim:SetTexture("Interface\\Common\\WhiteIconFrame")
        rim:SetVertexColor(T.muted[1], T.muted[2], T.muted[3], 0.72)
        rim:SetAllPoints(slot)
        skin.rims[slot] = rim
    end
    rim:SetShown(true)
end

local function styleSlots(skin)
    local panel = skin.panel
    if not panel then return end
    if skin.bank then
        local character = Enum and Enum.BankType and Enum.BankType.Character
        if R.Call(skin.window.GetActiveBankType, skin.window) ~= character then return end
        if panel.EnumerateValidItems then
            for slot in panel:EnumerateValidItems() do styleSlot(skin, slot) end
        end
    elseif panel.EnumerateItems then
        for _, slot in panel:EnumerateItems() do styleSlot(skin, slot) end
    end
end

local function createSkin(frame, bank)
    -- Keep the backdrop out of scans of the native window and below its controls.
    local chrome = CreateFrame("Frame", nil, frame:GetParent())
    chrome:EnableMouse(false)
    chrome:SetAllPoints(frame)
    chrome:Hide()
    local fill = UI.Rect(chrome, {0.035, 0.15, 0.17, 1}, "BACKGROUND")
    fill:SetPoint("TOPLEFT", 0, -23)
    fill:SetPoint("BOTTOMRIGHT")

    local header = UI.Rect(chrome, {0.07, 0.24, 0.26, 1}, "BACKGROUND")
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(23)

    horizontalTrim(chrome, "TOP", 0, 2)
    horizontalTrim(chrome, "BOTTOM", 0, 2)
    verticalTrim(chrome, "LEFT")
    verticalTrim(chrome, "RIGHT")
    horizontalTrim(chrome, "TOP", -22, 1, 0.78)

    local native = {}
    local function fade(region)
        if region then native[#native + 1] = {region = region} end
    end
    fade(frame.Bg)
    fade(frame.NineSlice)
    if bank then
        fade(frame.Background)
        fade(frame.TopTileStreaks)
        fade(frame.BankPanel and frame.BankPanel.NineSlice)
    else
        fade(frame.Background1Slot)
    end

    local panel = bank and frame.BankPanel or frame
    local skin = {window = frame, chrome = chrome, fill = fill, header = header, native = native,
        title = frame.TitleContainer and frame.TitleContainer.TitleText, bank = bank, panel = panel, rims = {}}
    frame:HookScript("OnShow", function() showChrome(skin) end)
    frame:HookScript("OnHide", function() chrome:Hide() end)
    -- A native window can be raised while open and Blizzard rescales the bags to fit the screen.
    chrome:SetScript("OnUpdate", function() syncChrome(chrome, frame) end)
    local slotUpdate = bank and "GenerateItemSlotsForSelectedTab" or "UpdateItemSlots"
    if panel and panel[slotUpdate] then
        local refreshSlots = function() if skin.visible then styleSlots(skin) end end
        hooksecurefunc(panel, slotUpdate, function()
            if skin.visible then ns.CombatQueue.Request(skin, refreshSlots) end
        end)
    end
    return skin
end

local function updateNativeAlpha(entry, visible)
    local region = entry.region
    if visible then
        local original = region:GetAlpha()
        if original == 0 then return end
        if not entry.hooked then
            -- A later write can claim the property without changing its value.
            hooksecurefunc(region, "SetAlpha", function() entry.originalAlpha = nil end)
            entry.hooked = true
        end
        region:SetAlpha(0)
        entry.appliedAlpha = region:GetAlpha()
        if entry.appliedAlpha ~= original then entry.originalAlpha = original end
    else
        local original = entry.originalAlpha
        entry.originalAlpha = nil
        if original and region:GetAlpha() == entry.appliedAlpha then region:SetAlpha(original) end
        entry.appliedAlpha = nil
    end
end

local function sameColor(color, r, g, b, a)
    return color[1] == r and color[2] == g and color[3] == b and color[4] == a
end

local function updateNativeTitle(skin, visible)
    local title = skin.title
    if not title then return end
    if visible then
        local original = {title:GetTextColor()}
        if sameColor(original, unpack(T.goldLight)) then return end
        if not skin.titleHooked then
            hooksecurefunc(title, "SetTextColor", function() skin.originalTitleColor = nil end)
            skin.titleHooked = true
        end
        title:SetTextColor(unpack(T.goldLight))
        skin.appliedTitleColor = {title:GetTextColor()}
        if not sameColor(original, unpack(skin.appliedTitleColor)) then skin.originalTitleColor = original end
    else
        local original = skin.originalTitleColor
        skin.originalTitleColor = nil
        if original and sameColor(skin.appliedTitleColor, title:GetTextColor()) then
            title:SetTextColor(unpack(original))
        end
        skin.appliedTitleColor = nil
    end
end

local function showSkin(skin, visible, opacity)
    if not skin then return end
    if visible then
        skin.fill:SetAlpha(opacity)
        skin.header:SetAlpha(opacity)
    end
    if skin.visible == visible then return end
    skin.visible = visible
    showChrome(skin)
    if visible then
        styleSlots(skin)
    else
        for _, rim in pairs(skin.rims) do rim:Hide() end
    end
    for _, entry in ipairs(skin.native) do updateNativeAlpha(entry, visible) end
    updateNativeTitle(skin, visible)
end

local function styleBag(frame, opacity)
    if not (frame and frame.Bg and frame.NineSlice) then return end
    bagSkins[frame] = bagSkins[frame] or createSkin(frame, false)
    showSkin(bagSkins[frame], true, opacity)
end

local function freeBagSlots()
    local readSlots = C_Container and C_Container.GetContainerNumFreeSlots
    local first = Enum and Enum.BagIndex and Enum.BagIndex.Backpack
    local last = R.Number(NUM_BAG_FRAMES)
    if not (readSlots and first and last) then return end

    -- The mouse/keyboard combined window contains the backpack and ordinary bags.
    local total = 0
    for bag = first, last do
        local free = R.Number(R.Call(readSlots, bag))
        if not free or free < 0 then return end
        total = total + free
    end
    return total
end

local function refreshCount()
    if not countLabel then return end
    local slots = listening and not gamepadEnabled() and freeBagSlots()
    if slots then countLabel:SetText(ns.L.INVENTORY_FREE_SLOTS:format(slots)) end
    countLabel:SetShown(slots ~= nil and slots ~= false)
end

local function refreshBank()
    bankRefreshPending = nil
    if not listening or InCombatLockdown() then return end

    local frame = BankFrame
    local character = Enum and Enum.BankType and Enum.BankType.Character
    local visible = not gamepadEnabled() and character and frame and frame.Bg and frame.Background and frame.NineSlice
        and frame:IsShown() and frame:GetAlpha() > 0
        and R.Call(frame.GetActiveBankType, frame) == character
    if visible then
        local purchased = R.Number(R.Call(C_Bank and C_Bank.FetchNumPurchasedBankTabs, character))
        visible = purchased and purchased > 0
    end
    if visible then bankSkin = bankSkin or createSkin(frame, true) end
    showSkin(bankSkin, not not visible, backgroundOpacity())
end

local function queueBankRefresh()
    if not listening or bankRefreshPending then return end
    -- Wait for Blizzard to finish opening the bank and granting its free first tab.
    bankRefreshPending = true
    C_Timer.After(0, refreshBank)
end

local function onEvent(_, event, arg)
    if event == "BAG_UPDATE_DELAYED" or event == "BAG_CONTAINER_UPDATE" then
        refreshCount()
    elseif event == "INPUT_DEVICE_INTERFACE_TRANSITION" then
        Inventory.Refresh()
    elseif event == "ADDON_LOADED" then
        if arg == "Blizzard_UIPanels_Game" then Inventory.Refresh() end
    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" or event == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" then
        local interaction = Enum and Enum.PlayerInteractionType
        if interaction and (arg == interaction.Banker or arg == interaction.CharacterBanker or arg == interaction.AccountBanker) then
            queueBankRefresh()
        end
    else
        queueBankRefresh()
    end
end

local function applyAppearance()
    local options = ns.db and ns.db.inventory
    local enabled = options and options.enabled == true
    if not enabled then
        if not listening then return end
        listening = false
        eventFrame:UnregisterAllEvents()
        if tabRegistry then
            tabRegistry:UnregisterCallback(tabEvent, Inventory)
            tabRegistry = nil
        end
        for _, skin in pairs(bagSkins) do showSkin(skin, false) end
        showSkin(bankSkin, false)
        refreshCount()
        return
    end

    if not listening then
        listening = true
        for _, event in ipairs(events) do eventFrame:RegisterEvent(event) end
        if EventRegistry then
            EventRegistry:RegisterCallback(tabEvent, queueBankRefresh, Inventory)
            tabRegistry = EventRegistry
        end
    end

    local opacity = backgroundOpacity()
    local combined = ContainerFrameCombinedBags
    if gamepadEnabled() then
        for _, skin in pairs(bagSkins) do showSkin(skin, false) end
    else
        styleBag(combined, opacity)
        if combined and bagSkins[combined] and not countLabel then
            countLabel = UI.Text(combined, 10, T.muted)
            countLabel:SetPoint("RIGHT", combined, "TOPLEFT", 48, -46)
            countLabel:SetJustifyH("RIGHT")
        end
        for index = 1, NUM_CONTAINER_FRAMES or 0 do
            styleBag(_G["ContainerFrame" .. index], opacity)
        end
    end
    refreshCount()
    queueBankRefresh()
end

function Inventory.Refresh()
    if eventFrame then ns.CombatQueue.Request("inventoryAppearance", applyAppearance) end
end

function Inventory.Init()
    if eventFrame then return end
    eventFrame = CreateFrame("Frame")
    eventFrame:SetScript("OnEvent", onEvent)
    Inventory.Refresh()
end
