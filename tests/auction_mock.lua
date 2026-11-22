-- WoW Forever C_AuctionHouse-form reader tests, using deterministic game mocks.
local CG = {}
local location = { IsValid = function() return true end }
local available = false
local mode = "commodity"
local price = 20000
local count = 3
local unitVendor = 10000
local buyout = 0
local item = location

C_Item = {
    GetItemLink = function(value) assert(value == location); return "|Hitem:123|h[Sample Cloth]|h" end,
    GetItemInfo = function(link)
        assert(link == "|Hitem:123|h[Sample Cloth]|h")
        return "Sample Cloth", link, 1, 1, 1, "Trade Goods", "Cloth", 20, "", 0, unitVendor
    end,
}
AuctionHouseFrame = {
    IsShown = function() return available end,
    IsListingAuctions = function() return mode ~= "browse" end,
    CommoditiesSellFrame = {
        IsShown = function() return mode == "commodity" end,
        GetItem = function() return item end,
        GetQuantity = function() return count end,
        GetUnitPrice = function() return price end,
        GetDepositAmount = function() return 500 end,
    },
    ItemSellFrame = {
        IsShown = function() return mode == "item" end,
        GetItem = function() return item end,
        GetQuantity = function() return count end,
        GetPrice = function() return 80, buyout end,
        GetDepositAmount = function() return 600 end,
    },
}
assert(loadfile("addon/Auction.lua"))("CoinGuardian", CG)
local function eq(a,b) assert(a==b, tostring(a) .. " ~= " .. tostring(b)) end
local context, state = CG.Auction.GetContext()
eq(context, nil); eq(state, "closed")
available = true
context,state = CG.Auction.GetContext()
eq(state, "ready")
eq(context.isCommodity, true)
eq(context.name, "Sample Cloth")
eq(context.vendorEach, 10000)
eq(context.quantity, 3)
eq(context.priceEach, 20000)
eq(context.deposit, 500)
mode = "item"
buyout = 50000
context,state = CG.Auction.GetContext()
eq(state, "ready")
eq(context.isCommodity, false)
eq(context.priceEach, 50000)
eq(context.deposit, 600)
buyout = nil
context,state = CG.Auction.GetContext()
eq(context.priceEach, nil) -- Bid-only is never assumed to be buyout.
item = nil
context,state = CG.Auction.GetContext()
eq(context.empty,true)
mode = "browse"
context,state = CG.Auction.GetContext()
eq(context,nil);eq(state,"browse")
print("PASS: Coin Guardian modern Forever selling-frame reader mocks")
