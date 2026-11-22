#!/usr/bin/env bash
set -euo pipefail
: "${CURSEFORGE_TOKEN:?Set CURSEFORGE_TOKEN secret}"
: "${CURSEFORGE_PROJECT_ID:?Set CURSEFORGE_PROJECT_ID Actions variable}"
: "${CHANGELOG:?Release notes are required}"
[[ "$CURSEFORGE_PROJECT_ID" =~ ^[1-9][0-9]*$ ]] || { echo 'Invalid CurseForge project ID' >&2; exit 1; }
[[ $# -eq 1 && -f "$1" ]] || { echo 'Expected one tested ZIP' >&2; exit 1; }
archive="$1"
toc=$(unzip -p "$archive" 'CoinGuardian/CoinGuardian.toc' | tr -d '\r')
interface=$(sed -n 's/^## Interface: //p' <<< "$toc")
version=$(sed -n 's/^## Version: //p' <<< "$toc")
[[ "$interface" == '16001' && "$version" =~ ^([0-9]+\.[0-9]+\.[0-9]+|[0-9]+\.[0-9]+b[1-9][0-9]*)$ ]] || { echo 'Unexpected addon manifest' >&2; exit 1; }
api='https://wow.curseforge.com/api'
header="X-Api-Token: $CURSEFORGE_TOKEN"
versions=$(curl --fail-with-body --silent --show-error --header "$header" "$api/game/versions")
version_id=$(jq -er '[.[] | select(.name == "1.60.1")] | if length == 1 and (.[0].id | type) == "number" then .[0].id else error("Expected unique Forever 1.60.1 version") end' <<< "$versions")
release_type='beta'
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && release_type='release'
metadata=$(jq -n --arg notes "$CHANGELOG" --arg version "$version" --arg type "$release_type" --argjson gameid "$version_id" '{changelog:$notes, changelogType:"markdown", releaseType:$type, displayName:("Coin Guardian " + $version + " (Forever)"), gameVersions:[$gameid]}')
response=$(curl --fail-with-body --silent --show-error --header "$header" --form-string "metadata=$metadata" --form "file=@$archive;type=application/zip" "$api/projects/$CURSEFORGE_PROJECT_ID/upload-file")
file_id=$(jq -er '.id | numbers | select(. > 0)' <<< "$response")
echo "Uploaded Coin Guardian $version to CurseForge, file $file_id"
