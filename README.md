# Queensland Coach Finder — Power Platform Solution

A Microsoft Power Apps canvas app that lets sports clubs search for accredited coaches who have completed courses in Queensland. Each coach profile features a **headshot photo** and **video reel** of their coaching delivery.

---

## Importing into Power Platform

> **Do NOT use the GitHub "Download ZIP" button.** GitHub always wraps the files in a subfolder, so `solution.xml` is never at the root of the ZIP and Power Platform will reject it with _"The manifest file could not be found"_.

**The correct way to get the importable ZIP:**

1. Go to the **Releases** tab of this repository
2. Under **Assets**, download `QldCoachFinder.zip`
3. In https://make.powerapps.com → **Solutions → Import solution** → upload `QldCoachFinder.zip`

The release ZIP is automatically built by the GitHub Actions workflow (`.github/workflows/build-solution.yml`) and has `solution.xml` at its root, exactly as Power Platform requires.

---

## Contents

```
.
├── .github/workflows/
│   └── build-solution.yml      Builds & publishes QldCoachFinder.zip as a Release asset
├── solution.xml                Solution manifest (publisher, version, root components)
├── customizations.xml          Dataverse table definitions, option sets, security roles
├── [Content_Types].xml         OPC content types
├── build.sh / build.ps1        Local build scripts (optional, requires no CLI for schema ZIP)
│
└── CanvasApps/
    └── CoachSearchApp_src/
        ├── App.fx.yaml                 App-level OnStart (colours, global state, data pre-load)
        ├── pkgs/
        │   ├── CanvasManifest.json     App metadata and connector references
        │   ├── DataSources.json        Dataverse table bindings
        │   ├── Themes.json             Queensland branding colour palette
        │   └── TableDefinitions/       Column reference docs (informational)
        └── Src/
            ├── SplashScreen.fx.yaml        Branded launch screen → auto-navigates
            ├── BrowseScreen.fx.yaml        Search + filter panel + coach card gallery
            └── CoachProfileScreen.fx.yaml  Full profile: headshot, video reel, qualifications
```

---

## Data Model

Four Dataverse tables under publisher prefix `qcf_`.

```
qcf_sport  ◄────────────  qcf_course
                                │
                                │  qcf_coachqualification (junction)
                                │  · qcf_completiondate
                                │  · qcf_expirydate
                                │  · qcf_certificatenumber
                                ▼
              qcf_coach ────────┘
              · qcf_fullname
              · qcf_headshot        (Dataverse Image column)
              · qcf_videourl        (URL to MP4 / SharePoint file)
              · qcf_region          (QLD region picklist)
              · qcf_availableforhire
              · qcf_wwccnumber
```

### Queensland Regions (picklist)
Brisbane Metro · Gold Coast · Sunshine Coast · Ipswich/Logan · Toowoomba · Wide Bay Burnett · Mackay/Whitsundays · Central QLD · North QLD · Far North QLD · South West QLD

### Accreditation Levels (picklist)
Foundation · Level 1 · Level 2 · Level 3 · Elite

---

## App Screens

| Screen | Purpose |
|---|---|
| **SplashScreen** | Branded landing page, auto-advances after 3 s |
| **BrowseScreen** | Search bar · sport/course/region filter panel · coach card gallery |
| **CoachProfileScreen** | Circular headshot · video reel · bio · qualifications list · contact CTA |

### BrowseScreen — Filter behaviour
- Text search matches `qcf_fullname` (case-insensitive substring)
- **Sport** dropdown cascades into **Course** dropdown
- Active filter chips appear as dismissible pills
- "Available for hire" toggle hides coaches with `qcf_availableforhire = false`
- Result count label updates reactively

### CoachProfileScreen — Video playback
The built-in Power Apps `Video` control plays **direct MP4 / WebM / OGG** links.

| Video hosting | Approach |
|---|---|
| SharePoint document library | Store `.mp4` and use the SharePoint file direct URL |
| Azure Blob Storage | Upload `.mp4` and paste the public or SAS URL |
| YouTube / Vimeo | URL is detected; an "Open Video" button launches the browser |

---

## Deployment Guide

> **Why do I get "manifest file could not be found"?**  
> Power Platform requires `solution.xml` to be at the **root of the ZIP** — not inside a subfolder. Never import the raw git repo ZIP. Always use the build script below to produce the correct ZIP.

### Prerequisites
- A Power Platform environment with Dataverse enabled (Australia Southeast — crm6.dynamics.com)
- System Administrator or System Customizer security role in that environment
- Power Platform CLI (`pac`) only needed for the full solution including canvas app

### Quickest path — Schema-only import (no CLI required)

