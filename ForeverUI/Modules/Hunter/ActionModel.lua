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
        local spellID,ranks
        for _,candidate in ipairs(group.spells)do
            if known[candidate]==true then
                spellID=candidate
                ranks=ranks or {}
                ranks[#ranks+1]=candidate
            end
        end
        if spellID then result[#result+1]={key=group.key,spellID=spellID,ranks=ranks}end
    end
    return result
end
function M.ActiveAspect(aspects,auraState)
    if type(aspects)~="table" then return "unknown" end
    auraState=type(auraState)=="table" and auraState or {}
    local unknown=false
    for _,aspect in ipairs(aspects)do
        for _,group in ipairs(groups)do
            if group.key==aspect.key then
                for _,spellID in ipairs(aspect.ranks or {aspect.spellID})do
                    local active=auraState[spellID]
                    if active==true then return aspect.key end
                    if active==nil then unknown=true end
                end
            end
        end
    end
    return unknown and "unknown" or nil
end
function M.QueryActiveAspect(aspects,query)
    local auraState={}
    if type(aspects)~="table" or type(query)~="function" then return "unknown" end
    for _,aspect in ipairs(aspects)do
        for _,spellID in ipairs(aspect.ranks or {aspect.spellID})do
            local ok,active=pcall(query,spellID)
            if ok and type(active)=="boolean" then auraState[spellID]=active end
        end
    end
    return M.ActiveAspect(aspects,auraState)
end
function M.HighestKnown(spells,known)
    local result
    for _,id in ipairs(spells)do if known[id]==true then result=id end end
    return result
end
function M.Slots(aspectCount,petActions)
    local slots={}
    for index=1,aspectCount do slots["aspect"..index]=index-1 end
    local nextIndex=aspectCount
    for _,key in ipairs(petActions)do slots[key]=nextIndex;nextIndex=nextIndex+1 end
    return slots
end
function M.Toolbar(actionCount)
    local result={actions={},feed=16+actionCount*38+8}
    for index=1,actionCount do result.actions[index]=16+(index-1)*38 end
    result.food=result.feed+44
    result.settings=result.food+44
    return result
end
function M.GroupLayout(aspectCount,petActionCount,aspectPosition,petPosition)
    aspectCount=math.max(0,math.floor(aspectCount or 0))
    petActionCount=math.max(0,math.floor(petActionCount or 0))
    aspectPosition=type(aspectPosition)=="table" and aspectPosition or {}
    petPosition=type(petPosition)=="table" and petPosition or {}
    local result={
        aspects={x=aspectPosition.x or 16,y=aspectPosition.y or -108,actions={},width=0},
        pet={x=petPosition.x or 280,y=petPosition.y or -108,actions={},feed=24,food=68,width=114},
        settings=484,
    }
    for index=1,aspectCount do result.aspects.actions[index]=24+(index-1)*38 end
    if aspectCount>0 then result.aspects.width=66+(aspectCount-1)*38 end
    for index=1,petActionCount do result.pet.actions[index]=24+(index-1)*38 end
    if petActionCount>0 then result.pet.feed=24+32+(petActionCount-1)*38+8 end
    result.pet.food=result.pet.feed+44
    result.pet.width=result.pet.food+46
    return result
end
function M.GroupOffset(left,top,rootLeft,rootTop)
    if type(left)~="number" or type(top)~="number" or type(rootLeft)~="number" or type(rootTop)~="number" then return nil end
    return {x=left-rootLeft,y=top-rootTop}
end
function M.Position(geometry,offset)
    local feed=ns.FoodModel.FeedPosition(geometry,offset)
    if not feed then return nil end
    return {x=feed.x,y=feed.y,scale=geometry.scale/geometry.parentScale}
end
function M.PetMacro(action,localizedName)
    if type(localizedName)~="string" or localizedName=="" then return nil end
    if action=="mend" then return "/cast [@pet,exists,nodead] "..localizedName end
    if action == "markAttack" then
        return "/petattack [@target,harm,nodead,pet]\n/cast [@target,harm,nodead] " .. localizedName
    end
end
function M.PetAction(action,spellID,localizedName)
    if (action=="revive" or action=="call" or action=="dismiss") and type(spellID)=="number" then return {type="spell",spell=spellID} end
    if action=="mend" or action=="markAttack" then
        local macro=M.PetMacro(action,localizedName)
        if macro then return {type="macro",macrotext=macro} end
    end
end
function M.PetAvailability(exists,dead)
    return {mend=exists==true and dead==false,revive=exists==true and dead==true}
end
M.SpellEvents={"SPELLS_CHANGED","LEARNED_SPELL_IN_SKILL_LINE"}
M.ClickEvents={"LeftButtonDown","LeftButtonUp"}
M.PetActionOrder={"mend","revive","call","dismiss","markAttack"}
M.PetSpells={mend={136,3111,3661,3662,13542,13543,13544},revive={982},call={883},dismiss={2641},markAttack={1130,14323,14324,14325}}
