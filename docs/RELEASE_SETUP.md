# Coin Guardian: Release Infrastructure

## Repository

- Repository: `PhatZero/Coin-Guardian`, default branch `main`.
- Ordinary pushes to `main` and pull requests run **Validate Coin Guardian**.
- Do not publish a release before verifying the Lua addon and WoW Forever UI inside the game.
- Production packages use a single root directory: `CoinGuardian/`.

## First addon implementation

1. Add `addon/CoinGuardian.toc` with the Forever interface value confirmed against the installed game client.
2. Put Lua and optional XML/textures under `addon/`, with ordered references in the TOC.
3. Validate with `python3 -m unittest discover -s tests -v` and `python3 scripts/build.py`.
4. Run in-game tests for protected actions, data availability, price math, saved slider state, and UI errors.

## GitHub release

1. Update the TOC `## Version:` to a version such as `1.0b1`.
2. Review and merge the release changes.
3. Create an explicit tag `forever-1.0b1` **on that commit**.
4. The GitHub Actions `release.yml` job validates the manifest and tests, syntax-checks Lua 5.1, packages the ZIP, and creates a GitHub release. A tag alone is never enough if addon source is missing.

## CurseForge release (separate, intentional action)

1. Create the **Coin Guardian** project on CurseForge and wait for its approval.
2. In GitHub repository settings, set Actions secret `CURSEFORGE_TOKEN` to your CurseForge API token. Never commit the token.
3. Set Actions variable `CURSEFORGE_PROJECT_ID` to **Coin Guardian's** numeric CurseForge project ID.
4. In GitHub Actions select **Publish Coin Guardian to CurseForge**, click Run workflow, and enter the **existing** release tag (for example `forever-1.0b1`).
5. This uploads the exact tested ZIP from that GitHub release, with Markdown release notes, using the Forever game version.

Do not reuse Food Guardian's CurseForge project ID. No routine commit, PR, or GitHub release automatically uploads to CurseForge; only the explicit publishing action does.

## Important limitations

- The connected GitHub integration cannot configure account secrets, variables, or branch protection directly. These require GitHub repository settings.
- Interface `16001`, game version `1.60.1`, and the CurseForge version lookup are based on the existing Food Guardian pipeline and must be confirmed in the target Forever environment.
