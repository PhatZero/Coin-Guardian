-- Coin Guardian: profit footer EMBEDDED in the WoW Forever Auction House Sell tab.
-- Does not create top-level, movable, or out-of-AH windows; never touches posting APIs.
local _, CG = ...
CG.UI = {}
local UI = CG.UI
local Pricing = CG.Pricing
local unpack = unpack
local gold = { 1.00, 0.82, 0.40 }
local pale = { 0.96, 0.92, 0.82 }
local green = { 0.35, 0.92, 0.52 }
local red = { 1.00, 0.32, 0.31 }
local amber = { 1.00, 0.77, 0.28 }

local function label(parent, text, x, y, width, align, template)
    local f = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    f:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    f:SetSize(width, 20)
    f:SetJustifyH(align or "LEFT")
    f:SetText(text or "")
    return f
end

local function color(f, shade)
    f:SetTextColor(shade[1], shade[2], shade[3])
end

local function background(parent, x, y, width, height, shade)
    local t = parent:CreateTexture(nil, "BACKGROUND")
    t:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    t:SetSize(width, height)
    t:SetColorTexture(unpack(shade))
    return t
end

local function canShow()
    local house = _G.AuctionHouseFrame
    if not house or not house.IsShown or not house:IsShown() then return nil end
    local item = house.ItemSellFrame
    local commodity = house.CommoditiesSellFrame
    if (item and item.IsShown and item:IsShown())
        or (commodity and commodity.IsShown and commodity:IsShown()) then
        return house
    end
    return nil
end
UI.CanShow = canShow

