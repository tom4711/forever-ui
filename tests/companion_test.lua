local noop = function() end

local function withCompanion(class, run)
    local inCombat, exists, preview, editMode = false, true, false, false
    local watch, eventFrame, openMenuType, openMenuData
    local editCallbacks = {}
    local function widget(parent)
        local frame = {shown = true, parent = parent}
        function frame:GetParent() return self.parent end
        function frame:SetParent(newParent)
            assert(not inCombat, "protected parent changed in combat")
            self.parent = newParent
        end
        function frame:IsShown() return self.shown end
        function frame:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
        function frame:Hide()
            assert(not (self.secure and inCombat), "protected visibility changed in combat")
            self.shown = false
        end
        function frame:Show()
            assert(not (self.secure and inCombat), "protected visibility changed in combat")
            self.shown = true
        end
        function frame:CreateTexture() return widget() end
        function frame:SetScript(name, callback) self[name] = callback end
        return setmetatable(frame, {__index = function(_, method)
            if method:match("^[A-Z]") then return noop end
        end})
    end

    local root = widget()
    local stockParent = widget(root)
    local stock = widget(stockParent)
    local petCast = widget(root)
    local frames = {}
    local ns = {
        db = {companion = {enabled = true}},
        Theme = {icons = {pet = 132161}, good = {}, inset = {}},
        L = {}, Preview = {IsEnabled = function() return preview end},
        Format = {Number = tostring},
        UI = {
            CreatePanel = function(parent, name)
                local panel = widget(parent)
                frames[name] = panel
                return panel
            end,
            Decorate = noop,
            Place = function() assert(not inCombat, "protected placement changed in combat") end,
            MakeMovable = noop,
            Text = function() return widget() end,
            Rect = function() return widget() end,
        },
    }
    withGlobals({
        UIParent = root, PetFrame = stock, PetCastingBarFrame = petCast,
        UnitClass = function() return class, class end,
        UnitExists = function(unit) return unit == "pet" and exists end,
        UnitHealth = function() return 10 end,
        UnitHealthMax = function() return 15 end,
        InCombatLockdown = function() return inCombat end,
        UnitInVehicle = function() return false end,
        EditModeManagerFrame = {IsEditModeActive = function() return editMode end},
        EventRegistry = {RegisterCallback = function(_, event, callback) editCallbacks[event] = callback end},
        SecureUnitButton_OnLoad = function(button, unit, menu) button.unit, button.menu = unit, menu end,
        UnitPopup_OpenMenu = function(kind, data) openMenuType, openMenuData = kind, data end,
        RegisterUnitWatch = function(frame)
            assert(not inCombat)
            watch = frame
            frame.shown = exists
        end,
        UnregisterUnitWatch = function(frame)
            assert(not inCombat and frame == watch)
            watch = nil
        end,
        CreateFrame = function(kind, name, parent, template)
            local frame = widget(parent)
            frame.secure = template == "SecureUnitButtonTemplate"
            if name then frames[name] = frame end
            if kind == "Frame" and not name and not parent then eventFrame = frame end
            return frame
        end,
    }, function()
        loadAddon("Core/Read.lua", ns)
        loadAddon("Modules/Companion.lua", ns)
        ns.Companion.Init()
        run(ns, frames, stock, stockParent, petCast, {
            changePet = function(value)
                exists = value
                stock.shown = value
                if watch then watch.shown = value end
                eventFrame.OnEvent(eventFrame, "UNIT_PET")
            end,
            setCombat = function(value)
                inCombat = value
                if not value then eventFrame.OnEvent(eventFrame, "PLAYER_REGEN_ENABLED") end
            end,
            setPreview = function(value)
                preview = value
                ns.Companion.Preview(value, class)
                ns.Companion.Refresh()
            end,
            editMode = function(value)
                editMode = value
                editCallbacks[value and "EditMode.Enter" or "EditMode.Exit"]()
            end,
            menu = function() return openMenuType, openMenuData end,
        })
    end)
end

for _, class in ipairs({"HUNTER", "WARLOCK"}) do
    test("the " .. class .. " companion uses one visible clickable pet frame", function()
        withCompanion(class, function(ns, frames, stock, parent, cast, game)
            local pet = assert(frames.ForeverUI_Companion)
            assert(pet.secure and pet.unit == "pet" and pet:IsVisible())
            assert(stock:IsShown() and not stock:IsVisible() and cast:IsVisible())
            pet.menu(pet, "pet")
            local kind, data = game.menu()
            assert(kind == "PET" and data.ownerFrame == pet and data.unit == "pet")

            game.setCombat(true)
            game.changePet(false)
            assert(not pet:IsVisible() and not stock:IsVisible())
            game.changePet(true)
            assert(pet:IsVisible() and not stock:IsVisible())
            ns.db.companion.enabled = false
            ns.Companion.Refresh()
            assert(pet:IsVisible() and not stock:IsVisible())
            game.setCombat(false)
            assert(not pet:IsVisible() and stock:IsVisible() and stock:GetParent() == parent)

            ns.db.companion.enabled = true
            ns.Companion.Refresh()
            game.setPreview(true)
            assert(frames.ForeverUI_PreviewCompanion:IsVisible() and not pet:IsVisible() and stock:IsVisible())
            game.setPreview(false)
            assert(pet:IsVisible() and not stock:IsVisible())

            game.editMode(true)
            assert(not pet:IsVisible() and stock:IsVisible())
            game.editMode(false)
            assert(pet:IsVisible() and not stock:IsVisible())
        end)
    end)
end

test("a class without a Forever companion leaves the Blizzard pet alone", function()
    withCompanion("MAGE", function(_, frames, stock, parent)
        assert(not frames.ForeverUI_Companion and stock:IsVisible() and stock:GetParent() == parent)
    end)
end)
