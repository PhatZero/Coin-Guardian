-- Coin Guardian: independent copper-precise AH profit calculator (WoW Lua 5.1).
local _, CG = ...
CG.Pricing = {}
local Pricing = CG.Pricing
local floor, ceil = math.floor, math.ceil

local function validAmount(value)
    return type(value) == "number" and value == value and value >= 0
        and value < math.huge and floor(value) == value
end

Pricing.IsCopper = validAmount

function Pricing.NormalizeMargin(value)
    value = tonumber(value) or 50
    if value ~= value or value == math.huge or value == -math.huge then value = 50 end
    return math.min(200, math.max(0, floor(value / 5 + 0.5) * 5))
end

-- All values are integers in copper. Price is PER UNIT on both Forever sell frames.
function Pricing.Evaluate(vendorEach, quantity, priceEach, minimumPercent, deposit)
    local result = { state = "unavailable", minimumPercent = Pricing.NormalizeMargin(minimumPercent) }
    if not validAmount(quantity) or quantity < 1 then
        result.reason = "Choose a valid quantity."
        return result
    end
    result.quantity = quantity
    if not validAmount(priceEach) or priceEach == 0 then
        result.reason = "Enter an Auction House buyout price."
        return result
    end
    result.priceEach = priceEach
    result.gross = quantity * priceEach
    if not validAmount(result.gross) then
        result.reason = "The asking price is not valid."
        return result
    end
    result.cut = floor(result.gross * 5 / 100)
    result.net = result.gross - result.cut
    if validAmount(deposit) then result.deposit = deposit end
    if not validAmount(vendorEach) then
        result.reason = "Waiting for the item's vendor value."
        return result
    end
    result.vendorEach = vendorEach
    result.vendor = vendorEach * quantity
    result.profit = result.net - result.vendor
    if result.vendor == 0 then
        result.state = "zero_vendor"
        result.reason = "The vendor pays nothing; a percentage comparison is not possible."
        return result
    end
    result.profitPercent = (result.profit / result.vendor) * 100
    -- Conservative target. Exact required net is enforced without rounding error.
    result.minimumGross = ceil((result.vendor * (100 + result.minimumPercent)) / 95)
    if result.net < result.vendor then
        result.state = "loss"
        result.reason = "Selling to a vendor pays more than this auction."
    elseif result.net * 100 >= result.vendor * (100 + result.minimumPercent) then
        result.state = "sell"
        result.reason = "Net Auction House proceeds meet your profit target."
    else
        result.state = "below_target"
        result.reason = "The auction earns more than a vendor, but misses your profit target."
    end
    return result
end

function Pricing.CoinText(amount)
    if type(amount) ~= "number" or not validAmount(math.abs(amount)) then return "--" end
    local n = math.abs(amount)
    local sign = amount < 0 and "-" or ""
    local gold = floor(n / 10000)
    local silver = floor(n % 10000 / 100)
    local copper = n % 100
    return string.format("%s%dg %02ds %02dc", sign, gold, silver, copper)
end
