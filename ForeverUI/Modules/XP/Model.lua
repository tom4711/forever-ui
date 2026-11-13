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
function M.New(snapshot,startedAt)
    snapshot=copy(snapshot)
    local start=finite(startedAt) and startedAt or snapshot.at
    return {version=1,startedAt=start,earned=0,last=snapshot,reliable=valid(snapshot),measurementReset=false}
end
local function reset(state,snapshot)
    state.startedAt=snapshot.at;state.earned=0;state.last=copy(snapshot)
    state.reliable=true;state.measurementReset=true
    return state
end
function M.Observe(state,snapshot)
    snapshot=copy(snapshot)
    if not valid(snapshot)then state.last=snapshot;state.reliable=false;return state end
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
    return state
end
function M.Summarize(state,now)
    local s=state.last or {}
    local elapsed=finite(now)and finite(state.startedAt)and math.max(0,now-state.startedAt)or nil
    local result={level=s.level,current=s.current,maximum=s.maximum,rested=s.rested,atCap=s.atCap==true,
        elapsed=elapsed,reliable=state.reliable==true,measurementReset=state.measurementReset==true}
    if not state.reliable then return result end
    result.earned=state.earned
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
        local state={version=1,startedAt=saved.startedAt,earned=saved.earned,last=copy(saved.last),
            reliable=saved.reliable==true,measurementReset=saved.measurementReset==true}
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
