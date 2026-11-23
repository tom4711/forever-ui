local total, failed = 0, 0
function test(name, body)
    total = total + 1
    local ok, message = pcall(body)
    if ok then
        print("PASS " .. name)
    else
        failed = failed + 1
        print("FAIL " .. name .. ": " .. tostring(message))
    end
end
function loadAddon(path, namespace)
    local chunk = assert(loadfile("ForeverUI/" .. path))
    chunk("ForeverUI", namespace)
end
function withGlobals(overrides, body)
    local saved = {}
    for name, value in pairs(overrides) do
        saved[name] = _G[name]
        _G[name] = value
    end
    local ok, message = pcall(body)
    for name in pairs(overrides) do _G[name] = saved[name] end
    if not ok then error(message, 0) end
end
for _, path in ipairs({
    "tests/settings_test.lua",
    "tests/read_test.lua",
    "tests/hunter_test.lua",
    "tests/hunter_actions_test.lua",
    "tests/paladin_test.lua",
    "tests/paladin_controller_test.lua",
    "tests/warlock_test.lua",
    "tests/warlock_controller_test.lua",
    "tests/class_views_test.lua",
    "tests/target_test.lua",
    "tests/party_test.lua",
    "tests/player_castbar_test.lua",
    "tests/inventory_appearance_test.lua",
    "tests/combat_queue_test.lua",
    "tests/food_test.lua",
    "tests/xp_test.lua",
    "tests/quest_xp_test.lua",
    "tests/xp_controller_test.lua",
}) do
    dofile(path)
end
print(string.format("%d tests, %d failures", total, failed))
os.exit(failed == 0 and 0 or 1)
