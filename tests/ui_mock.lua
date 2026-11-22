-- Read-only UI integration smoke test using stub WoW frames (Lua 5.1).
local CG = {}
local frames = {}
local function Widget(name)
    local obj = { name = name, visible = false, scripts = {} }
    function obj:CreateFontString() return Widget() end
    function obj:CreateTexture() return Widget() end
    function obj:SetSize(...) end
    function obj:SetPoint(...) end
    function obj:ClearAllPoints() end
    function obj:SetFrameStrata(...) end
    function obj:SetClampedToScreen(...) end
    function obj:EnableMouse(...) end
    function obj:SetColorTexture(...) end
    function obj:SetTexture(...) end
    function obj:SetText(value) self.text = value end
    function obj:SetWordWrap(...) end
    function obj:SetJustifyH(...) end
    function obj:SetTextColor(...) end
    function obj:SetMinMaxValues(...) end
    function obj:SetValueStep(...) end
    function obj:SetObeyStepOnDrag(...) end
    function obj:GetName() return self.name end
    function obj:SetScript(which, callback) self.scripts[which] = callback end
    function obj:GetValue() return self.value or 0 end
    function obj:SetValue(value)
        self.value = value
        if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
    end
    function obj:Show() self.visible = true end
    function obj:Hide() self.visible = false end
    function obj:IsShown() return self.visible end
    function obj:GetRight() return 900 end
    function obj:RegisterEvent(...) end
    frames[#frames + 1] = obj
    return obj
end
CreateFrame = function(kind, name)
    local frame = Widget(name)
    if name then
        _G[name] = frame
        if kind == "Slider" then
            _G[name .. "Low"] = Widget()
            _G[name .. "High"] = Widget()
        end
    end
    return frame
end
UIParent = Widget()
function UIParent:GetRight() return 1900 end
local item = { IsValid = function() return true end }
local price = 20000
C_Item = {
    GetItemLink = function() return "|Hitem:1|h[Sample Item]|h" end,
    GetItemInfo = function()
        return "Sample Item", "link", 1, 1, 1, "Trade Goods", "Cloth", 20, "", 0, 10000
    end,
}
AuctionHouseFrame = {
    IsShown = function() return true end,
    IsListingAuctions = function() return true end,
    GetRight = function() return 800 end,
    CommoditiesSellFrame = {
        IsShown = function() return true end,
        GetItem = function() return item end,
        GetQuantity = function() return 1 end,
        GetUnitPrice = function() return price end,
        GetDepositAmount = function() return 1234 end,
    },
}
assert(loadfile("addon/Pricing.lua"))("CoinGuardian", CG)
assert(loadfile("addon/Auction.lua"))("CoinGuardian", CG)
assert(loadfile("addon/UI.lua"))("CoinGuardian", CG)
CG.db = { enabled = true, minimumProfit = 50 }
function CG.GetMargin() return CG.Pricing.NormalizeMargin(CG.db.minimumProfit) end
function CG.SetMargin(p) CG.db.minimumProfit = CG.Pricing.NormalizeMargin(p); CG.UI.Refresh(true) end
CG.UI.Refresh(true)
assert(CG.UI.panel and CG.UI.panel:IsShown(), "Panel should be visible on Sell tab")
assert(CG.UI.status.text:find("SELL ON AUCTION HOUSE"), "Expected sell recommendation")
assert(CG.UI.rows.net.text == "1g 90s 00c", "Expected net after AH cut")
price = 9000
CG.UI.Refresh(false)
assert(CG.UI.status.text:find("VENDOR PAYS MORE"), "Expected visible loss warning")
price = 20000
CG.UI.slider:SetValue(100)
assert(CG.db.minimumProfit == 100, "Slider should update SavedVariables")
assert(CG.UI.status.text:find("BELOW YOUR 100%% TARGET"), "Expected below-target state")
CG.UI.reset.scripts.OnClick()
assert(CG.db.minimumProfit == 50, "Reset should restore default")
CG.db.enabled = false
CG.UI.Refresh(true)
assert(not CG.UI.panel:IsShown(), "Hide should hide panel")
print("PASS: Coin Guardian UI panel, sell warnings, and slider mocks")
