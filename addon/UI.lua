-- Coin Guardian: compact native-feeling, read-only panel for Forever's sell tab.
local _, CG = ...
CG.UI = {}
local UI = CG.UI
local Pricing = CG.Pricing
local gold = { 1.00, 0.82, 0.40 }
local pale = { 0.96, 0.92, 0.82 }
local green = { 0.35, 0.92, 0.52 }
local red = { 1.00, 0.32, 0.31 }
local amber = { 1.00, 0.77, 0.28 }

local function Label(parent, text, template, x, y, width, align)
    local field = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    field:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    field:SetSize(width, 22)
    field:SetJustifyH(align or "LEFT")
    field:SetText(text or "")
    return field
end

local function ColorText(label, color)
    label:SetTextColor(color[1], color[2], color[3])
end

local function Background(frame, left, top, width, height, color)
    local texture = frame:CreateTexture(nil, "BACKGROUND")
    texture:SetPoint("TOPLEFT", frame, "TOPLEFT", left, top)
    texture:SetSize(width, height)
    texture:SetColorTexture(unpack(color))
    return texture
end

local function LayoutPanel(panel, atHouse)
    panel:ClearAllPoints()
    local house = _G.AuctionHouseFrame
    if atHouse and house then
        local houseRight = house.GetRight and house:GetRight()
        local uiRight = UIParent.GetRight and UIParent:GetRight()
        if houseRight and uiRight and houseRight + 348 > uiRight then
            panel:SetPoint("TOPRIGHT", house, "TOPLEFT", -10, -10)
        else
            panel:SetPoint("TOPLEFT", house, "TOPRIGHT", 10, -10)
        end
    else
        panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

local function MakePanel()
    if UI.panel then return UI.panel end
    local panel = CreateFrame("Frame", "CoinGuardianPanel", UIParent)
    panel:SetSize(340, 473)
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    Background(panel, 0, 0, 340, 473, { 0.04, 0.035, 0.025, 0.96 })
    Background(panel, 2, -2, 336, 2, { 0.65, 0.43, 0.16, 1 })
    Background(panel, 2, -469, 336, 2, { 0.40, 0.29, 0.12, 1 })
    Background(panel, 2, -2, 2, 469, { 0.40, 0.29, 0.12, 1 })
    Background(panel, 336, -2, 2, 469, { 0.40, 0.29, 0.12, 1 })
    Background(panel, 15, -133, 310, 1, { 0.37, 0.29, 0.15, 0.8 })
    Background(panel, 15, -330, 310, 1, { 0.37, 0.29, 0.15, 0.8 })

    local icon = panel:CreateTexture(nil, "ARTWORK")
    icon:SetSize(33, 33)
    icon:SetPoint("TOPLEFT", 16, -15)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    local title = Label(panel, "COIN GUARDIAN", "GameFontNormalLarge", 55, -17, 240)
    ColorText(title, gold)
    local subtitle = Label(panel, "Protect your gold. Keep the profit.", "GameFontHighlightSmall", 55, -40, 255)
    ColorText(subtitle, pale)

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    close:SetScript("OnClick", function()
        if CG.db then CG.db.enabled = false end
        CG.manualOpen = false
        UI.Refresh(true)
    end)

    UI.itemLabel = Label(panel, "Choose an item in the Sell tab", "GameFontNormal", 18, -76, 305)
    UI.itemLabel:SetWordWrap(false)
    Background(panel, 15, -100, 310, 30, { 0.12, 0.11, 0.08, 1 })
    UI.status = Label(panel, "Waiting for a listing", "GameFontNormal", 25, -106, 295)
    ColorText(UI.status, amber)

    UI.rows = {}
    local rows = {
        { "Vendor equivalent", "vendor" },
        { "AH asking price", "gross" },
        { "Auction House cut (5%)", "cut" },
        { "You'll receive after cut", "net" },
        { "Profit over vendor", "profit" },
        { "Minimum AH price", "minimum" },
        { "Refundable deposit*", "deposit" },
    }
    for index, row in ipairs(rows) do
        local y = -148 - (index - 1) * 26
        local key = row[2]
        local label = Label(panel, row[1], "GameFontHighlightSmall", 18, y, 200)
        local value = Label(panel, "--", "GameFontNormal", 212, y, 112, "RIGHT")
        UI.rows[key] = value
        if key == "net" or key == "profit" then ColorText(value, gold) end
    end

    UI.sliderTitle = Label(panel, "MINIMUM PROFIT OVER VENDOR", "GameFontNormal", 18, -346, 252)
    ColorText(UI.sliderTitle, gold)
    UI.sliderValue = Label(panel, "50%", "GameFontNormalLarge", 268, -345, 54, "RIGHT")
    ColorText(UI.sliderValue, gold)

    local slider = CreateFrame("Slider", "CoinGuardianMarginSlider", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", panel, "TOPLEFT", 31, -387)
    slider:SetSize(277, 18)
    slider:SetMinMaxValues(0, 200)
    slider:SetValueStep(5)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    local low = _G[slider:GetName() .. "Low"]
    local high = _G[slider:GetName() .. "High"]
    if low then low:SetText("0%") end
    if high then high:SetText("200%") end
    slider:SetScript("OnValueChanged", function(_, value)
        if not CG.db or UI.settingSlider then return end
        local percent = Pricing.NormalizeMargin(value)
        if value ~= percent then
            UI.settingSlider = true
            slider:SetValue(percent)
            UI.settingSlider = false
        end
        if percent ~= CG.GetMargin() then CG.SetMargin(percent) end
        UI.sliderValue:SetText(percent .. "%")
    end)
    UI.slider = slider

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(94, 22)
    reset:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -18, -422)
    reset:SetText("Reset 50%")
    reset:SetScript("OnClick", function() CG.SetMargin(50) end)
    UI.reset = reset
    local foot = Label(panel, "*Lost if the auction expires. Profit assumes a sale.", "GameFontHighlightSmall", 18, -447, 300)
    ColorText(foot, { 0.72, 0.67, 0.54 })

    panel:Hide()
    UI.panel = panel
    return panel
