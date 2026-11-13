local ns={}
loadAddon("Modules/XP/Model.lua",ns)
local function quests()assert(ns.QuestXP,"Quest XP collection is not implemented");return ns.QuestXP end

test("only finished unrewarded quests contribute to the preview",function()
    local total=quests().Total({{id=10,complete=true,rewardXP=100},{id=11,complete=false,rewardXP=999},{id=12,complete=true,rewardXP=200}},true)
    assert(total==300)
end)

test("duplicate quest IDs are not counted twice",function()
    assert(quests().Total({{id=10,complete=true,rewardXP=100},{id=10,complete=true,rewardXP=100}},true)==100)
end)

test("unavailable reward or completion data stays unknown",function()
    assert(quests().Total({{id=10,complete=true}},true)==nil)
    assert(quests().Total({{id=10,rewardXP=100}},true)==nil)
    assert(quests().Total({},false)==nil)
    assert(quests().Total({},true)==0)
end)

test("zero-XP completed quests are valid while turned-in quests are excluded",function()
    assert(quests().Total({{id=10,complete=true,rewardXP=0},{id=11,complete=true,rewardXP=200,ignored=true}},true)==0)
end)

test("quest collector uses quest IDs rather than log indexes and skips headers",function()
    local entries={{isHeader=true},{questID=101,isHeader=false},{questID=102,isHeader=false}}
    local rewards={[101]=100,[102]=200}
    local provider={Count=function()return 3,2 end,Info=function(i)return entries[i]end,
        Complete=function(id)return rewards[id]~=nil end,Reward=function(id)return rewards[id]end}
    assert(quests().Collect(provider,{})==300)
    assert(quests().Collect(provider,{[101]=true})==200)
end)

test("a log changing during collection is not reported as a smaller known total",function()
    local provider={Count=function()return 2,2 end,Info=function(i)if i==1 then return {questID=101}end end,
        Complete=function()return true end,Reward=function()return 100 end}
    assert(quests().Collect(provider,{})==nil)
end)
