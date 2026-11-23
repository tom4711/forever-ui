local _,ns=...
ns.PriestModel={}
local M=ns.PriestModel
local fortitudeRanks = {1243, 1244, 1245, 2791, 10937, 10938, 25389}
local fortitudeAuras = {[21562] = true, [21564] = true}
for _, id in ipairs(fortitudeRanks) do fortitudeAuras[id] = true end

function M.IsFortitudeAura(spellID)
    return fortitudeAuras[spellID] == true
end

local actions={
    {key="fortitude",group="buffs",spells=fortitudeRanks},
    {key="shadowProtection",group="buffs",spells={976,10957,10958},friendly=true},
    {key="divineSpirit",group="buffs",spells={14752,14818,14819,27841,25312},friendly=true},
    {key="innerFire",group="buffs",spells={588,7128,602,1006,10951,10952,48168}},
    {key="shadowform",group="buffs",spells={15473}},
    {key="shield",group="support",spells={17,592,600,3747,6065,6066,10898,10899,10900,10901,25217,25218}},
    {key="renew",group="support",spells={139,6074,6075,6076,6077,6078,10927,10928,10929,25221,25222}},
    {key="dispelMagic",group="support",spells={527,988}},
    {key="cureDisease",group="support",spells={528}},
    {key="resurrection",group="support",spells={2006,2010,10880,10881,20770}},
    {key="silence",group="support",spells={15487},interrupt=true},
}
M.SpellActions=actions
function M.Actions(known)
    known=type(known)=="table"and known or{}
    local result={buffs={},support={},macros={}}
    for _,entry in ipairs(actions)do
        local ranks={}
        for _,spellID in ipairs(entry.spells)do if known[spellID]==true then ranks[#ranks+1]=spellID end end
        if #ranks>0 then
            local spellID = ranks[#ranks]
            result[entry.group][#result[entry.group]+1]={key=entry.key,spellID=spellID,ranks=ranks,interrupt=entry.interrupt}
            if entry.key == "fortitude" or entry.friendly then
                result.macros[#result.macros + 1] = {key = entry.key .. "Nearby", spellID = spellID, mode = "nearby"}
            end
            if entry.key == "fortitude" or entry.key == "shield" or entry.key == "renew" then
                result.macros[#result.macros + 1] = {key = entry.key .. "Self", spellID = spellID, mode = "self"}
            end
            if entry.key == "shield" or entry.key == "renew" then
                result.macros[#result.macros + 1] = {key = entry.key .. "Mouseover", spellID = spellID, mode = "mouseover"}
            end
        end
    end
    return result
end
function M.ActiveBuffs(buffActions,query)
    local result={}
    if type(buffActions)~="table"or type(query)~="function"then return result end
    for _,action in ipairs(buffActions)do
        local active,unknown=false,false
        for _,spellID in ipairs(action.ranks or{action.spellID})do
            local ok,value=pcall(query,spellID)
            if ok and value==true then active=true;break end
            if not ok or type(value)~="boolean"then unknown=true end
        end
        result[action.key]=active and"active"or unknown and"unknown"or"inactive"
    end
    return result
end
return M
