local _, ns = ...
ns.Read = {}
local function secret(value)
    return issecretvalue and issecretvalue(value)
end
function ns.Read.Number(value)
    if secret(value) or type(value) ~= "number" then return nil end
    if value ~= value or value == math.huge or value == -math.huge then return nil end
    return value
end
function ns.Read.Boolean(value)
    if secret(value) or type(value) ~= "boolean" then return nil end
    return value
end
