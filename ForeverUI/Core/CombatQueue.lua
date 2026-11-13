local _,ns=...
local function new(isLocked)
    local pending={}
    local queue={}
    function queue.Request(key,apply)
        if isLocked() then pending[key]=apply;return false end
        pending[key]=nil;apply();return true
    end
    function queue.Flush()
        for key,apply in pairs(pending)do
            if isLocked()then return false end
            pending[key]=nil;apply()
        end
        return true
    end
    return queue
end
ns.CombatQueue=new(function()return InCombatLockdown()end)
ns.CombatQueue.New=new