This imports the four Dataverse tables and security roles. You then build the canvas app inside Power Apps Studio.

**macOS / Linux**
```bash
./build.sh
# produces:  dist/QldCoachFinder.zip
```

**Windows (PowerShell)**
```powershell
.\build.ps1
# produces:  dist\QldCoachFinder.zip
```

Then in your browser:
1. Open https://make.powerapps.com
2. Switch to your environment (top-right corner)
3. **Solutions → Import solution** → upload `dist/QldCoachFinder.zip`
4. Click through the import wizard — no connection references to configure

> The ZIP must contain `solution.xml`, `customizations.xml`, and `[Content_Types].xml` at its root. The build scripts create exactly that structure.

---

### Full solution import (schema + canvas app, requires PAC CLI)

Install PAC CLI once:
```bash
npm install -g @microsoft/powerplatform-cli   # or download from https://aka.ms/PowerAppsCLI
```

Then run the same build script — it detects `pac` and automatically:
1. Packs `CanvasApps/CoachSearchApp_src/` → `qcf_coachsearchapp.msapp`
2. Assembles a ZIP with the canvas app inside `CanvasApps/`
3. Outputs `dist/QldCoachFinder_Full.zip`

```bash
./build.sh          # macOS/Linux
.\build.ps1         # Windows
```

Import `dist/QldCoachFinder_Full.zip` via the admin portal or CLI:
```bash
pac auth create --environment https://yourorg.crm6.dynamics.com
pac solution import --path dist/QldCoachFinder_Full.zip --activate-plugins
```

---

### After import — connect the canvas app to Dataverse

If you imported the schema-only ZIP, create the canvas app manually:
1. https://make.powerapps.com → **Create → Blank canvas app** → Tablet layout
2. **Data** panel → Add `qcf_coaches`, `qcf_courses`, `qcf_sports`, `qcf_coachqualifications`
3. Use the screen designs and Power Fx formulas in `CanvasApps/CoachSearchApp_src/Src/` as your blueprint

---

### Assign security roles
| Role | Who gets it |
|---|---|
| QCF Club User | All club staff who search for coaches |
| QCF Coach Administrator | Staff who manage coach profiles and courses |

Assign via: https://make.powerapps.com → Settings → Users + permissions → Security roles

### Load seed data (optional)
Import the sample data via Dataverse → **Import data**:
- `data/sports_seed.xlsx` — common Queensland sports
- `data/courses_seed.xlsx` — common accreditation courses

---

## Video Hosting Recommendation (SharePoint)

1. Create a SharePoint site: `Coaching Videos`
2. Add a document library: `Video Reels`
3. Set library permissions so the Power Apps service account has Read access
4. Upload coach `.mp4` files (recommended: H.264, 1080p, ≤200 MB per file)
5. Get the direct file URL (not the SharePoint page URL):  
   `https://yourorg.sharepoint.com/sites/CoachingVideos/Video%20Reels/JaneSmith_Reel.mp4`
6. Paste this URL into the coach record's `qcf_videourl` field

---

## Customisation Notes

### Colours
All brand colours are declared as global variables in `App.fx.yaml → OnStart`. Change `gblColPrimary` (default: QLD government blue `#00539B`) and `gblColAccent` (default: `#FF9800`) to match your organisation's palette.

### Adding sports
Add rows to `qcf_sport` via the model-driven app or data import. The sport dropdown in the canvas app populates from this table automatically.

### Adding courses
Add rows to `qcf_course`. Link each course to a sport via the `qcf_sport` lookup. The cascading course dropdown filters automatically when a sport is selected.

### WWCC verification
The WWCC (Working With Children Check) number and expiry date are stored but not automatically verified. To add live verification, connect to the Blue Card Services API via a Power Automate flow triggered from the coach record save.

---

## Delegation Warning

Power Apps has a default delegation limit of **2 000 rows** for complex filter queries. If your coach database exceeds this:

1. In `BrowseScreen.fx.yaml`, replace the inline `Filter()` on the gallery `Items` with a two-step approach:
   ```
   // Step 1 (in a button / OnChange):
   ClearCollect(colFilteredIds,
       Filter(qcf_coachqualifications,
              'Course (qcf_course)'.qcf_sport = gblFilterSport.qcf_sportid));
   // Step 2 (gallery Items):
   Filter(qcf_coaches, qcf_coachid in colFilteredIds.qcf_coachid)
   ```
2. Or increase the delegation limit in **Settings → Advanced settings → Maximum record row limit**.

---

## Solution Version History

| Version | Date | Notes |
|---|---|---|
| 1.0.0.0 | 2026-04-28 | Initial release |
