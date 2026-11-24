# Coin Guardian: Initial Feature Specification

## Player goal

Provide a trustworthy recommendation before posting an Auction House listing in WoW Forever. It is a decision aid, not an automated posting tool and not a guarantee an auction will sell.

## Inputs

- Vendor sell price *per item* in copper.
- Quantity/stack count being evaluated.
- Expected **total** Auction House listing price in copper.
- Minimum profit setting (default **50%**, proposed slider from **0% to 200%**, in 5% steps).
- AH deposit amount, when the client can supply it for this listing.
- AH market data only when the supported client API exposes it; never fabricate a current market price.

## Mathematics

Calculate using **integer copper**, not formatted strings.

- `V = vendor_unit_value * quantity`
- `P = AH total asking price`
- `fee = floor(P * 0.05)` (verify the server's exact rounding behavior in-game)
- `net = P - fee`
- `profit = net - V`
- `profit_pct = (profit / V) * 100`, only when `V > 0`
- `required_net = V * (1 + configured_pct / 100)`

The margin compares **net proceeds against selling to an NPC vendor**, not against the gross AH listing.

## Recommendation rules

1. No valid price or price source: show **No reliable price**, not a profit recommendation.
2. `V > 0` and `net < V`: show **Loss versus vendor: sell to vendor**.
3. `V > 0` and `net >= required_net`: show **AH recommended**.
4. `V > 0`, `net >= V`, but below threshold: show **Below profit target: vendor recommended**.
5. `V == 0`: do not divide by zero or show an infinite percentage; display net proceeds and a neutral/explicit zero-vendor status until policy is confirmed.

The deposit is shown separately. Deposits are generally returned when an auction succeeds but can be lost on expiry or cancellation; don't subtract deposits twice from expected proceeds on a successful sale.

## UI

- Compact, native-feeling panel beside the Auction House posting interface.
- Gross price, 5% cut, net, vendor equivalent, difference, percentage, and available deposit.
- Prominent green recommendation or red loss warning, with text as well as color.
- Configurable minimum-profit slider, instantly recomputed, saved across sessions.
- Settings reset to the 50% default.
- No automatic protected actions and no implied support for unsupported Forever APIs.

## Acceptance scenarios

| Vendor total | Auction ask | Cut | Net | Above vendor | Threshold | Recommendation |
| --- | --- | --- | --- | --- | --- | --- |
| 1g | 2g | 10s | 1g 90s | +90% | 50% | AH |
| 1g | 2g | 10s | 1g 90s | +90% | 100% | Vendor / below target |
| 1g | 90s | 4s 50c | 85s 50c | -14.5% | 50% | Warning / vendor |

Also test varying quantities, 0-vendor-value items, no price, rounding, UI slider persistence, expiration deposits, and client compatibility.

## First local QA implementation (0.1.0-alpha)

The Forever client is using the **modern** `C_AuctionHouse` API, `AuctionHouseFrame.CommoditiesSellFrame` and `AuctionHouseFrame.ItemSellFrame` (not Classic `GetAuctionSellItemInfo`). The addon uses `GetUnitPrice()` for commodities and the buyout from `GetPrice()` for items, then applies `GetQuantity()` in both cases. The native `GetDepositAmount()` is displayed separately. Item vendor values are read via `C_Item.GetItemInfo`, when cached. If a listing has only a bid and no buyout, the addon asks for a buyout; it will not assume a winning bid amount.

Implemented for local QA: read-only native AH panel, safe price math, 5% deduction, adjustable saved 50% threshold, warning states, and slash commands. Final visual and API behavior must be checked in-game before public release.

## Minimap navigation enhancement (0.1.1-alpha)

When the addon loads, it creates a 32x32 coin-and-shield button anchored to the minimap center at a radial distance of (minimap radius + 7 UI units). For the standard round minimap, the icon's center straddles the rim rather than drifting inside it. Square maps use a ray-to-edge intersection. Dragging stores an angle in `CoinGuardianDB.minimapAngle`, and a 0.25-second low-cost geometry check updates positions when minimap sizes change.

The button opens the existing profit panel and slider; it does not post auctions or make protected UI changes. `CoinGuardianDB.minimapVisible` controls visibility, with slash commands to show/hide/reset the icon.

## Integrated AH Sell-tab footer (0.1.2-alpha)

The first standalone floating panel did not meet the intended UX. The revised design creates a 180px footer as a direct child of `AuctionHouseFrame`, anchored to the bottom-right space beside the native Sell form. It saves all original `ItemSellList` anchor points, shortens the results list to make room, then restores those anchors when the footer hides, the player changes tabs, or the Auction House closes. The commodity list follows the resized item list's anchors. The original Blizzard Post button is untouched.

The profit breakdown and slider are never shown in a separate window, including when a player clicks the minimap icon away from an auctioneer. In-game QA should confirm the footer has adequate room at different UI scales and does not obscure the item/commodity search list or buttons.

## EllesmereUI addon flyout compatibility (0.1.3-alpha)

EllesmereUIMinimap collects named button children of `Minimap`, hides grouped buttons, and reparents the buttons into its flyout. It also positions ungrouped buttons on a managed row. Coin Guardian must yield ownership when the active Ellesmere minimap module is detected. Position only once when first creating the icon, then never force its anchor or call `SetShown` repeatedly. Do not call the minimap drag updater if a flyout has changed the button's parent or Ellesmere is active. Respect explicit Coin Guardian show/hide preferences, but only on preference transitions. Verify that button collectors can identify `button.icon`.

Native rim dragging remains supported only when no competing manager owns the minimap button. In-game UI verification with EllesmereUI remains required before considering this compatibility issue closed.
