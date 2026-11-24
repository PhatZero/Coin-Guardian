-- Coin Guardian: lightweight, LibDBIcon-free minimap button for WoW Forever.
-- The icon's center follows the minimap rim; the drag stores an ANGLE, not pixels.
local _, CG = ...
CG.Minimap = {}
local M = CG.Minimap
local cos, sin, abs, max, min, pi = math.cos, math.sin, math.abs, math.max, math.min, math.pi
local DEFAULT_ANGLE = 225

-- EllesmereUI's minimap module collects named button children, takes ownership
-- of placement (including reparenting to its flyout), and controls visibility.
-- Do not fight that management. A disabled Ellesmere minimap module leaves us
-- in standalone mode.
function M.IsExternallyManaged()
    local ui = _G.EllesmereUI
    if type(ui) ~= "table" or type(ui._ModuleNS) ~= "table" then return false end
    local module = ui._ModuleNS.EllesmereUIMinimap
    if type(module) ~= "table" then return false end
    local internals = module._internals
    local handler = type(internals) == "table" and internals.EBS
    local settings = type(handler) == "table" and handler.db
    local profile = type(settings) == "table" and settings.profile
    local minimapSettings = type(profile) == "table" and profile.minimap
    if type(minimapSettings) == "table" and minimapSettings.enabled == false then
        return false
    end
    return true
end

local function isOwnedByOtherFrame()
    return M.button and M.button.GetParent and M.button:GetParent() ~= Minimap
end

