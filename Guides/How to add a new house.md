## Add New Home Guide

This guide is intended for users who have already built the base mod and want to add new homes without modifying any script code.

## 1. General Workflow

Regardless of the unlock type, you need to do two things:

1. **Create the necessary CK objects** (see lists below).
2. **Update the corresponding FormLists** by placing the new home's data in the correct positions.

**Core principle:** All homes share a unified index pool of 0–65, and each home's index is determined by the Value of its `TMHA_Index_{HomeName}` GlobalVariable.

## 2. Determine Home Basic Info

| Item | Description | Example |
|------|-------------|---------|
| Home Name | Display name in game | Severin Manor |
| Hold | See hold reference table | Solstheim |
| Unlock Type | `Key`, `Quest`, or `Proximity` | Quest |
| For Key Type | Key EditorID | DLC2RRSeverinManorKey |
| For Quest Type | Quest EditorID | DLC2RR02 |
| For Quest Type | Completion Stage (0 = IsCompleted) | 0 |
| Home Index | Next available index (recommended = current max index + 1) | 17 |

## 3. Hold Index Reference Table

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

## 4. Key-Type Home

### CK Objects to Create (5 total)

| # | Type | EditorID Template | Description |
|---|------|-------------------|-------------|
| 1 | Message | `TMHA_Name_{HomeName}` | Display name of the home |
| 2 | GlobalVariable | `TMHA_HoldIndex_{HomeName}` | Hold index (Value = hold index number) |
| 3 | GlobalVariable | `TMHA_Index_{HomeName}` | Unified home index (Value = home index) |
| 4 | FormList | `TMHA_Loc_{HomeName}` | All Locations belonging to this home |
| 5 | XMarker | `TMHA_Marker_{HomeName}` | Teleport target (place at the entrance or inside) |

### FormLists to Update (5 total)

| FormList | Action |
|----------|--------|
| `TMHA_AllHomeKeys` | Append the key Form to the end |
| `TMHA_KeyHomeIndices` | Append `TMHA_Index_{HomeName}` to the end (**order must match `TMHA_AllHomeKeys`**) |
| `TMHA_AllHomeMarkers` | Put the XMarker at the **index position** (replace if a placeholder exists; extend the FormList if too short) |
| `TMHA_AllHomeNames` | Put the `TMHA_Name_{HomeName}` Message at the **index position** |
| `TMHA_AllHomeHolds` | Put the `TMHA_HoldIndex_{HomeName}` GlobalVariable at the **index position** |

### Optional (Strongly Recommended)

| FormList | Action |
|----------|--------|
| `TMHA_AllHomeLocationLists` | Put `TMHA_Loc_{HomeName}` at the **index position** (used to exclude the current home) |
| `TMHA_AllLocationsFlat` | Append all Locations to the end (used to detect whether the player is inside the home) |

### Order Alignment Example

Suppose your new key home has index 17, and `TMHA_AllHomeKeys` currently has 7 entries. The new key should be placed at entry index 7 (the 8th entry) in `TMHA_AllHomeKeys`. At the same index 7 in `TMHA_KeyHomeIndices`, you must put the corresponding `TMHA_Index_SeverinManor` (Value=17). In the four unified FormLists, you place the data at index 17.

## 5. Quest-Type Home

### CK Objects to Create (6 total)

| # | Type | EditorID Template | Description |
|---|------|-------------------|-------------|
| 1 | Message | `TMHA_Name_{HomeName}` | Display name of the home |
| 2 | GlobalVariable | `TMHA_HoldIndex_{HomeName}` | Hold index |
| 3 | GlobalVariable | `TMHA_Index_{HomeName}` | Unified home index |
| 4 | GlobalVariable | `TMHA_Stage_{HomeName}` | Quest completion stage (0 = IsCompleted) |
| 5 | FormList | `TMHA_Loc_{HomeName}` | Location sublist |
| 6 | XMarker | `TMHA_Marker_{HomeName}` | Teleport target |

