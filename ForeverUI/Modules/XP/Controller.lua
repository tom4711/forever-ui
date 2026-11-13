local _,ns=...
local R,M=ns.Read,ns.XPModel
ns.XP={}
local state,view,events,pending
local function number(fn,...)return R.Number(R.Call(fn,...))end
local function now()return number(GetServerTime)or number(time)end
local function snapshot()
    local level=number(UnitLevel,"player")
    local maximum=number(UnitXPMax,"player")
    local cap=number(GetMaxPlayerLevel)or number(C_PlayerInfo and C_PlayerInfo.GetMaxLevelForPlayerExpansion)
    local ok,rested=R.Try(GetXPExhaustion)
    if ok and rested==nil then rested=0 else rested=R.Number(rested)end
    return {level=level,current=number(UnitXP,"player"),maximum=maximum,rested=rested,at=now(),
        atCap=(level~=nil and cap~=nil and level>=cap)or (level~=nil and maximum==0)}
end
local function save()if state then ns.db.xpSession=state end end
local function render()
    if not view or not state then return end
    local summary=M.Summarize(state,now())
    view.Render(summary)
    view.frame:SetShown(ns.db.xp.enabled and not ns.Preview.IsEnabled() and (not summary.atCap or ns.db.xp.showAtCap))
end
local function sample()
    pending=false
    if not state then return end
    state=M.Observe(state,snapshot());save();render()
end
local function schedule()
    if pending then return end
    pending=true
    if C_Timer and C_Timer.After then C_Timer.After(0,sample)else sample()end
end
function ns.XP.Refresh()
    if not view then return end
    ns.UI.Place(view.frame,"xp");render()
end
function ns.XP.GetFrame()return view and view.frame end
function ns.XP.Init()
    view=ns.XPView.Create("ForeverUI_XP")
    events=CreateFrame("Frame")
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_XP_UPDATE","PLAYER_LEVEL_UP","UPDATE_EXHAUSTION","PLAYER_LOGOUT"})do events:RegisterEvent(event)end
    events:SetScript("OnEvent",function(_,event,initial,reloaded)
        if event=="PLAYER_ENTERING_WORLD"then
            local current=snapshot()
            if initial or reloaded or not state then state=M.Restore(ns.db.xpSession,current,reloaded==true)
            else state=M.Observe(state,current)end
            save();ns.XP.Refresh()
        elseif event=="PLAYER_LOGOUT"then sample();save()
        else schedule()end
    end)
    local elapsed=0
    events:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt
        if elapsed>=1 then elapsed=0;render()end
    end)
end