-- Make room INSIDE the right half of the Sell tab by reducing the native
-- results list height. Preserve every original anchor so hiding Coin Guardian
-- restores Blizzard's layout exactly.
local function saveListAnchors(list)
    local points = {}
    if list.GetNumPoints and list.GetPoint then
        for i = 1, list:GetNumPoints() do
            points[#points + 1] = { list:GetPoint(i) }
        end
    end
    return points
end

local function restoreList()
    if not UI.dockedList then return end
    local list = UI.dockedList
    if list.ClearAllPoints and list.SetPoint then
        list:ClearAllPoints()
        for _, point in ipairs(UI.originalAnchors or {}) do
            list:SetPoint(unpack(point))
        end
    end
    if list.MarkDirty then list:MarkDirty() end
    UI.dockedList = nil
    UI.originalAnchors = nil
end

local function dock(house)
    local list = house.ItemSellList
    local sell = house.ItemSellFrame
    if not list or not sell or not list.GetNumPoints or not list.GetPoint then
        return false
    end
    if UI.dockedList == list then return true end
    restoreList()
    local original = saveListAnchors(list)
    if #original == 0 then return false end
    UI.originalAnchors = original
    UI.dockedList = list
    list:ClearAllPoints()
    list:SetPoint("TOPLEFT", sell, "TOPRIGHT", 1, 0)
    list:SetPoint("RIGHT", house, "RIGHT", -5, 0)
    -- 180px footer plus an 8px gap, inside the Sell tab's original list area.
    list:SetPoint("BOTTOMLEFT", sell, "BOTTOMRIGHT", 1, 188)
    if list.MarkDirty then list:MarkDirty() end
    return true
end

local function makeFooter(house)
    if UI.panel and UI.house == house then return UI.panel end
    local panel = CreateFrame("Frame", "CoinGuardianSellFooter", house)
    panel:SetHeight(180)
    panel:SetPoint("BOTTOMLEFT", house.ItemSellFrame, "BOTTOMRIGHT", 1, 0)
    panel:SetPoint("RIGHT", house, "RIGHT", -5, 0)
    background(panel, 0, 0, 405, 180, { 0.05, 0.05, 0.04, 0.94 })
    background(panel, 1, -1, 403, 2, { 0.68, 0.48, 0.18, 1 })

    local header = label(panel, "COIN GUARDIAN  |  SELL PROFIT", 12, -7, 335, "LEFT", "GameFontNormal")
    color(header, gold)
    UI.status = label(panel, "Choose an item and asking price", 12, -27, 389, "LEFT", "GameFontHighlightSmall")
    color(UI.status, amber)

    UI.rows = {}
    local rows = {
        { "Vendor value", "vendor", 12, -52, 75, 90 },
        { "AH asking", "gross", 211, -52, 68, 112 },
        { "AH fee (5%)", "cut", 12, -76, 75, 90 },
        { "After AH cut", "net", 211, -76, 75, 105 },
        { "Profit", "profit", 12, -100, 75, 90 },
        { "Min. AH price", "minimum", 211, -100, 82, 98 },
        { "Deposit*", "deposit", 12, -124, 75, 90 },
    }
    for _, row in ipairs(rows) do
        label(panel, row[1], row[3], row[4], row[5])
        local x = row[3] == 12 and 98 or 295
        local val = label(panel, "--", x, row[4], row[6], "RIGHT", "GameFontNormalSmall")
        UI.rows[row[2]] = val
    end

    local marginText = label(panel, "Profit target", 211, -124, 90, "LEFT", "GameFontHighlightSmall")
    color(marginText, pale)
    UI.marginValue = label(panel, "50%", 315, -124, 78, "RIGHT", "GameFontNormalSmall")
    color(UI.marginValue, gold)

    local slider = CreateFrame("Slider", "CoinGuardianInlineMarginSlider", panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", panel, "TOPLEFT", 19, -155)
    slider:SetSize(274, 14)
    slider:SetMinMaxValues(0, 200)
    slider:SetValueStep(5)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    local low = _G[slider:GetName() .. "Low"]
    local high = _G[slider:GetName() .. "High"]
    if low then low:SetText("0%") end
    if high then high:SetText("200%") end
    slider:SetScript("OnValueChanged", function(_, value)
        if UI.updatingSlider or not CG.db then return end
        local percent = Pricing.NormalizeMargin(value)
        if percent ~= value then
            UI.updatingSlider = true
            slider:SetValue(percent)
            UI.updatingSlider = false
        end
        UI.marginValue:SetText(percent .. "%")
        if percent ~= CG.GetMargin() then CG.SetMargin(percent) end
    end)
    UI.slider = slider

    local reset = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    reset:SetSize(86, 21)
    reset:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -16, -150)
    reset:SetText("Reset 50%")
    reset:SetScript("OnClick", function() CG.SetMargin(50) end)
    UI.reset = reset

    -- The deposit is refunded on a successful sale; there is no second deduction.
    if panel.SetScript then
        panel:SetScript("OnEnter", function(self)
            if not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_LEFT")
            GameTooltip:SetText("Coin Guardian", 1, 0.82, 0.4)
            GameTooltip:AddLine("Profit is compared with vendor selling, after the 5% AH cut.", 0.9, 0.9, 0.85, true)
            GameTooltip:AddLine("*Deposit is usually refunded on sale, lost on expiry.", 0.9, 0.9, 0.85, true)
            GameTooltip:Show()
        end)
        panel:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    end

    panel:Hide()
    UI.panel, UI.house = panel, house
    return panel
end

local function fill(result)
    local fields = UI.rows
    local function put(key, value, prefix)
        fields[key]:SetText(value ~= nil and ((prefix or "") .. Pricing.CoinText(value)) or "--")
    end
    put("vendor", result and result.vendor)
    put("gross", result and result.gross)
    put("cut", result and result.cut, result and "-" or "")
    put("net", result and result.net)
    put("profit", result and result.profit, result and result.profit and result.profit > 0 and "+" or "")
    put("minimum", result and result.minimumGross)
    put("deposit", result and result.deposit)
    color(fields.profit, result and result.profit and (result.profit < 0 and red or green) or pale)
end

function UI.Refresh(force)
    if not CG.db then return end
    local house = canShow()
    if not house or not CG.db.enabled then
        if UI.panel then UI.panel:Hide() end
        restoreList()
        UI.lastFingerprint = nil
        return
    end

    local panel = makeFooter(house)
    if not dock(house) then
        -- Avoid drawing over auctions if Blizzard's list structure changed.
        panel:Hide()
        UI.lastFingerprint = nil
        return
    end
    if not panel:IsShown() then
        panel:Show()
        force = true
    end
    local target = CG.GetMargin()
    if force or UI.slider:GetValue() ~= target then
        UI.updatingSlider = true
        UI.slider:SetValue(target)
        UI.updatingSlider = false
        UI.marginValue:SetText(target .. "%")
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
        UI.status:SetText("Choose an item and asking price")
        color(UI.status, amber)
        fill(nil)
        return
    end
    local outcome = Pricing.Evaluate(context.vendorEach, context.quantity, context.priceEach, target, context.deposit)
    fill(outcome)
    if outcome.state == "sell" then
        UI.status:SetText("SELL ON AH  |  +" .. string.format("%.1f%%", outcome.profitPercent))
        color(UI.status, green)
    elseif outcome.state == "loss" then
        UI.status:SetText("WARNING: VENDOR PAYS MORE")
        color(UI.status, red)
    elseif outcome.state == "below_target" then
        UI.status:SetText("BELOW YOUR " .. target .. "% TARGET")
        color(UI.status, amber)
    elseif outcome.state == "zero_vendor" then
        UI.status:SetText("NO VENDOR VALUE  |  CHECK PRICE")
        color(UI.status, amber)
    else
        UI.status:SetText(outcome.reason or "Price information unavailable")
        color(UI.status, amber)
    end
end
