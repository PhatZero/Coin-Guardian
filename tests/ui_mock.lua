-- Coin Guardian UI integration: the footer must live inside the AH Sell tab.
local CG = {}
local function Widget(name, parent)
    local obj = { name = name, parent = parent, visible = false, scripts = {}, points = {} }
    function obj:CreateFontString() return Widget(nil, self) end
    function obj:CreateTexture() return Widget(nil, self) end
    function obj:SetSize(w,h) self.width, self.height = w,h end
    function obj:SetHeight(h) self.height = h end
    function obj:SetPoint(...) self.points[#self.points + 1] = { ... } end
    function obj:GetNumPoints() return #self.points end
    function obj:GetPoint(n) return unpack(self.points[n]) end
    function obj:ClearAllPoints() self.points = {} end
    function obj:GetParent() return self.parent end
    function obj:SetColorTexture(...) end
    function obj:SetTexture(...) end
    function obj:SetText(value) self.text = value end
    function obj:SetTextColor(...) end
    function obj:SetJustifyH(...) end
    function obj:SetWordWrap(...) end
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
    function obj:MarkDirty() self.markedDirty = true end
    return obj
end

local createdFooter
function CreateFrame(kind, name, parent)
    local frame = Widget(name, parent)
    if name then
        _G[name] = frame
        if kind == "Slider" then
            _G[name .. "Low"] = Widget()
            _G[name .. "High"] = Widget()
        end
        if name == "CoinGuardianSellFooter" then createdFooter = frame end
    end
    return frame
end
local house = Widget("AuctionHouseFrame")
local sell = Widget("ItemSellFrame", house)
local list = Widget("ItemSellList", house)
local commodity = Widget("CommoditiesSellFrame", house)
local regular = Widget("ItemSellFrame", house)
local market = Widget("CommoditiesSellList", house)
list:SetPoint("TOPLEFT", sell, "TOPRIGHT", 1, 0)
list:SetPoint("RIGHT", house, "RIGHT", -5, 0)
list:SetPoint("BOTTOMLEFT", sell, "BOTTOMRIGHT", 1, 0)
local before = {}
for i=1,list:GetNumPoints() do before[i]={list:GetPoint(i)} end
house.ItemSellList = list
house.ItemSellFrame = regular
house.CommoditiesSellFrame = commodity
house.CommoditiesSellList = market
function house:IsListingAuctions() return regular.visible or commodity.visible end
AuctionHouseFrame = house

local item = { IsValid = function() return true end }
local price = 20000
local q = 1
C_Item = {
    GetItemLink = function() return "|Hitem:1|h[Sample Item]|h" end,
    GetItemInfo = function()
        return "Sample Item", "link", 1, 1, 1, "Trade Goods", "Cloth", 20, "", 0, 10000
    end,
}
function commodity:GetItem() return item end
function commodity:GetQuantity() return q end
function commodity:GetUnitPrice() return price end
function commodity:GetDepositAmount() return 1234 end
function regular:GetItem() return item end
function regular:GetQuantity() return q end
function regular:GetPrice() return 0, price end
function regular:GetDepositAmount() return 2345 end

assert(loadfile("addon/Pricing.lua"))("CoinGuardian", CG)
assert(loadfile("addon/Auction.lua"))("CoinGuardian", CG)
assert(loadfile("addon/UI.lua"))("CoinGuardian", CG)
CG.db = { enabled = true, minimumProfit = 50 }
function CG.GetMargin() return CG.Pricing.NormalizeMargin(CG.db.minimumProfit) end
function CG.SetMargin(p) CG.db.minimumProfit = CG.Pricing.NormalizeMargin(p); CG.UI.Refresh(true) end

-- No separate floating window, including when /cg is used away from the AH.
CG.UI.Refresh(true)
assert(not CG.UI.panel and not createdFooter, "Outside AH must never create a window")
house:Show()
commodity:Show()
CG.UI.Refresh(true)
assert(createdFooter == CG.UI.panel, "Should construct embedded footer")
assert(createdFooter.parent == house, "Footer must be a CHILD OF AuctionHouseFrame")
assert(createdFooter.height == 180, "Expected compact 180px footer")
assert(createdFooter:IsShown(), "Should show on the active Sell tab")
assert(list:GetNumPoints() == 3 and list.points[3][5] == 188, "Native results list must shrink to reserve footer")
assert(CG.UI.status.text:find("SELL ON AH"), "Expected sell recommendation")
assert(CG.UI.rows.net.text == "1g 90s 00c", "Expected net after 5% cut")

price = 9000
CG.UI.Refresh(false)
assert(CG.UI.status.text:find("VENDOR PAYS MORE"), "Expected loss warning")
price = 20000
CG.UI.slider:SetValue(100)
assert(CG.db.minimumProfit == 100, "Slider should change saved target")
assert(CG.UI.status.text:find("BELOW YOUR 100%% TARGET"), "Expected below-target state")
CG.UI.reset.scripts.OnClick()
assert(CG.db.minimumProfit == 50, "Reset should restore 50%")
CG.db.enabled = false
CG.UI.Refresh(true)
assert(not createdFooter:IsShown(), "Disabled footer should hide")
assert(list:GetNumPoints() == #before, "Must restore original native anchors when hidden")
for i=1,#before do
    local a,b = list.points[i],before[i]
    for n=1,5 do assert(a[n]==b[n],"Original Auction House anchor must be preserved") end
end

CG.db.enabled = true
CG.UI.Refresh(true)
assert(list.points[3][5] == 188, "Reenable must redock")
commodity:Hide()
regular:Hide() -- AH Buy tab
CG.UI.Refresh(true)
assert(not createdFooter:IsShown(), "Footer must disappear outside Sell tab")
assert(list.points[3][5] == 0, "Buy tab must restore results anchors")

regular:Show() -- Regular item Sell form
CG.UI.Refresh(true)
assert(createdFooter:IsShown(), "Must show again on item Sell form")
assert(CG.UI.rows.net.text == "1g 90s 00c")
assert(list.points[3][5] == 188, "Must redock on tab change")
house:Hide() -- Auction House closed
CG.UI.Refresh(true)
assert(not createdFooter:IsShown(), "No floating footer after AH closes")
assert(list.points[3][5] == 0, "Must restore original list layout on close")
print("PASS: inline AH Sell footer, item/commodity, warnings, slider, tab transitions, anchor restoration")
