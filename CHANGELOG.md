# Coin Guardian changelog

## Unreleased

- Initialized the Coin Guardian GitHub repository.
- Added packaging validation and continuous integration scaffolding.
- Added gated GitHub release and CurseForge upload workflows.
- Documented the intended 5% AH commission, vendor comparison, and adjustable profit target.

No in-game addon has been released.

## 0.1.0-alpha (local QA only)

- Added a WoW Forever 1.60.1 addon with read-only Auction House Sell-tab integration.
- Supports both commodities and item listings using the modern sell controls.
- Shows price, 5% cut, net proceeds, vendor comparison, profit, minimum asking price, and deposit.
- Warns when a vendor pays more, and only recommends AH when the net profit threshold is met.
- Added a saved 0–200% minimum-profit slider, default 50%, and a reset button.
- Added slash commands `/cg`, `/cg margin`, `/cg reset`, `/cg show`, `/cg hide`, and `/cg status`.
- Added Lua mock tests and Python packaging tests.

This is not a public release. In-game QA is still required.

## 0.1.1-alpha (local QA only)

- Added a gold coin and shield button on the round minimap's outer rim.
- Added edge-constrained dragging and saved position across `/reload`.
- Preserves the ring position during minimap resizes and handles square minimap layouts.
- Left-click opens or closes Coin Guardian; right-click opens the profit settings.
- Added a tooltip with the current minimum profit requirement.
- Added `/cg minimap show`, `hide`, and `reset` commands.
- Added Lua 5.1 regression tests for minimap positioning, dragging, and persistence.

This build is for local in-game QA only.
