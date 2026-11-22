# Coin Guardian

**Protect Your Gold. Maximize Your Profits.**

Coin Guardian is a standalone Auction House decision-support addon being developed for **World of Warcraft: Forever**.

> **Status: repository/bootstrap only.** The in-game addon is not implemented or ready to release. Automated publication is intentionally gated.

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

This repository is currently **infrastructure only**. Gameplay code will be added under `addon/` after verifying the Forever client APIs. Its manifest will be `addon/CoinGuardian.toc` and must list every loaded Lua/XML file.

| Path | Purpose |
| --- | --- |
| `addon/` | Installable addon source (not yet implemented) |
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