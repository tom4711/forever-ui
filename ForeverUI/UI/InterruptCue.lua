local _, ns = ...
local UI, T, R = ns.UI, ns.Theme, ns.Read
local Cue = {}
ns.InterruptCue = Cue

local visible = {}
local castOutline, castLock, watching
local driver = CreateFrame("Frame")

local function secret(value)
    return issecretvalue and issecretvalue(value)
end

local function setOutline(outline, ready, locked)
    for _, texture in ipairs(outline) do
        if ready and secret(locked) then
            local setAlpha = texture.SetAlphaFromBoolean
            texture:SetShown(setAlpha and pcall(setAlpha, texture, locked, 0, 1) or false)
        else
            texture:SetAlpha(1)
            texture:SetShown(ready and locked == false)
        end
    end
end

local function spellUsable(id)
    local usable = R.Boolean(R.Call(C_Spell and C_Spell.IsSpellUsable, id))
    if usable ~= nil then return usable end
    return R.Boolean(R.Call(IsUsableSpell, id)) == true
end

local function cooldownReady(id)
    local cooldown = R.Call(C_Spell and C_Spell.GetSpellCooldown, id)
    if type(cooldown) == "table" then
        if R.Boolean(cooldown.isEnabled) == false then return false end
        local active = R.Boolean(cooldown.isActive)
        if active ~= nil then return not active end
        return R.Number(cooldown.duration) == 0
    end
    if not GetSpellCooldown then return false end
    local ok, _, duration, enabled = pcall(GetSpellCooldown, id)
    return ok and R.Boolean(enabled) ~= false and R.Number(enabled) ~= 0 and R.Number(duration) == 0
end

local function spellInRange(id)
    local range = R.Boolean(R.Call(C_Spell and C_Spell.IsSpellInRange, id, "target"))
    if range ~= nil then return range end
    local name = R.Call(C_Spell and C_Spell.GetSpellName, id) or R.Call(GetSpellInfo, id)
    local oldRange = type(name) == "string" and R.Call(IsSpellInRange, name, "target")
    return R.Boolean(oldRange) == true or R.Number(oldRange) == 1
end

local function refresh()
    local anyReady = false
    for _, state in pairs(visible) do
        local id = state.id
        local ready = watching and spellUsable(id) and cooldownReady(id) and spellInRange(id) or false
        setOutline(state.outline, ready, castLock)
        anyReady = anyReady or ready
    end
    if castOutline then setOutline(castOutline, anyReady, castLock) end
end

local elapsed = 0
local function onUpdate(_, delta)
    elapsed = elapsed + delta
    if elapsed < 0.1 then return end
    elapsed = 0
    refresh()
end

function Cue.Outline(frame)
    local outline = UI.ActionOutline(frame)
    for _, texture in ipairs(outline) do texture:SetVertexColor(unpack(T.goldLight)) end
    return outline
end

function Cue.SetCast(outline, locked)
    if castOutline and castOutline ~= outline then setOutline(castOutline, false) end
    castOutline, castLock = outline, locked
    watching = secret(locked) or locked == false
    elapsed = 0
    driver:SetScript("OnUpdate", watching and onUpdate or nil)
    refresh()
end

function Cue.Track(button, id)
    local state = {id = id, outline = Cue.Outline(button)}
    local function show(self) visible[self] = state end
    button:HookScript("OnShow", show)
    button:HookScript("OnHide", function(self)
        visible[self] = nil
        setOutline(state.outline, false)
    end)
    if button:IsVisible() then show(button) end
end
