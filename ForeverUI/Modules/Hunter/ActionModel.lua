local _,ns=...
ns.HunterActionModel={}
local M=ns.HunterActionModel
local groups={
    {key="monkey",spells={13163}},
    {key="hawk",spells={13165,14318,14319,14320,14321,14322}},
    {key="cheetah",spells={5118}},
    {key="pack",spells={13159}},
    {key="wild",spells={20043,20190}},
    {key="viper",spells={34074}},
}
M.SpellIDs=groups
function M.Aspects(known)
    local result={}
    for _,group in ipairs(groups)do
        local spellID
        for _,candidate in ipairs(group.spells)do
            if known[candidate]==true then spellID=candidate end
        end
        if spellID then result[#result+1]={key=group.key,spellID=spellID}end
    end
    return result
end
function M.HighestKnown(spells,known)
    local result
    for _,id in ipairs(spells)do if known[id]==true then result=id end end
    return result
end
function M.PetMacro(action,localizedName)
    if type(localizedName)~="string" or localizedName=="" then return nil end
    if action=="mend" then return "/cast [@pet,exists,nodead] "..localizedName end
    if action=="revive" then return "/cast [@pet,dead] "..localizedName end
end
function M.PetAvailability(exists,dead)
    return {mend=exists==true and dead==false,revive=exists==true and dead==true}
end
M.PetSpells={mend={136,3111,3661,3662,13542,13543,13544},revive={982}}
