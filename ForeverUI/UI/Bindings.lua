local _, ns = ...
local UI, T = ns.UI, ns.Theme

function UI.BuildBindingOptions(parent, options, refreshers)
    local B, L = ns.Bindings, ns.L
    local actions = B.Actions()
    if #actions == 0 then return 0 end

    local heading = UI.Text(parent, 15, T.goldLight)
    heading:SetPoint("TOPLEFT", 6, -4)
    heading:SetText(L.BIND_HEADING)

    local capture = UI.CreatePanel(options)
    capture:SetSize(360, 120)
    capture:SetPoint("CENTER")
    capture:SetFrameLevel(options:GetFrameLevel() + 20)
    capture:EnableMouse(true)
    capture:Hide()
    UI.CloseButton(capture, function() capture:Hide() end)
    local title = UI.Text(capture, 15, T.goldLight)
    title:SetPoint("TOPLEFT", 18, -19)
    title:SetWidth(290)
    local instruction = UI.Text(capture, 12, T.text)
    instruction:SetPoint("TOPLEFT", 18, -50)
    instruction:SetWidth(322)
    instruction:SetText(L.BIND_CAPTURE)
    local notice = UI.Text(capture, 11, {1, 0.53, 0.39, 1})
    notice:SetPoint("BOTTOMLEFT", 18, 17)
    notice:SetWidth(322)

    local activeID, heldKey, combination
    capture:SetScript("OnHide", function()
        activeID, heldKey, combination = nil, nil, nil
        capture:EnableKeyboard(false)
        capture:UnregisterEvent("PLAYER_REGEN_DISABLED")
    end)
    capture:SetScript("OnEvent", function() capture:Hide() end)
    capture:SetScript("OnKeyDown", function(_, key)
        local candidate = B.ReadKey(key)
        if candidate and not heldKey then heldKey, combination = key, candidate end
    end)
    capture:SetScript("OnKeyUp", function(_, key)
        if key == "ESCAPE" then capture:Hide(); return end
        if key ~= heldKey or not activeID then return end
        local success, errorText = B.Set(activeID, combination)
        heldKey, combination = nil, nil
        if success then
            capture:Hide()
            ns.Options.Refresh()
        else
            notice:SetText(errorText)
        end
    end)
    parent:HookScript("OnHide", function() capture:Hide() end)

    for index, entry in ipairs(actions) do
        local id, label = entry[1], L[entry[2]]
        local y = -32 - (index - 1) * 31
        local text = UI.Text(parent, 12, T.text)
        text:SetPoint("TOPLEFT", 24, y - 4)
        text:SetWidth(188)
        text:SetText(label)

        local assign = UI.Button(parent, "", 108)
        assign:SetSize(108, 25)
        assign:SetPoint("TOPRIGHT", -46, y)
        assign.label:SetWidth(102)
        assign.label:SetJustifyH("CENTER")
        assign:SetScript("OnClick", function()
            if InCombatLockdown() then ns.Print(L.BIND_COMBAT); return end
            activeID, heldKey, combination = id, nil, nil
            title:SetText(label)
            notice:SetText("")
            capture:SetPropagateKeyboardInput(false)
            capture:EnableKeyboard(true)
            capture:RegisterEvent("PLAYER_REGEN_DISABLED")
            capture:Show()
        end)
        assign:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(label)
            local status = B.Status(id)
            if status then GameTooltip:AddLine(status, 1, 0.65, 0.49, true) end
            GameTooltip:Show()
        end)
        assign:SetScript("OnLeave", function() GameTooltip:Hide() end)

        local clear = UI.Button(parent, "×", 25)
        clear:SetSize(25, 25)
        clear:SetPoint("TOPRIGHT", -13, y)
        UI.Tooltip(clear, L.BIND_CLEAR)
        clear:SetScript("OnClick", function()
            local success, errorText = B.Set(id, nil)
            if not success then ns.Print(errorText) end
            ns.Options.Refresh()
        end)

        refreshers[#refreshers + 1] = function()
            local key = ns.db.bindings[id]
            local display = key and GetBindingText and GetBindingText(key, "KEY_", true)
            assign.label:SetText(display and display ~= "" and display or key or L.BIND_ASSIGN)
            clear:SetShown(key ~= nil)
        end
    end

    return 44 + #actions * 31
end
