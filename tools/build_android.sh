#!/bin/bash
# Build the signed release APK and publish it where the in-game updater looks (game/build/web/app/):
#   https://willems-macbook-pro.tail868144.ts.net:8443/app/guardians.apk   (first install: open this on the phone)
#   https://willems-macbook-pro.tail868144.ts.net:8443/app/version.json    (what the installed app checks)
# Needs Godot 4.7 with its export templates, the Android SDK + JDK 17 in Godot's editor settings and the release
# keystore in server-mac/secrets (never committed; back it up: updates must be signed with the same key).
# The build number is minutes since 1970 (Android only accepts a higher one), so builds must be a minute apart.
set -e
cd "$(dirname "$0")/.."
. server-mac/secrets/android.env
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH GODOT_ANDROID_KEYSTORE_RELEASE_USER GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
# the gradle template (game/android/build) is committed except its 200 MB of engine libraries: restore those from the export templates
[ -f game/android/build/libs/release/godot-lib.template_release.aar ] || unzip -q -o "$HOME/Library/Application Support/Godot/export_templates/4.7.2.stable/android_source.zip" 'libs/*' -d game/android/build
godot --headless --path game --script res://tests/run_tests.gd | tail -2
godot --headless --path game --import >/dev/null 2>&1 || true
CODE=$(( $(date +%s) / 60 ))
NAME=$(grep '^version/name=' game/export_presets.cfg | tail -1 | cut -d'"' -f2)
printf '{"code": %d, "name": "%s"}\n' "$CODE" "$NAME" > game/build_info.json
BACKUP=$(mktemp)
cp game/export_presets.cfg "$BACKUP"
trap 'cp "$BACKUP" game/export_presets.cfg; rm -f "$BACKUP"' EXIT
sed -i '' "s/^version\/code=.*/version\/code=$CODE/" game/export_presets.cfg
mkdir -p game/build/android game/build/web/app
godot --headless --path game --export-release Android build/android/guardians.apk
cp game/build/android/guardians.apk game/build/web/app/guardians.apk.part
mv game/build/web/app/guardians.apk.part game/build/web/app/guardians.apk  # (a phone downloading right now never sees half a file)
python3 -I - <<'PY'
import hashlib, json, os
info = json.load(open("game/build_info.json"))
apk = open("game/build/web/app/guardians.apk", "rb").read()
info.update({"apk": "guardians.apk", "sha256": hashlib.sha256(apk).hexdigest(), "size": len(apk)})
json.dump(info, open("game/build/web/app/version.json.part", "w"))
os.replace("game/build/web/app/version.json.part", "game/build/web/app/version.json")
print("Published build %d (%s), %.1f MB" % (info["code"], info["name"], info["size"] / 1048576))
PY
