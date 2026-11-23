local _, ns = ...
local B = {}
ns.FriendlyBuffs = B

local function safeSpellName(name)
    return type(name) == "string" and name ~= "" and not name:find("[%c;%[%]]")
end

function B.MouseoverMacro(name)
    if safeSpellName(name) then return "/cast [@mouseover,help,nodead] " .. name end
end

function B.Macro(name)
    if not safeSpellName(name) then return nil end
    return "/targetfriendplayer [@mouseover,noexists][@mouseover,nohelp][@mouseover,dead]\n"
        .. "/cast [@mouseover,help,nodead][@target,help,nodead] " .. name
end

function B.Entry(bindingID, spellID, preview)
    local read = ns.Read.Call
    local name = read(C_Spell and C_Spell.GetSpellName, spellID)
    if not name then
        local info = read(C_Spell and C_Spell.GetSpellInfo, spellID)
        name = type(info) == "table" and info.name or read(GetSpellInfo, spellID)
    end
    local macro = B.Macro(name)
    if not preview and not macro then return nil end
    return {key = bindingID, bindingID = bindingID, spellID = spellID, macro = macro}
end