end

local function SetStatus(text, color)
    UI.status:SetText(text)
    ColorText(UI.status, color)
end

local function Values(result)
    local values = UI.rows
    local function set(key, amount, prefix)
        values[key]:SetText(amount ~= nil and ((prefix or "") .. Pricing.CoinText(amount)) or "--")
    end
    set("vendor", result and result.vendor)
    set("gross", result and result.gross)
    set("cut", result and result.cut, result and "-" or "")
    set("net", result and result.net)
    set("profit", result and result.profit, result and result.profit and result.profit > 0 and "+" or "")
    set("minimum", result and result.minimumGross)
    set("deposit", result and result.deposit)
    ColorText(values.profit, result and result.profit and (result.profit < 0 and red or green) or pale)
end

function UI.Refresh(force)
    if not CG.db then return end
    local house = _G.AuctionHouseFrame
    local atHouse = house and house.IsShown and house:IsShown() and house.IsListingAuctions and house:IsListingAuctions()
    local shouldShow = (CG.db.enabled and atHouse) or CG.manualOpen
    if not shouldShow then
        if UI.panel then UI.panel:Hide() end
        UI.lastFingerprint = nil
        return
    end
    MakePanel()
    if not UI.panel:IsShown() then
        LayoutPanel(UI.panel, atHouse)
        UI.panel:Show()
        force = true
    elseif force then
        LayoutPanel(UI.panel, atHouse)
    end
    local target = CG.GetMargin()
    if force or UI.slider:GetValue() ~= target then
        UI.settingSlider = true
        UI.slider:SetValue(target)
        UI.settingSlider = false
        UI.sliderValue:SetText(target .. "%")
    end
    local context, state = CG.Auction.GetContext()
    local fingerprint
    if context and not context.empty then
        fingerprint = table.concat({ tostring(context.item), tostring(context.name), tostring(context.vendorEach),
            tostring(context.quantity), tostring(context.priceEach), tostring(context.deposit), tostring(target) }, "|")
    else
        fingerprint = tostring(state) .. "|" .. tostring(target)
    end
    if not force and fingerprint == UI.lastFingerprint then return end
    UI.lastFingerprint = fingerprint
    if not context or context.empty then
        UI.itemLabel:SetText(atHouse and "Choose an item in the Sell tab" or "Open an auctioneer to evaluate a sale")
        SetStatus("Waiting for an item and price", amber)
        Values(nil)
        return
    end
    UI.itemLabel:SetText((context.name or "Selected item") .. "  x" .. tostring(context.quantity or "?") ..
        (context.isCommodity and " (commodity)" or ""))
    local outcome = Pricing.Evaluate(context.vendorEach, context.quantity, context.priceEach, target, context.deposit)
    Values(outcome)
    if outcome.state == "sell" then
        SetStatus("SELL ON AUCTION HOUSE  |  +" .. string.format("%.1f%%", outcome.profitPercent), green)
    elseif outcome.state == "loss" then
        SetStatus("WARNING: VENDOR PAYS MORE!", red)
    elseif outcome.state == "below_target" then
        SetStatus("BELOW YOUR " .. target .. "% TARGET", amber)
    elseif outcome.state == "zero_vendor" then
        SetStatus("VENDOR PAYS NOTHING  |  CHECK PRICE", amber)
    else
        SetStatus(outcome.reason or "Price information unavailable", amber)
    end
end
