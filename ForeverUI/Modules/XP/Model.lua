local _,ns=...
ns.XPModel={}
local M=ns.XPModel
local function finite(x)return type(x)=="number" and x==x and x~=math.huge and x~=-math.huge end
local function copy(s)
    s=type(s)=="table" and s or {}
    return {level=s.level,current=s.current,maximum=s.maximum,rested=s.rested,at=s.at,atCap=s.atCap==true}
end
local function valid(s)
    if type(s)~="table"or not finite(s.level)or s.level<1 or not finite(s.at)then return false end
    if s.atCap==true then return true end
    return finite(s.current) and finite(s.maximum) and s.maximum>0 and s.current>=0 and s.current<=s.maximum
end
local RECENT_SECONDS=30*60
local MIN_RECENT_SECONDS=60

local function newRecent(at)
    return {startedAt=math.floor(at),samples={}}
end

function M.LoadRecent(value)
    if type(value)~="table" or not finite(value.startedAt) or value.startedAt~=math.floor(value.startedAt)
        or type(value.samples)~="table" or #value.samples>RECENT_SECONDS then return nil end

    local recent=newRecent(value.startedAt)
    local previousAt,total=nil,0
    for index=1,#value.samples do
        local sample=value.samples[index]
        if type(sample)~="table" or not finite(sample.at) or sample.at~=math.floor(sample.at)
            or sample.at<recent.startedAt or (previousAt and sample.at<=previousAt)
            or not finite(sample.xp) or sample.xp<=0 then return nil end
        previousAt=sample.at
        total=total+sample.xp
        if not finite(total) then return nil end
        recent.samples[index]={at=sample.at,xp=sample.xp}
    end
    return recent,total
end

