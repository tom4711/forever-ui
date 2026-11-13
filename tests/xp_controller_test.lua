test("XP panel initializes from a live snapshot even before the world event",function()
    local saved={CreateFrame=CreateFrame,UnitLevel=UnitLevel,UnitXP=UnitXP,UnitXPMax=UnitXPMax,
        GetMaxPlayerLevel=GetMaxPlayerLevel,GetXPExhaustion=GetXPExhaustion,GetServerTime=GetServerTime,
        time=time,UIParent=UIParent,InCombatLockdown=InCombatLockdown}
    local frame={shown=false}
    function frame:SetShown(value)self.shown=value end
    function frame:SetScript(name,fn)self[name]=fn end
    function frame:RegisterEvent()end
    CreateFrame=function()return setmetatable({}, {__index={SetScript=function(self,name,fn)self[name]=fn end,
        RegisterEvent=function()end}})end
    UnitLevel=function()return 21 end;UnitXP=function()return 21 end;UnitXPMax=function()return 100 end
    GetMaxPlayerLevel=function()return 60 end;GetXPExhaustion=function()return 0 end;GetServerTime=function()return 100 end
    time=function()return 100 end;UIParent={};InCombatLockdown=function()return false end
    local ns={Read={Number=function(v)return type(v)=="number"and v or nil end,
        Boolean=function(v)return type(v)=="boolean"and v or nil end,
        Try=function(fn,...)local ok,v=pcall(fn,...);return ok,v end,
        Call=function(fn,...)if type(fn)=="function"then local ok,v=pcall(fn,...);if ok then return v end end end},
        }
    local modelNS={};loadAddon("Modules/XP/Model.lua",modelNS);ns.XPModel=modelNS.XPModel
    ns.QuestXP=modelNS.QuestXP;ns.L={};ns.db={xp={enabled=true,showAtCap=true,width=620}}
    ns.Preview={IsEnabled=function()return false end};ns.UI={Place=function()end}
    ns.XPView={Create=function()return {frame=frame,SetWidth=function()end,Render=function()end}end}
    ns.Format={Number=function(v)return tostring(v)end,Duration=function()return "0"end}
    loadAddon("Modules/XP/Controller.lua",ns)
    ns.XP.Init()
    CreateFrame=saved.CreateFrame;UnitLevel=saved.UnitLevel;UnitXP=saved.UnitXP;UnitXPMax=saved.UnitXPMax
    GetMaxPlayerLevel=saved.GetMaxPlayerLevel;GetXPExhaustion=saved.GetXPExhaustion;GetServerTime=saved.GetServerTime
    time=saved.time;UIParent=saved.UIParent;InCombatLockdown=saved.InCombatLockdown
    assert(frame.shown==true)
end)
