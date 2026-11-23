local _,ns=...
local R=ns.Read
ns.Player={}
local view,events
local buffs,debuffs
local replacementApplied=false
local stockAppearance

local function directValue(fn,...)
    if type(fn)~="function"then return nil end
    local ok,value=pcall(fn,...)
    if ok then return value end
end

local powerTokens = {[0] = "MANA", [1] = "RAGE", [2] = "FOCUS", [3] = "ENERGY"}

local function activePowerType()
    if type(UnitPowerType) ~= "function" then return nil end
    local ok, id, token = pcall(UnitPowerType, "player")
    if not ok then return nil end
    if not (issecretvalue and issecretvalue(token)) and type(token) == "string" and token ~= "" then
        return token
    end
    return powerTokens[R.Number(id)]
end

local function field(data,key)
    local ok,value=R.Try(function()return data[key]end)
    if ok then return value end
end

local function collectAuras(filter)
    local result = {}
    local api = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
    if type(api) ~= "function" then return result end
    for index = 1, 40 do
        local ok, aura = pcall(api, "player", index, filter)
        if not ok then break end
        local restricted = (issecretvalue and issecretvalue(aura)) or (issecrettable and issecrettable(aura))
        if not restricted and type(aura) ~= "table" then break end
        if not restricted then
            local spellID = R.Number(field(aura, "spellId") or field(aura, "spellID"))
            local auraInstanceID = R.Number(field(aura, "auraInstanceID"))
            local icon = field(aura, "icon")
            local name = field(aura, "name")
            if type(name) ~= "string" and spellID then
                name = R.Call(C_Spell and C_Spell.GetSpellName, spellID)
            end
            local description = spellID and R.Call(C_Spell and C_Spell.GetSpellDescription, spellID)
            local applications = R.Number(field(aura, "applications"))
            local dispellable = filter == "HARMFUL" and auraInstanceID ~= nil
                and R.Boolean(R.Call(C_UnitAuras.IsAuraFilteredOutByInstanceID,
                    "player", auraInstanceID, "HARMFUL|RAID")) == false
            local durationObject
            if auraInstanceID then
                durationObject = directValue(C_UnitAuras.GetAuraDuration, "player", auraInstanceID)
            end
            result[#result + 1] = {
                spellID = spellID,
                icon = (type(icon) == "number" or type(icon) == "string") and icon or nil,
                name = type(name) == "string" and name or nil,
                description = type(description) == "string" and description or nil,
                applications = applications,
                dispellable = dispellable,
                durationObject = durationObject,
                duration = R.Number(field(aura, "duration")),
                expirationTime = R.Number(field(aura, "expirationTime")),
                timeMod = R.Number(field(aura, "timeMod")),
            }
        end
    end
    return result
end

local function applyVisibility()
    local preview = ns.Preview and ns.Preview.IsEnabled and ns.Preview.IsEnabled()
    local enable = ns.db.player.enabled == true or preview == true
    if enable == replacementApplied or InCombatLockdown() then return end

    if enable then
        local stock = PlayerFrame
        if not stock or not stock.PlayerFrameContainer or not stock.PlayerFrameContent then return end
        local container, content = stock.PlayerFrameContainer, stock.PlayerFrameContent
        stockAppearance = {
            frame = stock,
            container = container, containerShown = container:IsShown(),
            content = content, contentShown = content:IsShown(),
            clicks = stock:IsMouseClickEnabled(), motion = stock:IsMouseMotionEnabled(),
        }

        -- The secure pet button and an attached cast bar need PlayerFrame to keep its native visibility.
        stock:SetMouseClickEnabled(false)
        stock:SetMouseMotionEnabled(false)
        container:Hide()
        content:Hide()
    else
        local previous = stockAppearance
        previous.container:SetShown(previous.containerShown)
        previous.content:SetShown(previous.contentShown)
        previous.frame:SetMouseClickEnabled(previous.clicks)
        previous.frame:SetMouseMotionEnabled(previous.motion)
        stockAppearance = nil
    end
    replacementApplied = enable
end

function ns.Player.SetReplacementEnabled(enabled)
    if not ns.db or not ns.db.player then return false end
    ns.db.player.enabled=enabled==true
    ns.Player.Refresh()
    return true
end

function ns.Player.Refresh()
    if not view or not ns.db or not ns.db.player then return end
    applyVisibility()
    local name=R.Call(UnitName,"player")
    local level=R.Number(R.Call(UnitLevel,"player"))
    local preview=ns.Preview and ns.Preview.IsEnabled and ns.Preview.IsEnabled()
    if replacementApplied and not preview then
        if not view.nativeBuffs and not buffs then buffs = collectAuras("HELPFUL") end
        if not view.nativeDebuffs and not debuffs then debuffs = collectAuras("HARMFUL") end
    end
    local data={visible=replacementApplied and not preview,
        name=type(name)=="string"and name or nil,level=level,portrait="player",
        resting=R.Boolean(R.Call(IsResting))==true,
        health=directValue(UnitHealth,"player"),maxHealth=directValue(UnitHealthMax,"player"),
        powerType=activePowerType(),power=directValue(UnitPower,"player"),maxPower=directValue(UnitPowerMax,"player"),
        buffs=buffs,debuffs=debuffs}
    view.Render(data)
    if not view.frame.dragging then ns.UI.Place(view.frame,"player") end
end

local function refreshMoney()
    view.RenderMoney(R.Number(R.Call(GetMoney)))
end

function ns.Player.Init()
    if view then return end
    view=ns.PlayerView.Create("ForeverUI_Player")
    events=CreateFrame("Frame")
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_LEVEL_UP","PLAYER_UPDATE_RESTING","PLAYER_MONEY","UNIT_HEALTH","UNIT_MAXHEALTH",
        "UNIT_POWER_UPDATE","UNIT_MAXPOWER","UNIT_DISPLAYPOWER","UNIT_AURA","SPELLS_CHANGED","PLAYER_REGEN_ENABLED"})do
        events:RegisterEvent(event)
    end
    if view.nativeBuffs and view.nativeDebuffs then events:UnregisterEvent("UNIT_AURA") end
    events:SetScript("OnEvent",function(_,event,unit)
        if event=="PLAYER_MONEY" then
            refreshMoney()
            return
        end
        if event=="PLAYER_ENTERING_WORLD" then refreshMoney() end
        if (event=="UNIT_HEALTH"or event=="UNIT_MAXHEALTH"or event=="UNIT_POWER_UPDATE"or
            event=="UNIT_MAXPOWER"or event=="UNIT_DISPLAYPOWER"or event=="UNIT_AURA")and unit~="player"then
            return
        end
        if event=="UNIT_AURA" or event=="PLAYER_ENTERING_WORLD" or event=="PLAYER_REGEN_ENABLED" then
            buffs,debuffs=nil,nil
        elseif event=="SPELLS_CHANGED" then
            debuffs=nil
            view.RefreshDispels()
        end
        ns.Player.Refresh()
    end)
    refreshMoney()
    ns.Player.Refresh()
end
