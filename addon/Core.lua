local addonName, CG = ...
CG.version = "0.1.3-alpha"
CG.defaultMargin = 50
CG.manualOpen = false

function CG.GetMargin()
    return CG.Pricing.NormalizeMargin(CG.db and CG.db.minimumProfit or 50)
end

function CG.SetMargin(percent)
    local normalized = CG.Pricing.NormalizeMargin(percent)
    if CG.db then CG.db.minimumProfit = normalized end
    if CG.UI then CG.UI.Refresh(true) end
    return normalized
end

local function Say(text)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd76aCoin Guardian|r: " .. text)
    end
end

local function OpenUI(force)
    if not CG.db then return end
    if force == nil then CG.db.enabled = not CG.db.enabled else CG.db.enabled = force end
    if CG.UI then CG.UI.Refresh(true) end
    Say(CG.db.enabled and "Profit panel enabled." or "Profit panel hidden. Use /cg show to restore it.")
end

-- Coin Guardian lives inside the AH Sell tab; never spawn a separate window.
function CG.TogglePanel()
    if not CG.db then return end
    if not CG.UI or not CG.UI.CanShow() then
        Say("Open the Auction House Sell tab to use Coin Guardian.")
        return
    end
    CG.db.enabled = not CG.db.enabled
    CG.UI.Refresh(true)
end

function CG.OpenSettings()
    if not CG.db then return end
    if not CG.UI or not CG.UI.CanShow() then
        Say("Profit settings are built into the Auction House Sell tab.")
        return
    end
    CG.db.enabled = true
    CG.UI.Refresh(true)
end

SLASH_COINGUARDIAN1 = "/cg"
SLASH_COINGUARDIAN2 = "/coinguardian"
SlashCmdList["COINGUARDIAN"] = function(message)
    local cmd, argument = (message or ""):match("^%s*(%S*)%s*(.-)%s*$")
    cmd = string.lower(cmd or "")
    if cmd == "show" then OpenUI(true)
    elseif cmd == "hide" then OpenUI(false)
    elseif cmd == "reset" then
        CG.SetMargin(50)
        Say("Minimum net profit reset to 50% above vendor value.")
    elseif cmd == "margin" then
        local value = tonumber(argument)
        if not value then Say("Usage: /cg margin 75  (0 to 200, steps of 5)")
        else Say("Minimum net profit set to " .. CG.SetMargin(value) .. "% above vendor value.") end
    elseif cmd == "status" then
        Say("Version " .. CG.version .. ", margin " .. CG.GetMargin() .. "%, panel " .. (CG.db and CG.db.enabled and "on" or "off") .. ".")
    elseif cmd == "minimap" then
        local choice = string.lower(argument or "")
        if choice == "hide" or choice == "show" then
            CG.db.minimapVisible = choice == "show"
            if CG.Minimap then CG.Minimap.Refresh() end
            Say("Minimap icon " .. (CG.db.minimapVisible and "shown." or "hidden. Use /cg minimap show to restore."))
        elseif choice == "reset" then
            CG.db.minimapAngle = 225
            if CG.Minimap then CG.Minimap.Reposition() end
            Say("Minimap icon returned to the default rim position.")
        else
            Say("Usage: /cg minimap show | hide | reset")
        end
    elseif cmd == "" then
        CG.TogglePanel()
    else
        Say("Commands: /cg, /cg show, /cg hide, /cg margin 75, /cg reset, /cg minimap show/hide/reset")
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
eventFrame:RegisterEvent("AUCTION_HOUSE_CLOSED")
eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if type(CoinGuardianDB) ~= "table" then CoinGuardianDB = {} end
        CG.db = CoinGuardianDB
        if CG.db.enabled == nil then CG.db.enabled = true end
        CG.db.minimumProfit = CG.Pricing.NormalizeMargin(CG.db.minimumProfit)
        if CG.Minimap then CG.Minimap.Create() end
        Say("Local QA " .. CG.version .. " loaded. Visit an auctioneer or use /cg.")
    elseif event == "AUCTION_HOUSE_CLOSED" then
        if CG.UI then CG.UI.Refresh(true) end
    elseif event == "AUCTION_HOUSE_SHOW" then
        if CG.UI then CG.UI.Refresh(true) end
    end
end)

-- Small read-only refresh while the AH is visible; does not hook protected actions
-- or replace Blizzard callbacks. This also notices loaded-on-demand AH frames.
local elapsed = 0
eventFrame:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + (delta or 0)
    if elapsed < 0.25 then return end
    elapsed = 0
    if CG.db and CG.UI then CG.UI.Refresh(false) end
    if CG.db and CG.Minimap then CG.Minimap.Refresh() end
end)
