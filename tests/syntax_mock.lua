for _, file in ipairs({
    "addon/Pricing.lua", "addon/Auction.lua", "addon/UI.lua", "addon/Minimap.lua", "addon/Core.lua",
    "tests/profit_mock.lua", "tests/auction_mock.lua", "tests/ui_mock.lua", "tests/minimap_mock.lua"
}) do
    local chunk, errorText = loadfile(file)
    assert(chunk, tostring(file) .. ": " .. tostring(errorText))
end
print("PASS: all Lua source files parse")
