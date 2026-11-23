local ns={}
loadAddon("Modules/Warlock/Model.lua",ns)
local function model()assert(ns.WarlockModel,"Warlock model is missing");return ns.WarlockModel end

test("demon status distinguishes missing dead living and unreadable states",function()
    assert(model().DemonState(false,false).state=="missing")
    assert(model().DemonState(true,true,"Imp").state=="dead")
    local living=model().DemonState(true,false,"Imp",50,100)
    assert(living.state=="living" and living.name=="Imp" and living.health==50 and living.maxHealth==100 and living.percent==nil)
    assert(model().DemonState(nil,nil).state=="unknown")
end)

test("soul shard count accepts readable zero and rejects unreadable or malformed counts",function()
    assert(model().SoulShards(0)==0 and model().SoulShards(3)==3)
    assert(model().SoulShards(nil)==nil and model().SoulShards(-1)==nil and model().SoulShards(1.5)==nil)
end)

test("warlock summon actions contain only learned demons in stable order",function()
    local actions=model().SummonActions({[688]=true,[697]=true,[691]=false,[30146]=true})
    assert(#actions==3)
    assert(actions[1].key=="imp" and actions[1].spellID==688)
    assert(actions[2].key=="voidwalker" and actions[2].spellID==697)
    assert(actions[3].key=="felguard" and actions[3].spellID==30146)
end)