local function validNumber(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function normalizeAngle(value)
    if not validNumber(value) then return DEFAULT_ANGLE end
    return value % 360
end

local function geometry()
    if not Minimap then return nil end
    local width, height = Minimap:GetWidth(), Minimap:GetHeight()
    if not validNumber(width) or width < 40 then width = 140 end
    if not validNumber(height) or height < 40 then height = 140 end
    local shape = "ROUND"
    if type(GetMinimapShape) == "function" then
        local ok, result = pcall(GetMinimapShape)
        if ok and type(result) == "string" and result ~= "" then shape = result end
    end
    return width, height, shape
end

local function atan2(y, x)
    if math.atan2 then return math.atan2(y, x) end
    if x > 0 then return math.atan(y / x) end
    if x < 0 and y >= 0 then return math.atan(y / x) + pi end
    if x < 0 and y < 0 then return math.atan(y / x) - pi end
    if y > 0 then return pi / 2 end
    if y < 0 then return -pi / 2 end
    return 0
end

-- For default ROUND use circle geometry. For square minimaps intersect a ray
-- with the square edge. +7 makes the gold coin straddle the actual minimap rim.
function M.OffsetForAngle(angle, width, height, shape)
    angle = math.rad(normalizeAngle(angle))
    local dx, dy = cos(angle), sin(angle)
    local radiusX = width / 2 + 7
    local radiusY = height / 2 + 7
    if shape == "SQUARE" then
        local radius = min(radiusX / max(abs(dx), 0.001), radiusY / max(abs(dy), 0.001))
        return dx * radius, dy * radius
    end
    -- The standard Forever minimap is circular; using both radii also supports
    -- resize/scale changes without hard-coded 80px positioning.
    return dx * radiusX, dy * radiusY
end

function M.Reposition()
    if not M.button or not CG.db or M.IsExternallyManaged() or isOwnedByOtherFrame() then return end
    local width, height, shape = geometry()
    if not width then return end
    local angle = normalizeAngle(CG.db.minimapAngle)
    local x, y = M.OffsetForAngle(angle, width, height, shape)
    M.button:ClearAllPoints()
    M.button:SetPoint("CENTER", Minimap, "CENTER", x, y)
    M.lastWidth, M.lastHeight, M.lastShape = width, height, shape
end

function M.Refresh()
    if not CG.db then return end
    if not M.button then M.Create() end
    if not M.button then return end
    local wanted = CG.db.minimapVisible ~= false
    -- Never call SetShown repeatedly: EllesmereUI hides/minimizes collected
    -- buttons and tracks Show/Hide. Reasserting Show every tick breaks its flyout.
    if M.lastRequestedVisibility ~= wanted then
        M.lastRequestedVisibility = wanted
        M.button:SetShown(wanted)
    end
    if M.IsExternallyManaged() or isOwnedByOtherFrame() then
        M.lastWidth, M.lastHeight, M.lastShape = nil, nil, nil
        return
    end
    local width, height, shape = geometry()
    if width ~= M.lastWidth or height ~= M.lastHeight or shape ~= M.lastShape then
        M.Reposition()
    end
end

function M.UpdateDrag()
    if not M.button or not CG.db or not Minimap then return end
    if M.IsExternallyManaged() or isOwnedByOtherFrame() then return end
    if type(InCombatLockdown) == "function" and InCombatLockdown() then return end
    if type(GetCursorPosition) ~= "function" then return end
    local scale = Minimap:GetEffectiveScale()
    if not validNumber(scale) or scale <= 0 then return end
    local cursorX, cursorY = GetCursorPosition()
    local midX, midY = Minimap:GetCenter()
    if not (validNumber(cursorX) and validNumber(cursorY)
        and validNumber(midX) and validNumber(midY)) then return end
    local angle = math.deg(atan2(cursorY / scale - midY, cursorX / scale - midX))
    CG.db.minimapAngle = normalizeAngle(angle)
    M.Reposition()
end

function M.Create()
    if M.button or not Minimap or not CG.db then return end
    if CG.db.minimapVisible == nil then CG.db.minimapVisible = true end
    CG.db.minimapAngle = normalizeAngle(CG.db.minimapAngle)

    local button = CreateFrame("Button", "CoinGuardianMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 8)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local ring = button:CreateTexture(nil, "BACKGROUND")
    ring:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    ring:SetSize(54, 54)
    ring:SetPoint("CENTER", button, "CENTER", 0, 0)

    local coin = button:CreateTexture(nil, "ARTWORK")
    coin:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    coin:SetSize(22, 22)
    coin:SetPoint("CENTER", button, "CENTER", -1, 1)
    -- Gives EllesmereUI and other collectors an unambiguous primary icon.
    button.icon = coin

    local shield = button:CreateTexture(nil, "OVERLAY")
    shield:SetTexture("Interface\\Icons\\INV_Shield_06")
    shield:SetSize(12, 12)
    shield:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "RightButton" then
            if CG.OpenSettings then CG.OpenSettings() end
        elseif CG.TogglePanel then
            CG.TogglePanel()
        end
    end)
    button:SetScript("OnDragStart", function(self)
        if M.IsExternallyManaged() or isOwnedByOtherFrame() then return end
        if type(InCombatLockdown) == "function" and InCombatLockdown() then return end
        self:SetScript("OnUpdate", function() M.UpdateDrag() end)
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        M.Reposition()
    end)
    button:SetScript("OnHide", function(self) self:SetScript("OnUpdate", nil) end)
    button:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("Coin Guardian  |cffffd76a" .. (CG.version or "") .. "|r", 1, 0.83, 0.45)
        local threshold = CG.GetMargin and CG.GetMargin() or 50
        GameTooltip:AddLine("Minimum net profit: " .. threshold .. "% above vendor", 0.9, 0.9, 0.8)
        GameTooltip:AddLine("Left-click: Toggle panel on AH Sell tab", 0.8, 0.9, 0.8)
        GameTooltip:AddLine("Right-click: Profit slider on AH Sell tab", 0.8, 0.9, 0.8)
        if M.IsExternallyManaged() or isOwnedByOtherFrame() then
            GameTooltip:AddLine("Button position managed by EllesmereUI", 0.8, 0.9, 0.8)
        else
            GameTooltip:AddLine("Drag: Move along the minimap edge", 0.8, 0.9, 0.8)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        if GameTooltip then GameTooltip:Hide() end
    end)
    M.button = button
    M.Reposition()
    M.Refresh()
end
