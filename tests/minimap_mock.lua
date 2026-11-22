-- WoW Forever minimap-edge behavior regression tests (Lua 5.1).
local CG = { version = "0.1.1-alpha", db = { minimapAngle = 225, minimapVisible = true } }
local width, height = 140, 140
local shape = "ROUND"
local cursorX, cursorY = 500, 500
local clickCount, settingsCount = 0, 0
function CG.TogglePanel() clickCount = clickCount + 1 end
function CG.OpenSettings() settingsCount = settingsCount + 1 end
function CG.GetMargin() return 50 end

function GetMinimapShape() return shape end
function GetCursorPosition() return cursorX, cursorY end
function InCombatLockdown() return false end

Minimap = {
    GetWidth = function() return width end,
    GetHeight = function() return height end,
    GetCenter = function() return 500, 500 end,
    GetEffectiveScale = function() return 1 end,
    GetFrameLevel = function() return 2 end,
}
local created
function CreateFrame(kind, name, parent)
    assert(kind == "Button")
    assert(name == "CoinGuardianMinimapButton")
    assert(parent == Minimap)
    local button = { scripts = {}, shown = true, position = {} }
    function button:SetSize(w, h) self.width, self.height = w, h end
    function button:SetFrameStrata(value) self.strata = value end
    function button:SetFrameLevel(value) self.level = value end
    function button:EnableMouse(value) self.enabled = value end
    function button:RegisterForClicks(...) self.clicks = { ... } end
    function button:RegisterForDrag(...) self.drags = { ... } end
    function button:CreateTexture()
        local texture = {}
        function texture:SetTexture(value) self.texture = value end
        function texture:SetSize(...) end
        function texture:SetPoint(...) end
        return texture
    end
    function button:SetScript(event, fn) self.scripts[event] = fn end
    function button:ClearAllPoints() self.position = {} end
    function button:SetPoint(point, relative, relativePoint, x, y)
        self.position = { point, relative, relativePoint, x, y }
    end
    function button:SetShown(shown) self.shown = shown end
    created = button
    return button
end

GameTooltip = {
    lines = {},
    SetOwner = function() end,
    SetText = function(self, text) self.text = text end,
    AddLine = function(self, text) table.insert(self.lines, text) end,
    Show = function() end,
    Hide = function() end,
}

assert(loadfile("addon/Minimap.lua"))("CoinGuardian", CG)
local M = CG.Minimap
local function near(actual, expected, tolerance, label)
    assert(math.abs(actual - expected) < tolerance, (label or "value") ..
        ": expected " .. expected .. ", got " .. tostring(actual))
end

M.Create()
assert(M.button == created, "Minimap button not created")
assert(created.width == 32 and created.height == 32, "Expected a compact minimap icon")
assert(CG.db.minimapAngle == 225, "Existing angle not preserved")
local x, y = created.position[4], created.position[5]
near(math.sqrt(x*x + y*y), 77, 0.01, "Round minimap radius")
assert(x < 0 and y < 0, "Default should be at lower-left rim")
assert(created.position[2] == Minimap, "Icon must anchor to the minimap itself")
assert(created.clicks[1] == "LeftButtonUp" and created.clicks[2] == "RightButtonUp")

created.scripts.OnClick(created, "LeftButton")
created.scripts.OnClick(created, "RightButton")
assert(clickCount == 1 and settingsCount == 1, "Minimap click bindings failed")
created.scripts.OnEnter(created)
assert(GameTooltip.text:find("Coin Guardian"), "Tooltip missing addon name")
assert(table.concat(GameTooltip.lines, " "):find("50%%"), "Tooltip missing margin")

width, height = 180, 180
M.Refresh()
x, y = created.position[4], created.position[5]
near(math.sqrt(x*x + y*y), 97, 0.01, "Resized round minimap")

cursorX, cursorY = 700, 500
created.scripts.OnDragStart(created)
assert(type(created.scripts.OnUpdate) == "function", "Drag handler missing")
created.scripts.OnUpdate(created)
near(CG.db.minimapAngle, 0, 0.01, "Drag angle east")
near(created.position[4], 97, 0.01, "Dragged icon remains on rim")
near(created.position[5], 0, 0.01, "Dragged icon angle alignment")
created.scripts.OnDragStop(created)
assert(created.scripts.OnUpdate == nil, "Drag OnUpdate not cleared")

shape = "SQUARE"
CG.db.minimapAngle = 45
M.Refresh()
x, y = created.position[4], created.position[5]
near(x, 97, 0.01, "Square rim x")
near(y, 97, 0.01, "Square rim y")

CG.db.minimapVisible = false
M.Refresh()
assert(not created.shown, "Saved hide preference not applied")
CG.db.minimapVisible = true
M.Refresh()
assert(created.shown, "Saved show preference not applied")

-- Recreating the icon after a mock /reload uses the saved ANGLE.
local savedAngle = CG.db.minimapAngle
M.button = nil
M.Create()
assert(CG.db.minimapAngle == savedAngle, "Reload should keep selected angle")
near(M.button.position[4], 97, 0.01, "Reload preserves square-rim x")
near(M.button.position[5], 97, 0.01, "Reload preserves square-rim y")
print("PASS: round and square edge anchoring, drag, UI scale geometry, saves, clicks, tooltip")
