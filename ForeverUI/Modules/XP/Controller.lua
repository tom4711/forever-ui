local _,ns=...
local R,M=ns.Read,ns.XPModel
local Q=ns.QuestXP
local requested={}
function Q.Read(ignored)
    local R=ns.Read
    if not C_QuestLog or type(C_QuestLog.GetNumQuestLogEntries)~="function"then return nil end
    local provider={}
    function provider.Count()
        local ok,count,expected=pcall(C_QuestLog.GetNumQuestLogEntries)
        if not ok then return nil,nil end
        return R.Number(count),R.Number(expected)
    end
    function provider.Info(index)
        local info=R.Call(C_QuestLog.GetInfo,index)
        if type(info)~="table"then return nil end
        return {questID=R.Number(info.questID),isHeader=R.Boolean(info.isHeader)}
    end
    function provider.Complete(id)return R.Boolean(R.Call(C_QuestLog.IsComplete,id))end
    function provider.Reward(id)
        local reward=R.Number(R.Call(C_QuestLog.GetQuestLogRewardXP or GetQuestLogRewardXP,id))
        if reward==nil and not requested[id]and C_QuestLog.RequestLoadQuestByID then
            requested[id]=true;R.Call(C_QuestLog.RequestLoadQuestByID,id)
        end
        return reward
    end
    return Q.Collect(provider,ignored)
end

ns.XP={}
local state,view,events,pending,pendingQuests
local questXP
local ignoredQuests={}
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
    summary.questXP=questXP
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
local function scheduleQuests()
    if pendingQuests then return end
    pendingQuests=true
    local function collect()
        pendingQuests=false;questXP=ns.QuestXP.Read(ignoredQuests);render()
    end
    if C_Timer and C_Timer.After then C_Timer.After(0,collect)else collect()end
end
function ns.XP.Refresh()
    if not view then return end
    view.SetWidth(ns.db.xp.width)
    ns.UI.Place(view.frame,"xp");render()
end
function ns.XP.GetFrame()return view and view.frame end
function ns.XP.Init()
    view=ns.XPView.Create("ForeverUI_XP")
    events=CreateFrame("Frame")
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_XP_UPDATE","PLAYER_LEVEL_UP","UPDATE_EXHAUSTION","PLAYER_LOGOUT","QUEST_LOG_UPDATE","QUEST_TURNED_IN","QUEST_REMOVED","QUEST_ACCEPTED","QUEST_DATA_LOAD_RESULT"})do events:RegisterEvent(event)end
    events:SetScript("OnEvent",function(_,event,initial,reloaded)
        if event=="PLAYER_ENTERING_WORLD"then
            local current=snapshot()
            if initial or reloaded or not state then state=M.Restore(ns.db.xpSession,current,reloaded==true)
            else state=M.Observe(state,current)end
            save();ns.XP.Refresh();scheduleQuests()
        elseif event=="PLAYER_LOGOUT"then sample();save()
        elseif event=="QUEST_TURNED_IN"or event=="QUEST_REMOVED"then
            local id=R.Number(initial)
            if id then ignoredQuests[id]=true end
            scheduleQuests()
        elseif event=="QUEST_ACCEPTED"then
            local id=R.Number(initial)
            if id then ignoredQuests[id]=nil end
            scheduleQuests()
        elseif event=="QUEST_LOG_UPDATE"or event=="QUEST_DATA_LOAD_RESULT"then scheduleQuests()
        else schedule();if event=="PLAYER_LEVEL_UP"then scheduleQuests()end end
    end)
    local elapsed=0
    events:SetScript("OnUpdate",function(_,dt)
        elapsed=elapsed+dt
        if elapsed>=1 then elapsed=0;render()end
    end)
end
