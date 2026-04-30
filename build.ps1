# build.ps1 — creates a ready-to-import Power Platform solution ZIP (Windows)
# Usage: .\build.ps1
# Output: dist\QldCoachFinder.zip  (schema-only, no PAC CLI required)

$Root = $PSScriptRoot
$Dist = Join-Path $Root "dist"
$Tmp  = Join-Path $Dist "tmp_schema"

Write-Host "==> Cleaning dist\" -ForegroundColor Cyan
if (Test-Path $Dist) { Remove-Item $Dist -Recurse -Force }
New-Item -ItemType Directory -Path $Tmp | Out-Null

# ── Schema-only ZIP ──────────────────────────────────────────────────────────
Write-Host "==> Copying solution manifest files to ZIP root..." -ForegroundColor Cyan
Copy-Item "$Root\solution.xml"        "$Tmp\solution.xml"
Copy-Item "$Root\customizations.xml"  "$Tmp\customizations.xml"
Copy-Item "$Root\[Content_Types].xml" "$Tmp\[Content_Types].xml"

$ZipPath = Join-Path $Dist "QldCoachFinder.zip"
Write-Host "==> Creating $ZipPath ..." -ForegroundColor Cyan
Compress-Archive -Path "$Tmp\*" -DestinationPath $ZipPath -Force
Remove-Item $Tmp -Recurse -Force
Write-Host "    -> $ZipPath  (ready to import into Power Platform)" -ForegroundColor Green

# ── Full solution (requires PAC CLI) ─────────────────────────────────────────
if (Get-Command pac -ErrorAction SilentlyContinue) {
    Write-Host "`n==> PAC CLI found — building full solution with canvas app..." -ForegroundColor Cyan
    $CanvasDir = Join-Path $Dist "canvas"
    New-Item -ItemType Directory -Path $CanvasDir | Out-Null
    $MsappPath = Join-Path $CanvasDir "qcf_coachsearchapp.msapp"

    pac canvas pack `
        --sources "$Root\CanvasApps\CoachSearchApp_src" `
        --msapp   $MsappPath

    $FullTmp = Join-Path $Dist "tmp_full"
    New-Item -ItemType Directory -Path "$FullTmp\CanvasApps" | Out-Null

    # Patch solution.xml to include canvas app RootComponent
    $xml = Get-Content "$Root\solution.xml" -Raw
    $xml = $xml -replace '<!-- Security Roles -->',
        "<!-- Canvas App -->`n      <RootComponent type=""300"" schemaName=""qcf_coachsearchapp"" behavior=""0"" />`n      <!-- Security Roles -->"
    Set-Content "$FullTmp\solution.xml" $xml

    Copy-Item "$Root\customizations.xml"  "$FullTmp\customizations.xml"
    Copy-Item "$Root\[Content_Types].xml" "$FullTmp\[Content_Types].xml"
    Copy-Item $MsappPath "$FullTmp\CanvasApps\qcf_coachsearchapp.msapp"

    $FullZip = Join-Path $Dist "QldCoachFinder_Full.zip"
    Compress-Archive -Path "$FullTmp\*" -DestinationPath $FullZip -Force
    Remove-Item $FullTmp -Recurse -Force
    Remove-Item $CanvasDir -Recurse -Force
    Write-Host "    -> $FullZip  (schema + canvas app)" -ForegroundColor Green
} else {
    Write-Host "`n==> PAC CLI not found — skipping full solution build." -ForegroundColor Yellow
    Write-Host "    Install: npm install -g @microsoft/powerplatform-cli" -ForegroundColor Yellow
}

Write-Host "`nDone. Import dist\QldCoachFinder.zip into Power Platform." -ForegroundColor Green
