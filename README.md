# Take Me Home, Apparition - Complete Mod Creation Guide (English)

## Table of Contents
1. [Prerequisites](#1-prerequisites)
2. [Create Mod Plugin](#2-create-mod-plugin)
3. [Create FormLists](#3-create-formlists)
4. [Create Messages](#4-create-messages)
5. [Create GlobalVariables](#5-create-globalvariables)
6. [Place XMarkers](#6-place-xmarkers)
7. [Create Location Sublists](#7-create-location-sublists)
8. [Populate FormLists](#8-populate-formlists)
9. [Create Quest and Alias](#9-create-quest-and-alias)
10. [Write Scripts](#10-write-scripts)
11. [Create Magic Effects and Spells](#11-create-magic-effects-and-spells)
12. [Fill Script Properties](#12-fill-script-properties)
13. [Save and Test](#13-save-and-test)
14. [Mod Requirements](#14-mod-requirements)
15. [New Home Template Overview](#15-new-home-template-overview)
16. [Appendix](#16-appendix)

---

## 1. Prerequisites

### 1.1 Required Tools

| Tool | Purpose |
|------|---------|
| Creation Kit (CK) | Create and edit mod plugins |
| SKSE64 | Script extender (required for runtime) |
| SkyUI | UI framework (required for runtime) |
| UIExtensions | List menu system (required for runtime) |
| Papyrus Compiler | Compile scripts (CK built-in or standalone) |

### 1.2 Configure CK

Find `SkyrimEditorCustom.ini` in the game root directory (or `My Games\Skyrim Special Edition`). Add the following content (create the file if it does not exist):

```
[Papyrus]
sScriptSourceFolder=Data\Scripts\Source
sAdditionalImports=Data\Scripts\Source\SKSE
```

Make sure the `Data\Scripts\Source\SKSE` folder contains necessary script source files such as `UIExtensions.psc`.

---

## 2. Create Mod Plugin

1. Launch CK, check the following required plugins:
   - `Skyrim.esm`
   - `Update.esm`
   - `Hearthfires.esm` (if you want to support Hearthfire homes)
   - All CC plugins you wish to support (e.g., `ccBGSSSE005_Hendraheim.esl`, etc.)
2. Click OK to load, wait for completion.
3. Click **File → Save**, save as `TakeMeHomeApparition.esp`.
4. It is recommended to mark the plugin as **ESL-flagged ESP** (use SSEEdit to add the `ESL` flag) to save plugin slots.

---

## 3. Create FormLists

### 3.1 Unlock Condition Data

| EditorID | Type | Description |
|----------|------|-------------|
| `TMHA_AllHomeKeys` | FormList | Key Forms for all key-type homes (e.g., `WhiterunBreezehomeKey`) |
| `TMHA_KeyHomeIndices` | FormList | `TMHA_Index_*` GlobalVariables corresponding to `TMHA_AllHomeKeys` order |
| `TMHA_AllHomeQuests` | FormList | Quests for all quest-type homes (e.g., `ccBGSSSE005_HendraheimQuest`) |
| `TMHA_QuestHomeIndices` | FormList | `TMHA_Index_*` GlobalVariables corresponding to `TMHA_AllHomeQuests` order |
| `TMHA_QuestStages` | FormList | Quest completion stage GlobalVariables (`TMHA_Stage_*`) corresponding to `TMHA_AllHomeQuests` order |
| `TMHA_ProximityHomeIndices` | FormList | `TMHA_Index_*` GlobalVariables for all proximity-type homes (order irrelevant) |
| `TMHA_QuestMarkers` | FormList | **No longer used**, retained for compatibility (can be left empty) |

### 3.2 Unified Home Data (arranged by index order)

| EditorID | Type | Description |
|----------|------|-------------|
| `TMHA_AllHomeNames` | FormList | Home name Messages (index 0 contains the name for index 0 home, etc.) |
| `TMHA_AllHomeHolds` | FormList | Hold index GlobalVariables (index position holds the corresponding `TMHA_HoldIndex_*`) |
| `TMHA_AllHomeMarkers` | FormList | XMarkers (index position holds the corresponding `TMHA_Marker_*`) |
| `TMHA_AllHomeLocationLists` | FormList | Dedicated Location sublist FormLists (index position holds `TMHA_Loc_*`) |
| `TMHA_AllLocationsFlat` | FormList | Flat list of all Locations for all homes (for quick lookup) |

### 3.3 Dynamic Data

| EditorID | Type | Description |
|----------|------|-------------|
| `TMHA_UnlockedHomes` | FormList | Leave empty; dynamically filled at runtime with unlocked home XMarkers |
| `TMHA_HoldNames` | FormList | Hold name Messages (indices 0~8 correspond to the nine holds) |

---

## 4. Create Messages

### 4.1 Hold Names (9)

| EditorID | Title |
|----------|-------|
| `TMHA_Hold_Whiterun` | Whiterun Hold |
| `TMHA_Hold_Riften` | The Rift |
| `TMHA_Hold_Falkreath` | Falkreath Hold |
| `TMHA_Hold_Haafingar` | Haafingar |
| `TMHA_Hold_Hjaalmarch` | Hjaalmarch |
| `TMHA_Hold_Pale` | The Pale |
| `TMHA_Hold_Eastmarch` | Eastmarch |
| `TMHA_Hold_Reach` | The Reach |
| `TMHA_Hold_Solstheim` | Solstheim |

### 4.2 Home Names (example 17 homes)

| Index | EditorID | Title |
|-------|----------|-------|
| 0 | `TMHA_Name_Breezehome` | Breezehome |
| 1 | `TMHA_Name_Honeyside` | Honeyside |
| 2 | `TMHA_Name_VlindrelHall` | Vlindrel Hall |
| 3 | `TMHA_Name_Hjerim` | Hjerim |
| 4 | `TMHA_Name_Proudspire` | Proudspire Manor |
| 5 | `TMHA_Name_Tundra` | Tundra Homestead |
| 6 | `TMHA_Name_Shadowfoot` | Shadowfoot Sanctum |
| 7 | `TMHA_Name_Lakeview` | Lakeview Manor |
| 8 | `TMHA_Name_Windstad` | Windstad Manor |
| 9 | `TMHA_Name_Heljarchen` | Heljarchen Hall |
| 10 | `TMHA_Name_Hendraheim` | Hendraheim |
| 11 | `TMHA_Name_Myrwatch` | Myrwatch |
| 12 | `TMHA_Name_Bloodchill` | Bloodchill Manor |
| 13 | `TMHA_Name_Gallows` | Gallows Hall |
| 14 | `TMHA_Name_GoldenHills` | Golden Hills Plantation |
| 15 | `TMHA_Name_DeadMansDread` | Dead Man's Dread |
| 16 | `TMHA_Name_Nchuanthumz` | Nchuanthumz |

---

## 5. Create GlobalVariables

### 5.1 Hold Index GlobalVariables (one per home)

| Index | EditorID | Value |
|-------|----------|-------|
| 0 | `TMHA_HoldIndex_Breezehome` | 0 (Whiterun) |
| 1 | `TMHA_HoldIndex_Honeyside` | 1 (Rift) |
| 2 | `TMHA_HoldIndex_VlindrelHall` | 7 (Reach) |
| 3 | `TMHA_HoldIndex_Hjerim` | 6 (Eastmarch) |
| 4 | `TMHA_HoldIndex_Proudspire` | 3 (Haafingar) |
| 5 | `TMHA_HoldIndex_Tundra` | 0 (Whiterun) |
| 6 | `TMHA_HoldIndex_Shadowfoot` | 1 (Rift) |
| 7 | `TMHA_HoldIndex_Lakeview` | 2 (Falkreath) |
| 8 | `TMHA_HoldIndex_Windstad` | 4 (Hjaalmarch) |
| 9 | `TMHA_HoldIndex_Heljarchen` | 5 (Pale) |
| 10 | `TMHA_HoldIndex_Hendraheim` | 7 (Reach) |
| 11 | `TMHA_HoldIndex_Myrwatch` | 4 (Hjaalmarch) |
| 12 | `TMHA_HoldIndex_Bloodchill` | 2 (Falkreath) |
| 13 | `TMHA_HoldIndex_Gallows` | 6 (Eastmarch) |
| 14 | `TMHA_HoldIndex_GoldenHills` | 0 (Whiterun) |
| 15 | `TMHA_HoldIndex_DeadMansDread` | 8 (Solstheim) |
| 16 | `TMHA_HoldIndex_Nchuanthumz` | 6 (Eastmarch) |

### 5.2 Unified Home Index GlobalVariables (one per home)

| Index | EditorID | Value |
|-------|----------|-------|
| 0 | `TMHA_Index_Breezehome` | 0 |
| 1 | `TMHA_Index_Honeyside` | 1 |
| 2 | `TMHA_Index_VlindrelHall` | 2 |
| 3 | `TMHA_Index_Hjerim` | 3 |
| 4 | `TMHA_Index_Proudspire` | 4 |
| 5 | `TMHA_Index_Tundra` | 5 |
| 6 | `TMHA_Index_Shadowfoot` | 6 |
| 7 | `TMHA_Index_Lakeview` | 7 |
| 8 | `TMHA_Index_Windstad` | 8 |
| 9 | `TMHA_Index_Heljarchen` | 9 |
| 10 | `TMHA_Index_Hendraheim` | 10 |
| 11 | `TMHA_Index_Myrwatch` | 11 |
| 12 | `TMHA_Index_Bloodchill` | 12 |
| 13 | `TMHA_Index_Gallows` | 13 |
| 14 | `TMHA_Index_GoldenHills` | 14 |
| 15 | `TMHA_Index_DeadMansDread` | 15 |
| 16 | `TMHA_Index_Nchuanthumz` | 16 |

### 5.3 Quest Stage GlobalVariables (7 CC quest homes)

| EditorID | Value | Notes |
|----------|-------|-------|
| `TMHA_Stage_Hendraheim` | 0 | 0 means `IsCompleted()` |
| `TMHA_Stage_Myrwatch` | 0 | Same |
| `TMHA_Stage_Bloodchill` | 0 | Same |
| `TMHA_Stage_Gallows` | 0 | Same |
| `TMHA_Stage_GoldenHills` | 0 | Same |
| `TMHA_Stage_DeadMansDread` | 0 | Same |
| `TMHA_Stage_Nchuanthumz` | 0 | Same |

---

## 6. Place XMarkers

You need to place an XMarker for each home in the game world (in Cell View, choose a suitable location, right-click → New → XMarker).

| Index | EditorID |
|-------|----------|
| 0 | `TMHA_Marker_Breezehome` |
| 1 | `TMHA_Marker_Honeyside` |
| 2 | `TMHA_Marker_VlindrelHall` |
| 3 | `TMHA_Marker_Hjerim` |
| 4 | `TMHA_Marker_Proudspire` |
| 5 | `TMHA_Marker_Tundra` |
| 6 | `TMHA_Marker_Shadowfoot` |
| 7 | `TMHA_Marker_Lakeview` |
| 8 | `TMHA_Marker_Windstad` |
| 9 | `TMHA_Marker_Heljarchen` |
| 10 | `TMHA_Marker_Hendraheim` |
| 11 | `TMHA_Marker_Myrwatch` |
| 12 | `TMHA_Marker_Bloodchill` |
| 13 | `TMHA_Marker_Gallows` |
| 14 | `TMHA_Marker_GoldenHills` |
| 15 | `TMHA_Marker_DeadMansDread` |
| 16 | `TMHA_Marker_Nchuanthumz` |

Additionally, place a `TMHA_ReturnMarker` in any hidden location (e.g., a remote corner of the Tamriel worldspace) to record the wilderness return point.

---

## 7. Create Location Sublists

Each home requires a dedicated FormList (used as Location sublist) containing all interior/exterior Locations belonging to that home. For example:

| Index | EditorID | Included Locations |
|-------|----------|-------------------|
| 0 | `TMHA_Loc_Breezehome` | `WhiterunBreezehomeLocation` |
| 1 | `TMHA_Loc_Honeyside` | `RiftenHoneysideLocation` |
| 2 | `TMHA_Loc_VlindrelHall` | `MarkarthVlindrelHallLocation` |
| 3 | `TMHA_Loc_Hjerim` | `WindhelmHjerimLocation` |
| 4 | `TMHA_Loc_Proudspire` | `SolitudeProudspireManorLocation` |
| 5 | `TMHA_Loc_Tundra` | `ccEEJSSE001_TundraHomesteadLocation` |
| 6 | `TMHA_Loc_Shadowfoot` | `ccEEJSSE003_ShadowfootSanctumLocation` |
| 7 | `TMHA_Loc_Lakeview` | `BYOHHouse1Location` + exterior Location |
| 8 | `TMHA_Loc_Windstad` | `BYOHHouse2Location` + exterior |
| 9 | `TMHA_Loc_Heljarchen` | `BYOHHouse3Location` + exterior |
| 10 | `TMHA_Loc_Hendraheim` | `ccBGSSSE005_HendraheimLocation` |
| 11 | `TMHA_Loc_Myrwatch` | `ccEEJSSE002_MyrwatchLocation` |
| 12 | `TMHA_Loc_Bloodchill` | `ccBGSSSE004_BloodchillManorLocation` |
| 13 | `TMHA_Loc_Gallows` | `ccBGSSSE003_GallowsHallLocation` |
| 14 | `TMHA_Loc_GoldenHills` | `ccBGSSSE006_GoldenHillsLocation` |
| 15 | `TMHA_Loc_DeadMansDread` | `ccBGSSSE009_DeadMansDreadLocation` |
| 16 | `TMHA_Loc_Nchuanthumz` | `ccBGSSSE010_NchuanthumzLocation` |

Note: Hearthfire homes (index 7-9) need to include both interior and exterior Locations, because the exterior area also belongs to the home.

---

## 8. Populate FormLists

### 8.1 `TMHA_HoldNames`
- Drag in 9 hold name Messages in order of indices 0-8 (`TMHA_Hold_Whiterun`, etc.).

### 8.2 `TMHA_AllHomeNames`
- Drag in 17 home name Messages in order of indices 0-16 (`TMHA_Name_Breezehome` at index 0, `TMHA_Name_Honeyside` at index 1, and so on).

### 8.3 `TMHA_AllHomeHolds`
- Drag in 17 `TMHA_HoldIndex_*` GlobalVariables in order of indices 0-16.

### 8.4 `TMHA_AllHomeMarkers`
- Drag in 17 XMarkers in order of indices 0-16 (`TMHA_Marker_Breezehome` at index 0, etc.).

### 8.5 `TMHA_AllHomeLocationLists`
- Drag in 17 `TMHA_Loc_*` FormLists in order of indices 0-16.

### 8.6 `TMHA_AllLocationsFlat`
- Drag all Locations (interior + exterior + basement) for all homes into this FormList at once; order does not matter.

### 8.7 Key Unlock Condition FormLists

| FormList | Filling Method |
|----------|----------------|
| `TMHA_AllHomeKeys` | Drag in key Forms in order of indices 0-6 (`WhiterunBreezehomeKey` → `RiftenHoneysideKey` → ... → `ccEEJSSE003_ShadowfootSanctumKey`) |
| `TMHA_KeyHomeIndices` | Drag in the corresponding `TMHA_Index_*` in exactly the same order as `TMHA_AllHomeKeys` (`TMHA_Index_Breezehome` → `TMHA_Index_Honeyside` → ... → `TMHA_Index_Shadowfoot`) |

### 8.8 Quest Unlock Condition FormLists

| FormList | Filling Method |
|----------|----------------|
| `TMHA_AllHomeQuests` | Drag in 7 CC quests (e.g., `ccBGSSSE005_HendraheimQuest` → `ccEEJSSE002_MageTowerQuest` → ...) |
| `TMHA_QuestHomeIndices` | Drag in the corresponding `TMHA_Index_*` in the same order (`TMHA_Index_Hendraheim` → `TMHA_Index_Myrwatch` → ...) |
| `TMHA_QuestStages` | Drag in the corresponding `TMHA_Stage_*` in the same order (`TMHA_Stage_Hendraheim` → `TMHA_Stage_Myrwatch` → ...) |
| `TMHA_QuestMarkers` | Leave empty or keep old data (no longer used) |

### 8.9 Proximity Unlock Condition FormList

| FormList | Filling Method |
|----------|----------------|
| `TMHA_ProximityHomeIndices` | Currently leave empty (wait until adding proximity homes in the future, then drag in `TMHA_Index_*` in any order) |

---

## 9. Create Quest and Alias

### 9.1 Create the Main Quest
- Right-click in Object Window → New → Quest.
- Editor ID: `TMHA_Quest`
- Check `Start Game Enabled`
- Check `Run Once`

### 9.2 Create Player Alias
- In the Quest window, go to the Alias tab, right-click → New Reference Alias.
- Alias Name: `TMHA_PlayerAlias`
- Fill Type: `Specific Reference`
- Click `Select Reference` → choose `PlayerRef`.
- In the `Scripts` tab, add the script `TMHA_PlayerScript` (the script will be created in step 10).

### 9.3 Create Quest Script (optional)
- Create an empty script `TMHA_QuestScript` and attach it to the Quest. This script is only used to host the Alias; it does nothing.

---

## 10. Write Scripts

You need two script files: **TMHA_PlayerScript.psc** and **TMHA_Apparition_Effect.psc**.

Save both scripts to the `Data\Scripts\Source\` directory. Then compile them into `.pex` files using the Papyrus Compiler or directly in CK, and place them in `Data\Scripts\`.

### 10.1 `TMHA_PlayerScript.psc`

```papyrus
; Key functionality summary:
; - Monitors key acquisition, Hearthfire quest stages, CC quest completion, and proximity trigger for four unlock methods.
; - Maintains the HomeUnlocked array (0~65).
; - Updates the TMHA_UnlockedHomes FormList.
; - Builds cache arrays for the Effect script to read.
```

### 10.2 `TMHA_Apparition_Effect.psc`

```papyrus
; Functionality summary:
; - Shows a simplified menu when inside a home, or a hold menu when in the wilderness.
; - Handles three-level menu interaction, executes teleportation and effects.
; - Accesses cached data via CachedPS.
```

---

## 11. Create Magic Effects and Spells

### 11.1 Create the Invisibility Effect `TMHA_VanishShader_Effect`
- Create a new Magic Effect, Editor ID: `TMHA_VanishShader_Effect`
- Effect Archetype: `Invisibility`
- Hit Shader: Select `InvFXShader` (or any fade-in/fade-out shader you prefer)
- Duration: 3 (seconds)
- Others default

### 11.2 Create the Script Effect `TMHA_Apparition_Effect`
- Create a new Magic Effect, Editor ID: `TMHA_Apparition_Effect`
- Effect Archetype: `Script`
- In the `Scripts` tab, add the `TMHA_Apparition_Effect` script.

### 11.3 Create the Spell `TMHA_Apparition_Spell`
- Create a new Spell, Editor ID: `TMHA_Apparition_Spell`
- Type: `Lesser Power`
- Effects:
  - `TMHA_VanishShader_Effect` (Duration = 3)
  - `TMHA_Apparition_Effect` (Duration = 0)

### 11.4 Create the Arrival Short Invisibility Spell `TMHA_VanishSpell_Arrive`
- Create a new Spell, Editor ID: `TMHA_VanishSpell_Arrive`
- Type: `Spell`
- Effects: `TMHA_VanishShader_Effect` (Duration = 1)
- Check `Hide in UI` (so it's invisible to the player)

### 11.5 Create the Spell Tome `TMHA_Tome_Apparition`
- Create a new Book, Editor ID: `TMHA_Tome_Apparition`
- Book Type: `Spell Tome`
- Spell: `TMHA_Apparition_Spell`
- Fill in name and description text.

---

## 12. Fill Script Properties

### 12.1 `TMHA_PlayerScript` Property Bindings

| Property | Value |
|----------|-------|
| `TMHA_AllHomeKeys` | `TMHA_AllHomeKeys` |
| `TMHA_KeyHomeIndices` | `TMHA_KeyHomeIndices` |
| `BYOHHouseFalkreathQuest` | `BYOHHouseFalkreath` |
| `BYOHHouseHjaalmarchQuest` | `BYOHHouseHjaalmarch` |
| `BYOHHousePaleQuest` | `BYOHHousePale` |
| `Marker_Lakeview` | `TMHA_Marker_Lakeview` |
| `Marker_Windstad` | `TMHA_Marker_Windstad` |
| `Marker_Heljarchen` | `TMHA_Marker_Heljarchen` |
| `TMHA_AllHomeQuests` | `TMHA_AllHomeQuests` |
| `TMHA_QuestHomeIndices` | `TMHA_QuestHomeIndices` |
| `TMHA_QuestMarkers` | `TMHA_QuestMarkers` (retained for compatibility) |
| `TMHA_QuestStages` | `TMHA_QuestStages` |
| `TMHA_ProximityHomeIndices` | `TMHA_ProximityHomeIndices` |
| `TMHA_UnlockedHomes` | `TMHA_UnlockedHomes` |
| `TMHA_AllHomeNames` | `TMHA_AllHomeNames` |
| `TMHA_AllHomeHolds` | `TMHA_AllHomeHolds` |
| `TMHA_HoldNames` | `TMHA_HoldNames` |
| `TMHA_AllLocationsFlat` | `TMHA_AllLocationsFlat` |
| `TMHA_AllHomeLocationLists` | `TMHA_AllHomeLocationLists` |
| `TMHA_AllHomeMarkers` | `TMHA_AllHomeMarkers` (retained for compatibility) |
| `TMHA_Tome_Apparition` | `TMHA_Tome_Apparition` |

### 12.2 `TMHA_Apparition_Effect` Property Bindings

| Property | Value |
|----------|-------|
| `TMHA_UnlockedHomes` | `TMHA_UnlockedHomes` |
| `TMHA_ReturnMarker` | `TMHA_ReturnMarker` |
| `TMHA_ApparitionHazard` | Your custom Hazard (e.g., `TMHA_ApparitionHazard`) |
| `TMHA_AllHomeLocationLists` | `TMHA_AllHomeLocationLists` |
| `TMHA_Apparition_Spell_Arrive` | `TMHA_VanishSpell_Arrive` |

> Note: The Effect script no longer needs `TMHA_AllHomeMarkers`, `TMHA_QuestMarkers`, `TMHA_QuestHomeIndices`, `Marker_Lakeview`, etc. You can leave these properties empty or delete them in CK.

---

## 13. Save and Test

1. Save your `.esp` in CK.
2. Compile both scripts (if not auto-compiled, run the Papyrus Compiler manually).
3. Launch the game and load the mod.

### Testing Commands

| Type | Command |
|------|---------|
| Key unlock | `player.additem WhiterunBreezehomeKey 1` |
| Hearthfire unlock | `setstage BYOHHouseFalkreath 100` |
| CC quest unlock | `completequest ccBGSSSE005_HendraheimQuest` |
| Obtain spell tome | Automatic (upon first home unlock) |

---

## 14. Mod Requirements

| Requirement | Mandatory |
|-------------|-----------|
| SKSE64 | ✅ |
| SkyUI | ✅ |
| UIExtensions | ✅ |
| Backported Extended ESL Support | ✅ (if using ESL-flagged ESP) |
| Hearthfires DLC | Optional (skip Hearthfire homes if not present) |
| Anniversary Edition CC Content | Optional (skip CC homes if not present) |

---

## 15. New Home Template Overview

This mod supports three unlock types. See the "Add New Home Guide" for detailed steps for each type.

| Type | CK Objects to Create | FormLists to Update |
|------|----------------------|---------------------|
| Key-Type | 5 | 5 |
| Quest-Type | 6 | 9 |
| Proximity-Type | 4 | 5 |

---

## 16. Appendix

### Appendix A: Hold Index Reference

| Index | Hold |
|-------|------|
| 0 | Whiterun Hold |
| 1 | The Rift |
| 2 | Falkreath Hold |
| 3 | Haafingar |
| 4 | Hjaalmarch |
| 5 | The Pale |
| 6 | Eastmarch |
| 7 | The Reach |
| 8 | Solstheim |

### Appendix B: Home Index Overview (example 17 homes)

| Index | Home | Unlock Type | Hold |
|-------|------|-------------|------|
| 0 | Breezehome | Key | Whiterun |
| 1 | Honeyside | Key | Rift |
| 2 | Vlindrel Hall | Key | Reach |
| 3 | Hjerim | Key | Eastmarch |
| 4 | Proudspire Manor | Key | Haafingar |
| 5 | Tundra Homestead | Key | Whiterun |
| 6 | Shadowfoot Sanctum | Key | Rift |
| 7 | Lakeview Manor | Quest (Stage≥100) | Falkreath |
| 8 | Windstad Manor | Quest (Stage≥100) | Hjaalmarch |
| 9 | Heljarchen Hall | Quest (Stage≥100) | Pale |
| 10 | Hendraheim | Quest (IsCompleted) | Reach |
| 11 | Myrwatch | Quest (IsCompleted) | Hjaalmarch |
| 12 | Bloodchill Manor | Quest (IsCompleted) | Falkreath |
| 13 | Gallows Hall | Quest (IsCompleted) | Eastmarch |
| 14 | Golden Hills Plantation | Quest (IsCompleted) | Whiterun |
| 15 | Dead Man's Dread | Quest (IsCompleted) | Solstheim |
| 16 | Nchuanthumz | Quest (IsCompleted) | Eastmarch |

### Appendix C: EditorID Naming Convention

| Purpose | Template |
|---------|----------|
| Home Name Message | `TMHA_Name_{HomeName}` |
| Hold Index GlobalVariable | `TMHA_HoldIndex_{HomeName}` |
| Unified Home Index GlobalVariable | `TMHA_Index_{HomeName}` |
| Quest Stage GlobalVariable | `TMHA_Stage_{HomeName}` (quest-type only) |
| Location Sublist FormList | `TMHA_Loc_{HomeName}` |
| Teleport Marker XMarker | `TMHA_Marker_{HomeName}` |
