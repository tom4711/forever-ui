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
    local chunk = loadfile("ForeverUI/" .. path)
    if chunk then chunk("ForeverUI", namespace) end
end
for _, path in ipairs({"tests/settings_test.lua", "tests/read_test.lua", "tests/hunter_test.lua", "tests/combat_queue_test.lua", "tests/food_test.lua", "tests/xp_test.lua", "tests/quest_xp_test.lua"}) do
    dofile(path)
end
print(string.format("%d tests, %d failures", total, failed))
os.exit(failed == 0 and 0 or 1)