### FormLists to Update (9 total)

| FormList | Action |
|----------|--------|
| `TMHA_AllHomeQuests` | Append the Quest to the end |
| `TMHA_QuestHomeIndices` | Append `TMHA_Index_{HomeName}` to the end (order must match `TMHA_AllHomeQuests`) |
| `TMHA_QuestStages` | Append `TMHA_Stage_{HomeName}` to the end (order must match) |
| `TMHA_AllHomeMarkers` | Put the XMarker at the **index position** |
| `TMHA_AllHomeNames` | Put the Message at the **index position** |
| `TMHA_AllHomeHolds` | Put the `TMHA_HoldIndex_{HomeName}` at the **index position** |
| `TMHA_AllHomeLocationLists` | Put `TMHA_Loc_{HomeName}` at the **index position** |
| `TMHA_AllLocationsFlat` | Append all Locations to the end |
| `TMHA_QuestMarkers` | No action needed; keep old data (script no longer reads it) |

### Notes

- If the quest already exists (e.g., a vanilla or CC quest), you only need to add it to `TMHA_AllHomeQuests`; no need to create a new quest.
- Stage value `0` means `IsCompleted()`; any non‑zero value means `GetStage() >= StageValue`.

## 6. Proximity-Type Home

### CK Objects to Create (4 total)

| # | Type | EditorID Template | Description |
|---|------|-------------------|-------------|
| 1 | Message | `TMHA_Name_{HomeName}` | Display name of the home |
| 2 | GlobalVariable | `TMHA_HoldIndex_{HomeName}` | Hold index |
| 3 | GlobalVariable | `TMHA_Index_{HomeName}` | Unified home index |
| 4 | XMarker | `TMHA_Marker_{HomeName}` | Detection point (place at the entrance; home unlocks when player is within 300 units) |

### FormLists to Update (5 total)

| FormList | Action |
|----------|--------|
| `TMHA_ProximityHomeIndices` | Append `TMHA_Index_{HomeName}` to the end (**order does not matter**) |
| `TMHA_AllHomeMarkers` | Put the XMarker at the **index position** |
| `TMHA_AllHomeNames` | Put the Message at the **index position** |
| `TMHA_AllHomeHolds` | Put the `TMHA_HoldIndex_{HomeName}` at the **index position** |
| `TMHA_AllHomeLocationLists` | Put `TMHA_Loc_{HomeName}` at the **index position** (optional, for exclusion) |

### Optional

| FormList | Action |
|----------|--------|
| `TMHA_AllLocationsFlat` | Append all Locations to the end (optional, for in‑home detection) |

### Trigger Explanation

- The home is automatically unlocked when the player comes within **300 game units** of the XMarker.
- No item or quest is required.
- Proximity check runs every 2 seconds, suitable for open‑world hideouts that unlock upon approach.

## 7. General Precautions

### 1. Index Management

- Home indices must be globally unique; they cannot conflict with any other home (key, quest, proximity, or Hearthfire) in terms of the `TMHA_Index_*` Value.
- Hearthfire homes (indices 7–9) are hard‑coded in the script. **Do not** use indices 7, 8, or 9 for other homes.

### 2. FormList Length

- The four unified FormLists (`TMHA_AllHomeNames`, `TMHA_AllHomeHolds`, `TMHA_AllHomeMarkers`, `TMHA_AllHomeLocationLists`) must have a length at least `max index + 1`. For example, if your new index is 17, these FormLists must have at least 18 entries (indices 0–17). If the current length is insufficient, extend the FormList by creating new empty entries in the CK.
- `TMHA_AllLocationsFlat` is a flat list with no index requirement; you can simply append to it.

### 3. Order Alignment (Important)

