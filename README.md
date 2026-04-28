# Queensland Coach Finder — Power Platform Solution

A Microsoft Power Apps canvas app that lets sports clubs search for accredited coaches who have completed courses in Queensland. Each coach profile features a **headshot photo** and **video reel** of their coaching delivery.

---

## Contents

```
.
├── solution/
│   ├── solution.xml            Solution manifest (publisher, version, root components)
│   ├── customizations.xml      Dataverse table definitions, option sets, security roles
│   └── [Content_Types].xml     OPC content types
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

### Prerequisites
- Power Platform CLI (`pac`) ≥ 1.32  
  Install: `npm install -g @microsoft/powerplatform-cli`  
  Or download from: https://aka.ms/PowerAppsCLI
- A Power Platform environment with Dataverse enabled
- System Administrator or System Customizer security role

### Step 1 — Pack the canvas app
```bash
cd CanvasApps/CoachSearchApp_src
pac canvas pack \
  --sources . \
  --msapp ../../build/CoachSearchApp.msapp
```

### Step 2 — Build the solution ZIP
```bash
# Place the packed .msapp into the solution folder structure first
mkdir -p build/CanvasApps
cp build/CoachSearchApp.msapp build/CanvasApps/qcf_coachsearchapp.msapp

# Pack the solution
pac solution pack \
  --zipfile build/QldCoachFinder.zip \
  --folder solution \
  --packagetype Unmanaged
```

### Step 3 — Import into Power Platform
**Option A — CLI**
```bash
pac auth create --environment https://yourorg.crm6.dynamics.com
pac solution import --path build/QldCoachFinder.zip --activate-plugins
```

**Option B — Power Platform admin portal**
1. Open https://make.powerapps.com
2. Select your environment (Australia Southeast — crm6)
3. Solutions → Import → upload `build/QldCoachFinder.zip`
4. Follow the import wizard

### Step 4 — Assign security roles
| Role | Who gets it |
|---|---|
| QCF Club User | All club staff who search for coaches |
| QCF Coach Administrator | Staff who manage coach profiles and courses |

Assign via: https://make.powerapps.com → Dataverse → Roles

### Step 5 — Load seed data (optional)
Import the sample data spreadsheet via Dataverse → Import Data:
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
