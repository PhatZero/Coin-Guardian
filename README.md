# Coin Guardian

**Protect Your Gold. Maximize Your Profits.**

Coin Guardian is a standalone Auction House decision-support addon being developed for **World of Warcraft: Forever**.

> **Status: local QA build 0.1.0-alpha.** Core features are implemented, but they still require actual WoW Forever in-game acceptance testing. No public release has been made. Automated publication is intentionally gated.

## Planned features

- Compare expected Auction House proceeds to the **same item's vendor value for the same quantity**.
- Deduct the **5% Auction House commission** from the listing price.
- Recommend selling on the AH only when the net amount exceeds vendor value by the configured minimum, **50% by default**.
- Give a clear warning when the AH would return **less gold than an NPC vendor**.
- Show gross AH price, 5% cut, net proceeds, vendor price, absolute profit over vendor, profit percentage, and any available deposit.
- Let players change their required profit using an in-game slider, with saved preferences and a reset to 50%.
- Avoid divide-by-zero errors, handle copper and stack quantities correctly, and show an unknown state when an authoritative price is unavailable.
- Never automatically post auctions or promise a listed item will sell.

## Development

The first local QA implementation reads the modern Forever `AuctionHouseFrame` sell forms without hooking protected post actions. It includes a profit calculator, read-only panel, and persisted margin slider. Its manifest will be `addon/CoinGuardian.toc` and must list every loaded Lua/XML file.

| Path | Purpose |
| --- | --- |
| `addon/` | Installable addon source (`Pricing.lua`, `Auction.lua`, `UI.lua`, `Core.lua`) |
| `docs/FEATURE_SPEC.md` | Rules, calculations, and acceptance criteria |
| `docs/RELEASE_SETUP.md` | GitHub and CurseForge setup |
| `scripts/build.py` | Validate and create a clean installable ZIP |
| `scripts/upload-forever.sh` | Upload an existing tested ZIP to CurseForge |
| `tests/` | Packaging tests |
| `.github/workflows/` | Validation, GitHub release, and manual CurseForge publishing |

## Releases

- Target: WoW Forever, presently using interface `16001` based on Food Guardian. **Confirm it in the installed Forever client before the first release.**
- Package root: `CoinGuardian/`, containing `CoinGuardian.toc` and addon assets.
- Example ZIP: `CoinGuardian-Forever-1.0b1.zip`.
- Example tag: `forever-1.0b1`, followed by `forever-1.0b2`, eventually `forever-1.0.0`.
- CI runs on pull requests and main. Neither ordinary commits nor regular PR merges publish an addon.
- A matching `forever-*` tag triggers tested **GitHub release packaging**. CurseForge publishing is a **separate manual workflow** that uploads the already-tested release, and needs a Coin Guardian-specific CurseForge project ID and API token.

**Do not reuse the Food Guardian CurseForge project ID.**
## Install the local QA ZIP

1. Extract `CoinGuardian-Forever-0.1.0-alpha.zip` into `World of Warcraft/_forever_/Interface/AddOns/`.
2. Confirm the path is `Interface/AddOns/CoinGuardian/CoinGuardian.toc`.
3. Fully restart WoW Forever, enable Coin Guardian on the AddOns screen, and visit an Auction House.
4. Open the Sell tab and select an item. Coin Guardian appears alongside the native sell form and updates when quantity/asking price changes.
5. Drag the 0%–200% slider (5% increments), then `/reload` to verify settings persist.

The panel only reads the selling form. It never posts auctions or blocks Blizzard's Post button. Use `/cg status`, `/cg show`, `/cg hide`, `/cg margin 75`, `/cg reset`, or `/cg` (panel toggle while at the AH; preview elsewhere).

**Please report:** which sell tab was used (item or commodity), the item's vendor value, stack count, asking price, whether the panel updated, and any Lua/taint errors.

## Minimap button (local QA 0.1.1-alpha)

Coin Guardian adds a gold-coin button with a small shield on the edge of the round minimap. It is anchored to the minimap itself, not to the screen, and automatically recalculates its position when the minimap changes size or shape. Dragging the button slides it around the rim, and its angle is saved across logins and `/reload`.

- **Left-click:** Toggle Coin Guardian's panel (including preview mode away from auctioneers).
- **Right-click:** Open the profit panel/settings from anywhere.
- **Drag:** Reposition along the minimap edge.
- **Hover:** Show the addon name, margin setting, and mouse controls.
- **Commands:** `/cg minimap hide`, `/cg minimap show`, `/cg minimap reset`.

No Github release or CurseForge publishing is performed for local alpha builds.

## 0.1.2-alpha: embedded in the Auction House Sell tab

Coin Guardian no longer creates a separate floating panel. Visit an auctioneer and open the normal **Sell** tab. The gold-colored Coin Guardian footer lives **inside the right-hand side** of that tab, beneath the shortened native listings area. The original Post button and pricing controls remain unchanged. Switching to Buy or closing the Auction House hides the footer and restores the original listing area. The 50% profit-target slider is also in this embedded section.

- Minimap left-click toggles the footer while on Sell. Minimap right-click restores the footer/settings there.
- Away from the Auction House, the minimap button and `/cg` show a chat hint instead of opening a new window.
- This is still **local QA only**. No tag, release, or CurseForge upload has been made.

## 0.1.3-alpha: EllesmereUI minimap compatibility

If you use **EllesmereUI's minimap addon flyout**, it now controls the position and appearance of Coin Guardian's minimap button. Coin Guardian does not fight the flyout by repeatedly showing the button or snapping it back to the map rim. In EllesmereUI, use its addon-button grouping or ungrouping controls to choose where the Coin Guardian icon appears.

Without an active EllesmereUI minimap manager, Coin Guardian keeps its normal gold coin/shield button on the **outer rim of the round minimap**, with draggable saved angle.

The existing `/cg minimap show`, `hide`, and `reset` commands still work; `reset` changes Coin Guardian's standalone position and will not override EllesmereUI's managed row or flyout. The profit calculator remains inside the Auction House **Sell tab**.

**Local QA:** Test entering the world, opening/closing EllesmereUI's addon flyout, navigating the AH, dragging in standalone mode, reloading, and disabling EllesmereUI's minimap module.
