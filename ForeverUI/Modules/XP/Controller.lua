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
local sessionReady=false
local questXP
local ignoredQuests={}
local flight={active=false,startedAt=nil,route=nil,routeLength=nil,recordable=false}
local pendingFlight
local function number(fn,...)return R.Number(R.Call(fn,...))end
local function now()return number(GetServerTime)or number(time)end
local function flightNow()return number(GetTime)end
local function taxiState()return R.Boolean(R.Call(UnitOnTaxi,"player"))end
local function taxiNodeName(index)return R.Call(TaxiNodeName,index)end
local function currentTaxiOrigin()
    local count=number(NumTaxiNodes)
    if count and count>0 and count<=500 then
        for i=1,count do
            if R.Call(TaxiNodeGetType,i)=="CURRENT"then
                local name=taxiNodeName(i)
                if type(name)=="string"and name~=""then return name end
            end
        end
    end
    return R.Call(GetMinimapZoneText)
end
local function taxiRouteLength(index)
    local hops=number(GetNumRoutes,index)
    if not hops or hops<1 or hops>30 then return nil end
    local total=0
    for hop=1,hops do
        local from=number(TaxiGetNodeSlot,index,hop,true)
        local to=number(TaxiGetNodeSlot,index,hop,false)
        if not from or not to then return nil end
        local ok1,x1,y1=pcall(TaxiNodePosition,from);local ok2,x2,y2=pcall(TaxiNodePosition,to)
        if not ok1 then x1,y1=nil,nil end;if not ok2 then x2,y2=nil,nil end
        x1,y1,x2,y2=R.Number(x1),R.Number(y1),R.Number(x2),R.Number(y2)
        if not x1 or not y1 or not x2 or not y2 then return nil end
        local dx=(x2-x1)*1.5;local dy=y2-y1
        total=total+math.sqrt(dx*dx+dy*dy)
    end
    if total<=0 or total>10 then return nil end
    return total
end
local function captureTaxiSelection(index)
    local origin=currentTaxiOrigin();local destination=taxiNodeName(index)
    local key=origin and destination and M.FlightRouteKey(origin,destination)
    pendingFlight={route=key,routeLength=taxiRouteLength(index),recordable=key~=nil}
end
local function invalidateFlightLearning()
    if flight.active then flight.recordable=false end
    if pendingFlight then pendingFlight.recordable=false end
end
local function syncFlight()
    local active=taxiState()
    if active==nil then
        invalidateFlightLearning()
        return
    end
    if active and not flight.active then
        local start=flightNow()
        local routeData=pendingFlight
        flight={active=true,startedAt=start,route=routeData and routeData.route or nil,
            routeLength=routeData and routeData.routeLength or nil,
            recordable=routeData~=nil and routeData.recordable==true and routeData.route~=nil}
        pendingFlight=nil
    elseif not active and flight.active then
        local ended=flightNow()
        local duration=ended and flight.startedAt and ended-flight.startedAt
        if flight.recordable and duration and ns.db.xp.flight then
            M.RecordFlight(ns.db.xp.flight,flight.route,duration,flight.routeLength)
        end
        flight={active=false,startedAt=nil,route=nil,routeLength=nil,recordable=false}
    end
end
function ns.XP.FlightSnapshot()
    syncFlight()
    if not flight.active then return {active=false}end
    local current=flightNow()
    local elapsed=current and flight.startedAt and math.max(0,current-flight.startedAt)or nil
    local saved=ns.db.xp.flight or {}
    local routeSeconds=flight.route and saved.routes and saved.routes[flight.route]
    local estimate=M.FlightEstimate(routeSeconds,flight.routeLength,saved.secondsPerUnit)
    return {active=true,elapsed=elapsed,route=flight.route,estimate=estimate,
        progress=M.FlightProgress(elapsed,estimate),estimateIsApproximate=not (routeSeconds and routeSeconds>=5 and routeSeconds<=3600)}
end
function ns.XP.CaptureTaxiSelection(index)captureTaxiSelection(index)end
local function snapshot()
    local level=number(UnitLevel,"player")
    local maximum=number(UnitXPMax,"player")
    local cap=number(GetMaxPlayerLevel)or number(C_PlayerInfo and C_PlayerInfo.GetMaxLevelForPlayerExpansion)
    local ok,rested=R.Try(GetXPExhaustion)
    if ok and rested==nil then rested=0 else rested=R.Number(rested)end
    return {level=level,current=number(UnitXP,"player"),maximum=maximum,rested=rested,at=now(),
        atCap=(level~=nil and cap~=nil and level>=cap)or (level~=nil and maximum==0)}
end
local function save()
    if sessionReady then ns.db.xpSession=state end
end
local nativeSlots = {}
local hideNativeXP = false

