#!/usr/bin/env bash
# build.sh — creates a ready-to-import Power Platform solution ZIP
# Usage: ./build.sh
# Output: dist/QldCoachFinder.zip  (schema-only, no PAC CLI required)
#         dist/QldCoachFinder_Full.zip  (schema + canvas app, requires PAC CLI)

set -e
ROOT="$(cd "$(dirname "$0")" && pwd)"
DIST="$ROOT/dist"
TMP="$DIST/tmp_schema"

echo "==> Cleaning dist/"
rm -rf "$DIST"
mkdir -p "$TMP"

# ── Schema-only ZIP (importable without PAC CLI) ──────────────────────────────
echo "==> Copying solution manifest files to ZIP root..."
cp "$ROOT/solution.xml"           "$TMP/solution.xml"
cp "$ROOT/customizations.xml"     "$TMP/customizations.xml"
cp "$ROOT/[Content_Types].xml"    "$TMP/[Content_Types].xml"

echo "==> Creating dist/QldCoachFinder.zip ..."
cd "$TMP"
zip -r "$DIST/QldCoachFinder.zip" . -x "*.DS_Store"
cd "$ROOT"
rm -rf "$TMP"
echo "    -> dist/QldCoachFinder.zip  (ready to import into Power Platform)"

# ── Full solution ZIP (requires PAC CLI) ─────────────────────────────────────
if command -v pac &>/dev/null; then
  echo ""
  echo "==> PAC CLI found — building full solution with canvas app..."
  mkdir -p "$DIST/canvas"

  pac canvas pack \
    --sources "$ROOT/CanvasApps/CoachSearchApp_src" \
    --msapp   "$DIST/canvas/qcf_coachsearchapp.msapp"

  FULL_TMP="$DIST/tmp_full"
  mkdir -p "$FULL_TMP/CanvasApps"
  cp "$ROOT/solution.xml"         "$FULL_TMP/solution.xml"
  cp "$ROOT/customizations.xml"   "$FULL_TMP/customizations.xml"
  cp "$ROOT/[Content_Types].xml"  "$FULL_TMP/[Content_Types].xml"
  cp "$DIST/canvas/qcf_coachsearchapp.msapp" \
     "$FULL_TMP/CanvasApps/qcf_coachsearchapp.msapp"

  # Patch solution.xml to re-add canvas app RootComponent
  sed -i 's|<!-- Security Roles -->|<!-- Canvas App -->\n      <RootComponent type="300" schemaName="qcf_coachsearchapp" behavior="0" />\n      <!-- Security Roles -->|' \
    "$FULL_TMP/solution.xml"

  cd "$FULL_TMP"
  zip -r "$DIST/QldCoachFinder_Full.zip" . -x "*.DS_Store"
  cd "$ROOT"
  rm -rf "$FULL_TMP" "$DIST/canvas"
  echo "    -> dist/QldCoachFinder_Full.zip  (schema + canvas app)"
else
  echo ""
  echo "==> PAC CLI not found — skipping full solution build."
  echo "    Install PAC: npm install -g @microsoft/powerplatform-cli"
  echo "    Then re-run this script to also produce QldCoachFinder_Full.zip"
fi

echo ""
echo "Done. Import dist/QldCoachFinder.zip into Power Platform to create"
echo "the Dataverse tables, then build the canvas app in Power Apps Studio."