local function recordRecent(recent,at,delta)
    -- The session clock has second resolution. Coalesce gains in the same second.
    at=math.floor(at)
    local samples=recent.samples
    local first=1
    while samples[first] and samples[first].at<=at-RECENT_SECONDS do first=first+1 end
    if first>1 then
        local retained={}
        for index=first,#samples do retained[#retained+1]=samples[index] end
        recent.samples=retained
        samples=retained
    end
    if delta<=0 then return end
    local last=samples[#samples]
    if last and last.at==at then
        last.xp=last.xp+delta
    else
        samples[#samples+1]={at=at,xp=delta}
    end
end

function M.New(snapshot,startedAt)
    snapshot=copy(snapshot)
    local start=finite(startedAt) and startedAt or snapshot.at
    local reliable=valid(snapshot)
    return {version=1,startedAt=start,earned=0,last=snapshot,reliable=reliable,measurementReset=false,
        recent=reliable and newRecent(snapshot.at) or nil}
end
local function reset(state,snapshot)
    state.startedAt=snapshot.at;state.earned=0;state.last=copy(snapshot)
    state.reliable=true;state.measurementReset=true
    state.recent=newRecent(snapshot.at)
    return state
end
function M.Observe(state,snapshot)
    snapshot=copy(snapshot)
    if not valid(snapshot)then
        state.last=snapshot;state.reliable=false;state.recent=nil
        return state
    end
    local previous=state.last
    if not state.reliable or not valid(previous) or snapshot.at<previous.at then return reset(state,snapshot)end
    local delta
    if snapshot.level==previous.level then
        if snapshot.atCap and previous.atCap then delta=0
        elseif finite(snapshot.current) and finite(previous.current)then delta=snapshot.current-previous.current end
    elseif snapshot.level==previous.level+1 and finite(previous.maximum) and finite(previous.current) and finite(snapshot.current) then
        delta=previous.maximum-previous.current+snapshot.current
    end
    if not finite(delta)or delta<0 then return reset(state,snapshot)end
    state.earned=state.earned+delta;state.last=snapshot;state.reliable=true
    if state.recent then
        recordRecent(state.recent,snapshot.at,delta)
    else
        -- Older sessions have no reliable rolling history before this observation.
        state.recent=newRecent(snapshot.at)
    end
    return state
end

local function summarizeRecent(state,now,result)
    local recent=state.recent
    if not recent or not finite(now) or now<state.last.at then return end
    local at=math.floor(now)
    local window=math.min(RECENT_SECONDS,at-recent.startedAt)
    result.recentWindow=window
    if window<MIN_RECENT_SECONDS then return end

    local earned=0
    for index=#recent.samples,1,-1 do
        local sample=recent.samples[index]
        if sample.at<=at-RECENT_SECONDS then break end
        earned=earned+sample.xp
    end
    local rate=earned/window*3600
    if finite(rate) then result.recentPerHour=rate end
end

function M.Summarize(state,now)
    local s=state.last or {}
    local elapsed=finite(now)and finite(state.startedAt)and math.max(0,now-state.startedAt)or nil
    local result={level=s.level,current=s.current,maximum=s.maximum,rested=s.rested,atCap=s.atCap==true,
        elapsed=elapsed,reliable=state.reliable==true,measurementReset=state.measurementReset==true}
    if not state.reliable then return result end
    result.earned=state.earned
    summarizeRecent(state,now,result)
    if elapsed and elapsed>0 then result.perHour=state.earned*3600/elapsed end
    if s.atCap then result.percent=100;result.remaining=0;result.restedEnd=0;return result end
    result.percent=s.current/s.maximum*100
    result.remaining=s.maximum-s.current
    if finite(s.rested)then result.restedEnd=math.min(s.maximum,s.current+math.max(0,s.rested))end
    if result.perHour and result.perHour>0 and result.remaining>0 then result.eta=result.remaining/result.perHour*3600 end
    return result
end
function M.Restore(saved,snapshot,reloaded)
    local at=type(snapshot)=="table"and snapshot.at
    if reloaded and type(saved)=="table" and saved.version==1 and finite(saved.startedAt) and finite(saved.earned) and saved.earned>=0
        and finite(at) and saved.startedAt<=at and valid(saved.last) and saved.last.at<=at then
        local recent,total=M.LoadRecent(saved.recent)
        if recent then
            local latest=recent.samples[#recent.samples]
            if recent.startedAt<math.floor(saved.startedAt) or recent.startedAt>saved.last.at
                or (latest and latest.at>saved.last.at) or total>saved.earned then recent=nil end
        end
        local state={version=1,startedAt=saved.startedAt,earned=saved.earned,last=copy(saved.last),
            reliable=saved.reliable==true,measurementReset=saved.measurementReset==true,recent=recent}
        return M.Observe(state,snapshot)
    end
    return M.New(snapshot,at)
end

function M.Segments(data)
    local result={current={start=0,size=0},quest={start=0,size=0},rested={start=0,size=0},
        questKnown=finite(data.questXP) and data.questXP>=0,restedKnown=finite(data.rested) and data.rested>=0}
    if data.reliable==false then return result end
    if data.atCap then result.current.size=1;return result end
    if not finite(data.current)or not finite(data.maximum)or data.maximum<=0 then return result end
    local maximum=data.maximum
    local current=math.max(0,math.min(maximum,data.current))
    local quest=math.min(maximum-current,result.questKnown and data.questXP or 0)
    local rested=math.min(maximum-current-quest,result.restedKnown and data.rested or 0)
    result.current.size=current/maximum
    result.quest.start=current/maximum;result.quest.size=quest/maximum
    result.rested.start=(current+quest)/maximum;result.rested.size=rested/maximum
    return result
end

-- Completed quest rewards are preview-only, not earned session XP.
ns.QuestXP={}
local Q=ns.QuestXP
function Q.Total(entries,allLoaded)
    if not allLoaded then return nil end
    local total,seen=0,{}
    for _,entry in ipairs(entries)do
        if not seen[entry.id]then
            seen[entry.id]=true
            if not entry.ignored then
                if entry.complete==nil then return nil end
                if entry.complete then
                    if not finite(entry.rewardXP)or entry.rewardXP<0 then return nil end
                    total=total+entry.rewardXP
                end
            end
        end
    end
    return total
end
function Q.Collect(provider,ignored)
    local count,expected=provider.Count()
    if not finite(count)or not finite(expected)or count<0 or count>1000 or expected<0 then return nil end
    local entries,seen,found={}, {},0
    local allLoaded=true
    for index=1,count do
        local info=provider.Info(index)
        if not info then allLoaded=false
        elseif info.isHeader~=true then
            local id=info.questID
            if not finite(id)or id<=0 then allLoaded=false
            elseif not seen[id]then
                seen[id]=true;found=found+1
                local complete=provider.Complete(id)
                entries[#entries+1]={id=id,complete=complete,ignored=ignored and ignored[id],
                    rewardXP=complete==true and provider.Reward(id)or nil}
            end
        end
    end
    return Q.Total(entries,allLoaded and found==expected)
end

function M.DisplayAmount(amount,maximum,mode)
    if not finite(amount) then return nil end
    if mode=="percent" and finite(maximum) and maximum>0 then return amount/maximum*100 end
    return amount
end

local function flightFinite(value)return finite(value)end
local function validRouteKey(route)
    if type(route)~="string"or #route<5 or #route>150 or route:find("[|;\r\n\t]")then return false end
    local split=route:find(" -> ",1,true)
    return split~=nil and split>1 and split+4<=#route
end
local function validFlightSeconds(value)return flightFinite(value) and value>=5 and value<=3600 end
local function routeCount(routes)
    local count=0
    for route in pairs(type(routes)=="table"and routes or {})do if validRouteKey(route)then count=count+1 end end
    return count
end
function M.FlightRouteKey(origin,destination)
    if type(origin)~="string"or type(destination)~="string"then return nil end
    origin=origin:match("^%s*(.-)%s*$");destination=destination:match("^%s*(.-)%s*$")
    if #origin<2 or #origin>70 or #destination<2 or #destination>70 then return nil end
    local route=origin.." -> "..destination
    return validRouteKey(route)and route or nil
end
function M.FlightEstimate(routeSeconds,routeLength,secondsPerUnit)
    local estimate
    if validFlightSeconds(routeSeconds)then estimate=routeSeconds
    elseif flightFinite(routeLength)and routeLength>0 and routeLength<=10 and flightFinite(secondsPerUnit)and secondsPerUnit>=100 and secondsPerUnit<=4000 then
        estimate=routeLength*secondsPerUnit
        if estimate<5 then estimate=5 elseif estimate>3600 then estimate=3600 end
    end
    return estimate
end
function M.FlightProgress(elapsed,estimate)
    if not flightFinite(elapsed)or elapsed<0 or not validFlightSeconds(estimate)then return nil end
    return math.max(0,math.min(1,elapsed/estimate))
end
function M.ImportFlightData(flightData,source)
    if type(flightData)~="table"then return false end
    flightData.routes=type(flightData.routes)=="table"and flightData.routes or {}
    if flightData.importedForeverXPBar==true or type(source)~="table"then return false end
    local copied=false;local count=routeCount(flightData.routes)
    if type(source.flightRouteDurations)=="table"then
        local keys={};for route in pairs(source.flightRouteDurations)do if validRouteKey(route)then keys[#keys+1]=route end end
        table.sort(keys)
        for _,route in ipairs(keys)do
            local seconds=source.flightRouteDurations[route]
            if count>=500 then break end
            if validFlightSeconds(seconds)and not validFlightSeconds(flightData.routes[route])then
                flightData.routes[route]=seconds;count=count+1;copied=true
            end
        end
    end
    if (not flightFinite(flightData.secondsPerUnit)or flightData.secondsPerUnit==650)
        and flightFinite(source.flightScale)and source.flightScale>=100 and source.flightScale<=4000 then
        flightData.secondsPerUnit=source.flightScale;copied=true
    end
    if copied then flightData.importedForeverXPBar=true end
    return copied
end
function M.RecordFlight(flightData,route,seconds,routeLength)
    if type(flightData)~="table"or not validRouteKey(route)or not validFlightSeconds(seconds)
        or not flightFinite(routeLength)or routeLength<=0 or routeLength>10 then return false end
    flightData.routes=type(flightData.routes)=="table"and flightData.routes or {}
    local old=flightData.routes[route]
    if not validFlightSeconds(old)and routeCount(flightData.routes)>=500 then return false end
    flightData.routes[route]=validFlightSeconds(old)and old*0.7+seconds*0.3 or seconds
    local oldScale=flightData.secondsPerUnit
    if not flightFinite(oldScale)or oldScale<100 or oldScale>4000 then oldScale=650 end
    local sample=seconds/routeLength
    flightData.secondsPerUnit=math.max(100,math.min(4000,oldScale*0.7+sample*0.3))
    return true
end
