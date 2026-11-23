local _,ns=...
ns.WarlockModel={}
local M=ns.WarlockModel
local summons={
    {key="imp",spellID=688},{key="voidwalker",spellID=697},{key="succubus",spellID=712},
    {key="felhunter",spellID=691},{key="felguard",spellID=30146},{key="infernal",spellID=1122},{key="doomguard",spellID=18540},
}
M.SummonSpells=summons
M.QuickSpells = {
    {key = "healthFunnel", unit = "pet", ranks = {755,3698,3699,3700,11693,11694,11695,11698,27259}},
    {key = "healthstone", ranks = {6201,6202,5699,11729,11730,27230}},
}

function M.QuickActions(known)
    local result = {}
    for _, action in ipairs(M.QuickSpells) do
        for index = #action.ranks, 1, -1 do
            local id = action.ranks[index]
            if known[id] then
                result[#result + 1] = {key = action.key, spellID = id, unit = action.unit}
                break
            end
        end
    end
    return result
end
function M.DemonState(exists,dead,name,health,maxHealth)
    if exists==false then return {state="missing"}end
    if exists~=true or type(dead)~="boolean"then return {state="unknown"}end
    if dead then return {state="dead",name=type(name)=="string"and name or nil}end
    local result={state="living",name=type(name)=="string"and name or nil}
    if type(health)=="number"and health>=0 and health==health then result.health=health end
    if type(maxHealth)=="number"and maxHealth>0 and maxHealth==maxHealth then result.maxHealth=maxHealth end
    return result
end
function M.SoulShards(count)
    if type(count)=="number"and count==count and count>=0 and count<math.huge and count==math.floor(count)then return count end
end
function M.SummonActions(known)
    known=type(known)=="table"and known or {}
    local result={}
    for _,entry in ipairs(summons)do if known[entry.spellID]==true then result[#result+1]={key=entry.key,spellID=entry.spellID}end end
    return result
end
return M