local function maskRegion(regions, region)
    if not region then return end
    local alpha = R.Number(region:GetAlpha())
    local hasMouse = region.IsMouseEnabled and R.Boolean(region:IsMouseEnabled())
    if not hasMouse and (alpha == nil or alpha == 0) then return end

    -- A redraw can restore the native properties after the first mask.
    local original = regions[region] or {}
    regions[region] = original
    if alpha and alpha ~= 0 then
        original.alpha = alpha
        region:SetAlpha(0)
    end
    if hasMouse then
        original.hadMouse = true
        region:EnableMouse(false)
    end
end

local function restoreRegions(regions)
    for region, original in pairs(regions) do
        if original.alpha and R.Number(region:GetAlpha()) == 0 then
            region:SetAlpha(original.alpha)
        end
        if original.hadMouse then region:EnableMouse(true) end
        regions[region] = nil
    end
end

local function updateNativeSlot(container, experience)
    local regions = nativeSlots[container]
    local xpBar = container.bars and container.bars[experience]
    if not hideNativeXP or not xpBar or container.shownBarIndex ~= experience then
        restoreRegions(regions)
        return
    end

    -- Keep the container's own visibility and alpha under Blizzard's animation control.
    maskRegion(regions, xpBar)
    maskRegion(regions, xpBar.ExhaustionTick)
    maskRegion(regions, container.BarFrameTexture)
    local dividers = container.HorizontalDividersPool
    if dividers then
        for divider in dividers:EnumerateActive() do maskRegion(regions, divider) end
    end
end

local function syncNativeXP(visible)
    hideNativeXP = visible
    if not visible then
        for _, regions in pairs(nativeSlots) do restoreRegions(regions) end
        return
    end

    local manager = StatusTrackingBarManager
    local kinds = StatusTrackingBarInfo and StatusTrackingBarInfo.BarsEnum
    local experience = kinds and kinds.Experience
    if not manager or not manager.barContainers or not experience then return end

    for _, container in ipairs(manager.barContainers) do
        if not nativeSlots[container] then
            nativeSlots[container] = {}
            local function update() updateNativeSlot(container, experience) end
            hooksecurefunc(container, "ApplyPendingBarToShow", update)
            hooksecurefunc(container, "UpdateDividers", update)
        end
        updateNativeSlot(container, experience)
    end
end

function ns.XP.GetSummary()
    if state then return M.Summarize(state,now()) end
end

local function render()
    if not view or not state then return end
    local summary=ns.XP.GetSummary()
    summary.questXP=questXP
    summary.flight=ns.XP.FlightSnapshot()
    view.Render(summary)
    local visible = ns.db.xp.enabled and not ns.Preview.IsEnabled() and (not summary.atCap or ns.db.xp.showAtCap)
    view.frame:SetShown(visible)
    syncNativeXP(visible)
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
    ns.db.xp.flight=ns.db.xp.flight or {routes={},secondsPerUnit=650,importedForeverXPBar=false}
    if type(ForeverXPBarDB)=="table"then M.ImportFlightData(ns.db.xp.flight,ForeverXPBarDB)end
    if type(hooksecurefunc)=="function"then
        if type(TakeTaxiNode)=="function"then pcall(hooksecurefunc,"TakeTaxiNode",captureTaxiSelection)end
        if type(TaxiRequestEarlyLanding)=="function"then
            pcall(hooksecurefunc,"TaxiRequestEarlyLanding",invalidateFlightLearning)
        end
    end
    view=ns.XPView.Create("ForeverUI_XP")
    -- Render live XP immediately, then use the world entry flags to resolve the saved session.
    sessionReady=false
    state=M.New(snapshot())
    if taxiState()==true then flight={active=true,startedAt=flightNow(),route=nil,routeLength=nil,recordable=false}end
    ns.XP.Refresh()
    events=CreateFrame("Frame")
    for _,event in ipairs({"PLAYER_ENTERING_WORLD","PLAYER_XP_UPDATE","PLAYER_LEVEL_UP","UPDATE_EXHAUSTION","PLAYER_LOGOUT","QUEST_LOG_UPDATE","QUEST_TURNED_IN","QUEST_REMOVED","QUEST_ACCEPTED","QUEST_DATA_LOAD_RESULT"})do events:RegisterEvent(event)end
    events:SetScript("OnEvent",function(_,event,initial,reloaded)
        if event=="PLAYER_ENTERING_WORLD"then
            local current=snapshot()
            if not sessionReady or initial or reloaded then state=M.Restore(ns.db.xpSession,current,reloaded==true)
            else state=M.Observe(state,current)end
            sessionReady=true
            save();ns.XP.Refresh();scheduleQuests()
        elseif event=="PLAYER_LOGOUT"then sample()
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
        if elapsed>=1 then elapsed=0;syncFlight();render()end
    end)
end
