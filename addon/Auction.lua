-- WoW Forever 1.60.1 uses the modern C_AuctionHouse posting interface.
-- This module only reads native posting controls; it never posts or changes prices.
local _, CG = ...
CG.Auction = {}
local Auction = CG.Auction

local function safely(object, method, ...)
    if not object or type(object[method]) ~= "function" then return nil end
    local ok, value = pcall(object[method], object, ...)
    if ok then return value end
    return nil
end

local function readVendor(itemLocation)
    if not C_Item or type(C_Item.GetItemInfo) ~= "function" then return nil, nil end
    local link
    if type(C_Item.GetItemLink) == "function" then
        local ok, value = pcall(C_Item.GetItemLink, itemLocation)
        if ok then link = value end
    end
    if not link and type(C_Item.GetItemID) == "function" then
        local ok, value = pcall(C_Item.GetItemID, itemLocation)
        if ok then link = value end
    end
    if not link then return nil, nil end
    local ok, name, vendor = pcall(function()
        local itemName = C_Item.GetItemInfo(link)
        local vendorValue = select(11, C_Item.GetItemInfo(link))
        return itemName, vendorValue
    end)
    if not ok then return nil, nil end
    return name, vendor
end

function Auction.GetContext()
    local house = _G.AuctionHouseFrame
    if not house or not house.IsShown or not house:IsShown() then
        return nil, "closed"
    end
    if not house.IsListingAuctions or not safely(house, "IsListingAuctions") then
        return nil, "browse"
    end
    local commodity = house.CommoditiesSellFrame
    local item = house.ItemSellFrame
    local sell, isCommodity
    if commodity and commodity.IsShown and commodity:IsShown() then
        sell, isCommodity = commodity, true
    elseif item and item.IsShown and item:IsShown() then
        sell, isCommodity = item, false
    else
        return nil, "browse"
    end
    local location = safely(sell, "GetItem")
    if not location then return { empty = true }, "empty" end
    if type(location.IsValid) == "function" and not safely(location, "IsValid") then
        return { empty = true }, "empty"
    end
    local quantity = safely(sell, "GetQuantity")
    local priceEach
    if isCommodity then
        priceEach = safely(sell, "GetUnitPrice")
    elseif type(sell.GetPrice) == "function" then
        local ok, _, buyout = pcall(sell.GetPrice, sell)
        if ok then priceEach = buyout end -- A bid is not a guaranteed sale.
    end
    local deposit = safely(sell, "GetDepositAmount")
    local name, vendorEach = readVendor(location)
    return {
        item = location,
        name = name or "Selected item",
        vendorEach = vendorEach,
        quantity = quantity,
        priceEach = priceEach,
        deposit = deposit,
        isCommodity = isCommodity,
    }, "ready"
end
