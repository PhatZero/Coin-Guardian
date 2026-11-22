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