- `TMHA_KeyHomeIndices` must match `TMHA_AllHomeKeys` in order.
- `TMHA_QuestHomeIndices` and `TMHA_QuestStages` must match `TMHA_AllHomeQuests` in order.
- `TMHA_ProximityHomeIndices` has no order requirement.
- The four unified FormLists (Names, Holds, Markers, LocationLists) **must be ordered by home index**, consistent with the Value of each `TMHA_Index_*`.

### 4. No Script Changes Required

- All FormList size changes are automatically detected by the script's `OnUpdate()`; `BuildCache()` rebuilds the cache automatically.
- Adding any type of home does **not** require modifying or recompiling any `.psc` file.

### 5. xEdit Compatibility

- The current design is ready for xEdit automation: all data is stored in FormLists, and indices are controlled by GlobalVariable Values.
- In the future, you can write a PAScript for xEdit that reads `TMHA_AllHomeNames.GetSize()` as the next index, then creates objects and populates FormLists.

## 8. Testing Commands

| Type | Command |
|------|---------|
| Key unlock | `player.additem <KeyEditorID> 1` |
| Quest unlock (IsCompleted) | `completequest <QuestEditorID>` |
| Quest unlock (specific stage) | `setstage <QuestEditorID> <StageNumber>` |
| Proximity unlock | Walk up to the entrance (no command needed) |
| View unlocked count | `sqv TMHA_Quest` and check the size of `TMHA_UnlockedHomes` (could use `player.placeatme <MarkerFormID>` for debugging) |

## 9. Frequently Asked Questions

**Q: What if the index position in `TMHA_AllHomeMarkers` is wrong?**

A: In the CK, open that FormList, find the incorrect entry, right-click → Delete to remove it, then New in the correct position and drag in the correct XMarker. Alternatively, use SSEEdit to directly edit the FormList order.

**Q: My new home is unlocked but does not appear in the spell menu?**

A: First, check whether `TMHA_UnlockedHomes` contains the home's XMarker. In the console, type `help "TMHA_Unlocked" 4` to see the FormList contents. If it's missing, verify:
- `HomeUnlocked[index]` is `true` (troubleshoot the unlock condition).
- `CachedMarkers[index]` is not `None` (check `TMHA_AllHomeMarkers` filling).
- `UpdateUnlockedHomesFormList` was called (confirm that the `CheckForNew*` function executed).

**Q: Can I adjust the proximity detection range?**

A: Yes. Modify the value `300.0` in the `CheckProximityHomes` function in `TMHA_PlayerScript.psc` and recompile. Keeping the default is recommended.

**Q: Can I add multiple homes at once?**

A: Yes. Just ensure each home has a unique index and that all FormLists are updated synchronously.

---

## Appendix: Quick Checklist (After Adding a New Home)

- [ ] The home index is correctly set in `TMHA_Index_{HomeName}`
- [ ] The hold index is correctly set in `TMHA_HoldIndex_{HomeName}` (check hold table)
- [ ] `TMHA_AllHomeNames` has the Message at the correct index position
- [ ] `TMHA_AllHomeHolds` has the HoldIndex at the correct index position
- [ ] `TMHA_AllHomeMarkers` has the XMarker at the correct index position
- [ ] `TMHA_AllHomeLocationLists` has the Location sublist at the correct index position (optional but recommended)
- [ ] If Key-Type: the key is added to `TMHA_AllHomeKeys`, and `TMHA_KeyHomeIndices` order matches
- [ ] If Quest-Type: the quest is added to `TMHA_AllHomeQuests`, and both `TMHA_QuestHomeIndices` and `TMHA_QuestStages` order matches
- [ ] If Proximity-Type: `TMHA_ProximityHomeIndices` contains the corresponding `TMHA_Index_*`
- [ ] `TMHA_AllLocationsFlat` contains all Locations (optional but recommended)
- [ ] All FormList lengths are at least `max index + 1`
- [ ] Save the `.esp`, reload the save, and test the unlock
```