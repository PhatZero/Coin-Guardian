-- WoW Forever minimap-edge behavior regression tests (Lua 5.1).
local CG = { version = "0.1.3-alpha", db = { minimapAngle = 225, minimapVisible = true } }
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
    local button = { scripts = {}, shown = true, position = {}, parent = parent, setShownCalls = 0, repositionCalls = 0 }
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
    function button:GetParent() return self.parent end
    function button:ClearAllPoints() self.position = {} end
    function button:SetPoint(point, relative, relativePoint, x, y)
        self.repositionCalls = self.repositionCalls + 1
        self.position = { point, relative, relativePoint, x, y }
    end
    function button:SetShown(shown) self.shown = shown; self.setShownCalls = self.setShownCalls + 1 end
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
assert(created.icon ~= nil, "External managers should find the primary coin icon")
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
-- A flyout manager can now claim the same button. Coin Guardian must NEVER
-- force visibility or anchor changes back to Minimap while EUI is managing it.
local button = M.button
local originalShows = button.setShownCalls
for i = 1, 6 do M.Refresh() end
assert(button.setShownCalls == originalShows,
    "Periodic refresh must not call SetShown after initialization")

EllesmereUI = {
    _ModuleNS = {
        EllesmereUIMinimap = {
            _internals = { EBS = { db = { profile = { minimap = { enabled = true } } } } },
        },
    },
}
assert(M.IsExternallyManaged(), "Expected EllesmereUI minimap detection")

local foreignPanel = {}
button.parent = foreignPanel
button.position = { "TOPLEFT", foreignPanel, "TOPLEFT", 13, -23 }
local acquiredPoints = button.repositionCalls
width, height = 280, 280
M.Refresh()
assert(button.repositionCalls == acquiredPoints, "Don't move a button in Ellesmere flyout")
assert(button.position[2] == foreignPanel, "Don't steal icon back to Minimap")
assert(button.setShownCalls == originalShows, "Don't force-show flyout-managed buttons")
button.scripts.OnDragStart(button)
assert(button.scripts.OnUpdate == nil, "Disable native drag while flyout owns button")
button.scripts.OnDragStop(button)
assert(button.repositionCalls == acquiredPoints, "Stopping flyout drag must not reposition")

-- Even an Ellesmere 'ungrouped' button stays on Minimap, but its row layout is
-- controlled by Ellesmere, not by Coin Guardian's own rim geometry.
button.parent = Minimap
button.position = { "TOPRIGHT", Minimap, "TOPRIGHT", -19, -4 }
M.Refresh()
assert(button.repositionCalls == acquiredPoints, "Ellesmere row anchor must remain untouched")
button.scripts.OnEnter(button)
assert(table.concat(GameTooltip.lines, " "):find("EllesmereUI"), "Tooltip must explain ownership")
button.scripts.OnDragStart(button)
assert(button.scripts.OnUpdate == nil, "Native drag must not conflict with row drag")

-- Explicit Coin Guardian preferences still work, but only on state change.
CG.db.minimapVisible = false
M.Refresh()
assert(button.shown == false)
assert(button.setShownCalls == originalShows + 1)
M.Refresh()
assert(button.setShownCalls == originalShows + 1, "No repeated hide calls")
CG.db.minimapVisible = true
M.Refresh()
assert(button.shown == true)
assert(button.setShownCalls == originalShows + 2)
M.Refresh()
assert(button.setShownCalls == originalShows + 2, "No repeated show calls")

-- Switching the Ellesmere minimap module OFF restores Coin Guardian behavior.
EllesmereUI._ModuleNS.EllesmereUIMinimap._internals.EBS.db.profile.minimap.enabled = false
assert(not M.IsExternallyManaged(), "Disabled manager must yield control")
shape = "ROUND"
M.Refresh()
assert(button.repositionCalls == acquiredPoints + 1,
    "Standalone round-rim placement must resume after manager is disabled")
near(math.sqrt(button.position[4]^2 + button.position[5]^2), 147, .01,
    "Rim radius after disable")

-- On login with EUI already loaded, the button gets one sensible rim position
-- until Ellesmere discovers it. Subsequent EUI layout remains authoritative.
EllesmereUI._ModuleNS.EllesmereUIMinimap._internals.EBS.db.profile.minimap.enabled = true
M.button = nil
M.lastRequestedVisibility = nil
M.Create()
assert(M.button.position[2] == Minimap, "New icons must have initial position")
local euiButton = M.button
local euiPositionCount = euiButton.repositionCalls
M.Refresh()
assert(euiButton.repositionCalls == euiPositionCount,
    "Do not reposition after initial Ellesmere handoff")
print("PASS: minimap rim + EllesmereUI flyout compatibility, drag, resize, visibility and state")

