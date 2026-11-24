local _,ns=...
ns.PaladinModel={}
local M=ns.PaladinModel
local groups={
    {key="devotion",kind="aura",spells={465,10290,643,10291,1032,10292,10293,27149,48941,48942}},
    {key="retribution",kind="aura",spells={7294,10298,10299,10300,10301,27150,54043,54044}},
    {key="concentration",kind="aura",spells={19746,19952,19953,27153,27154}},
    {key="fireResistance",kind="aura",spells={19891,19899,19900}},
    {key="frostResistance",kind="aura",spells={19888,19897,19898}},
    {key="shadowResistance",kind="aura",spells={19876,19895,19896}},
    {key="might",kind="blessing",spells={19740,19834,19835,19836,19837,19838,25291,27140,48931,48932}},
    {key="wisdom",kind="blessing",spells={19742,19850,19852,19853,19854,25290,27142,48935,48936}},
    {key="kings",kind="blessing",spells={20217}},
    {key="greaterMight",kind="blessing",spells={25782,25916}},
    {key="greaterWisdom",kind="blessing",spells={25894,25918}},
    {key="greaterKings",kind="blessing",spells={25898}},
    {key="salvation",kind="blessing",spells={1038}},
    {key="protection",kind="blessing",spells={1022,5599,10278}},
    {key="freedom",kind="blessing",spells={1044}},
    {key="sacrifice",kind="blessing",spells={6940,20729,27147,27148}},
}
M.SpellGroups=groups
function M.Actions(known)
    known=type(known)=="table" and known or {}
    local result={}
    for _,group in ipairs(groups)do
        local ranks={}
        for _,id in ipairs(group.spells)do if known[id]==true then ranks[#ranks+1]=id end end
        if #ranks>0 then result[#result+1]={key=group.key,kind=group.kind,spellID=ranks[#ranks],ranks=ranks}end
    end
    return result
end
function M.QuickActions(actions)
    local result = {}
    for _, action in ipairs(actions) do
        if action.key == "protection" or action.key == "freedom" then
            result[#result + 1] = action
        end
    end
    return result
end
function M.ActiveAura(actions,query)
    if type(actions)~="table" or type(query)~="function" then return "unknown" end
    local unknown=false
    for _,action in ipairs(actions)do
        if action.kind=="aura" then
            for _,id in ipairs(action.ranks or {action.spellID})do
                local ok,value=pcall(query,id)
                if ok and value==true then return action.key end
                if not ok or type(value)~="boolean" then unknown=true end
            end
        end
    end
    return unknown and "unknown" or nil
end
function M.EquipmentMacro(shieldName,twoHandName)
    local function safe(name)
        return type(name)=="string" and #name>0 and #name<=80 and not name:find("[%c;%[%]]")
    end
    if not safe(shieldName) or not safe(twoHandName) then return nil end
    return "/equipset [equipped:shield] "..twoHandName.."; "..shieldName
end
M.JudgementSpellID = 20271
M.SealIDs = {21084, 21082, 1311649, 20375, 20164, 20165, 20166}

function M.SelectSeal(seals, preferred)
    for _, seal in ipairs(seals) do
        if seal.id == preferred then return seal end
    end
    return seals[1]
end

local function safeSpellName(name)
    return type(name) == "string" and #name > 0 and #name <= 100 and not name:find("[%c;%[%]]")
end

function M.JudgementMacros(judgementName, sealName)
    if not safeSpellName(judgementName) then return end
    local judgement = "/startattack [harm,nodead]\n/cast [harm,nodead] " .. judgementName
    local seal = safeSpellName(sealName) and "/cast [@player] " .. sealName or nil
    return judgement, seal
end
return M
