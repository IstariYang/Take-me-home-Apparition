# Take Me Home, Apparition - 完整 Mod 制作指南（中文版）

## 目录
1. [准备工作](#1-准备工作)
2. [创建 Mod 插件](#2-创建-mod-插件)
3. [创建 FormList](#3-创建-formlist)
4. [创建 Message](#4-创建-message)
5. [创建 GlobalVariable](#5-创建-globalvariable)
6. [放置 XMarker](#6-放置-xmarker)
7. [创建 Location 子表单](#7-创建-location-子表单)
8. [填充 FormList](#8-填充-formlist)
9. [创建 Quest 和 Alias](#9-创建-quest-和-alias)
10. [编写脚本](#10-编写脚本)
11. [创建 Magic Effect 和 Spell](#11-创建-magic-effect-和-spell)
12. [填充脚本属性](#12-填充脚本属性)
13. [保存并测试](#13-保存并测试)
14. [前置 Mod 需求](#14-前置-mod-需求)
15. [新增房产模板概览](#15-新增房产模板概览)
16. [附录](#16-附录)

---

## 1. 准备工作

### 1.1 所需工具

| 工具 | 用途 |
|------|------|
| Creation Kit (CK) | 创建和编辑 Mod 插件 |
| SKSE64 | 脚本扩展（运行必需） |
| SkyUI | UI 框架（运行必需） |
| UIExtensions | 列表菜单系统（运行必需） |
| Papyrus Compiler | 编译脚本（CK自带或独立） |

### 1.2 配置 CK

在游戏根目录（或 `My Games\Skyrim Special Edition`）找到 `SkyrimEditorCustom.ini`，添加以下内容（如果文件不存在则新建）：

```
[Papyrus]
sScriptSourceFolder=Data\Scripts\Source
sAdditionalImports=Data\Scripts\Source\SKSE
```

确保你的 `Data\Scripts\Source\SKSE` 文件夹下有 `UIExtensions.psc` 等必要脚本源文件。

---

## 2. 创建 Mod 插件

1. 启动 CK，勾选以下必需插件：
   - `Skyrim.esm`
   - `Update.esm`
   - `Hearthfires.esm`（如要支持炉火房产）
   - 所有你希望支持的 CC 插件（如 `ccBGSSSE005_Hendraheim.esl` 等）
2. 点击 OK 加载，等待完成。
3. 点击 **File → Save**，保存为 `TakeMeHomeApparition.esp`。
4. 建议将该插件设为 **ESL-flagged ESP**（使用 SSEEdit 添加 `ESL` 标志位），以节省插件槽。

---

## 3. 创建 FormList

### 3.1 解锁条件数据

| EditorID | 类型 | 内容说明 |
|----------|------|----------|
| `TMHA_AllHomeKeys` | FormList | 所有钥匙型房产的钥匙 Form（如 `WhiterunBreezehomeKey`） |
| `TMHA_KeyHomeIndices` | FormList | 对应 `TMHA_AllHomeKeys` 顺序的 `TMHA_Index_*` GlobalVariable |
| `TMHA_AllHomeQuests` | FormList | 所有任务型房产的 Quest（如 `ccBGSSSE005_HendraheimQuest`） |
| `TMHA_QuestHomeIndices` | FormList | 对应 `TMHA_AllHomeQuests` 顺序的 `TMHA_Index_*` GlobalVariable |
| `TMHA_QuestStages` | FormList | 对应 `TMHA_AllHomeQuests` 顺序的任务完成阶段 GlobalVariable（`TMHA_Stage_*`） |
| `TMHA_ProximityHomeIndices` | FormList | 所有距离型房产的 `TMHA_Index_*` GlobalVariable（顺序无关） |
| `TMHA_QuestMarkers` | FormList | **不再使用**，保留兼容（可留空） |

### 3.2 统一房产数据（按索引顺序排列）

| EditorID | 类型 | 内容说明 |
|----------|------|----------|
| `TMHA_AllHomeNames` | FormList | 房产名称 Message（索引 0 存放索引 0 的房产名称，依此类推） |
| `TMHA_AllHomeHolds` | FormList | 领地索引 GlobalVariable（索引位置存放对应 `TMHA_HoldIndex_*`） |
| `TMHA_AllHomeMarkers` | FormList | XMarker（索引位置存放对应 `TMHA_Marker_*`） |
| `TMHA_AllHomeLocationLists` | FormList | 专属 Location 子表单 FormList（索引位置存放 `TMHA_Loc_*`） |
| `TMHA_AllLocationsFlat` | FormList | 所有房产的全部 Location 扁平列表（用于快速查找） |

### 3.3 动态数据

| EditorID | 类型 | 内容说明 |
|----------|------|----------|
| `TMHA_UnlockedHomes` | FormList | 留空，脚本运行时动态填充已解锁房产的 XMarker |
| `TMHA_HoldNames` | FormList | 领地名称 Message（索引 0~8 对应九个领地） |

---

## 4. 创建 Message

### 4.1 领地名称（9 个）

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

### 4.2 房产名称（示例 17 处）

| 索引 | EditorID | Title |
|------|----------|-------|
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

## 5. 创建 GlobalVariable

### 5.1 领地索引 GlobalVariable（每个房产一个）

| 索引 | EditorID | Value |
|------|----------|-------|
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

### 5.2 统一房产索引 GlobalVariable（每个房产一个）

| 索引 | EditorID | Value |
|------|----------|-------|
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

### 5.3 任务阶段 GlobalVariable（7 个 CC 任务房产）

| EditorID | Value | 备注 |
|----------|-------|------|
| `TMHA_Stage_Hendraheim` | 0 | 0 表示 `IsCompleted()` |
| `TMHA_Stage_Myrwatch` | 0 | 同上 |
| `TMHA_Stage_Bloodchill` | 0 | 同上 |
| `TMHA_Stage_Gallows` | 0 | 同上 |
| `TMHA_Stage_GoldenHills` | 0 | 同上 |
| `TMHA_Stage_DeadMansDread` | 0 | 同上 |
| `TMHA_Stage_Nchuanthumz` | 0 | 同上 |

---

## 6. 放置 XMarker

你需要为每个房产在游戏世界中放置一个 XMarker（在 Cell View 中选择合适位置，右键 → New → XMarker）。

| 索引 | EditorID |
|------|----------|
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

另外放置一个 `TMHA_ReturnMarker` 在任意隐藏位置（如 Tamriel 世界空间中一个无人的角落），用于记录野外返回点。

---

## 7. 创建 Location 子表单

每个房产需要一个专属的 FormList（用作 Location 子表单），包含该房产的所有室内/室外 Location。例如：

| 索引 | EditorID | 包含的 Location |
|------|----------|-----------------|
| 0 | `TMHA_Loc_Breezehome` | `WhiterunBreezehomeLocation` |
| 1 | `TMHA_Loc_Honeyside` | `RiftenHoneysideLocation` |
| 2 | `TMHA_Loc_VlindrelHall` | `MarkarthVlindrelHallLocation` |
| 3 | `TMHA_Loc_Hjerim` | `WindhelmHjerimLocation` |
| 4 | `TMHA_Loc_Proudspire` | `SolitudeProudspireManorLocation` |
| 5 | `TMHA_Loc_Tundra` | `ccEEJSSE001_TundraHomesteadLocation` |
| 6 | `TMHA_Loc_Shadowfoot` | `ccEEJSSE003_ShadowfootSanctumLocation` |
| 7 | `TMHA_Loc_Lakeview` | `BYOHHouse1Location` + 室外 Location |
| 8 | `TMHA_Loc_Windstad` | `BYOHHouse2Location` + 室外 |
| 9 | `TMHA_Loc_Heljarchen` | `BYOHHouse3Location` + 室外 |
| 10 | `TMHA_Loc_Hendraheim` | `ccBGSSSE005_HendraheimLocation` |
| 11 | `TMHA_Loc_Myrwatch` | `ccEEJSSE002_MyrwatchLocation` |
| 12 | `TMHA_Loc_Bloodchill` | `ccBGSSSE004_BloodchillManorLocation` |
| 13 | `TMHA_Loc_Gallows` | `ccBGSSSE003_GallowsHallLocation` |
| 14 | `TMHA_Loc_GoldenHills` | `ccBGSSSE006_GoldenHillsLocation` |
| 15 | `TMHA_Loc_DeadMansDread` | `ccBGSSSE009_DeadMansDreadLocation` |
| 16 | `TMHA_Loc_Nchuanthumz` | `ccBGSSSE010_NchuanthumzLocation` |

注：炉火房产（索引 7-9）需要同时包含室内和室外 Location，因为室外区域也属于该房产。

---

## 8. 填充 FormList

### 8.1 `TMHA_HoldNames`
- 按索引 0-8 拖入 9 个领地名称 Message（`TMHA_Hold_Whiterun` 等）。

### 8.2 `TMHA_AllHomeNames`
- 按索引 0-16 拖入 17 个房产名称 Message（`TMHA_Name_Breezehome` 对应索引 0，`TMHA_Name_Honeyside` 对应索引 1，依此类推）。

### 8.3 `TMHA_AllHomeHolds`
- 按索引 0-16 拖入 17 个 `TMHA_HoldIndex_*` GlobalVariable。

### 8.4 `TMHA_AllHomeMarkers`
- 按索引 0-16 拖入 17 个 XMarker（`TMHA_Marker_Breezehome` 对应索引 0，依此类推）。

### 8.5 `TMHA_AllHomeLocationLists`
- 按索引 0-16 拖入 17 个 `TMHA_Loc_*` FormList。

### 8.6 `TMHA_AllLocationsFlat`
- 将所有房产的 Location（室内 + 室外 + 地下室）一次性拖入该 FormList，顺序不重要。

### 8.7 钥匙解锁条件 FormList

| FormList | 填充方法 |
|----------|---------|
| `TMHA_AllHomeKeys` | 将钥匙 Form 按索引 0-6 的顺序拖入（`WhiterunBreezehomeKey` → `RiftenHoneysideKey` → ... → `ccEEJSSE003_ShadowfootSanctumKey`） |
| `TMHA_KeyHomeIndices` | 按与 `TMHA_AllHomeKeys` 完全相同的顺序拖入对应的 `TMHA_Index_*`（`TMHA_Index_Breezehome` → `TMHA_Index_Honeyside` → ... → `TMHA_Index_Shadowfoot`） |

### 8.8 任务解锁条件 FormList

| FormList | 填充方法 |
|----------|---------|
| `TMHA_AllHomeQuests` | 将 7 个 CC 任务 Quest 拖入（如 `ccBGSSSE005_HendraheimQuest` → `ccEEJSSE002_MageTowerQuest` → ...） |
| `TMHA_QuestHomeIndices` | 按相同顺序拖入对应的 `TMHA_Index_*`（`TMHA_Index_Hendraheim` → `TMHA_Index_Myrwatch` → ...） |
| `TMHA_QuestStages` | 按相同顺序拖入对应的 `TMHA_Stage_*`（`TMHA_Stage_Hendraheim` → `TMHA_Stage_Myrwatch` → ...） |
| `TMHA_QuestMarkers` | 留空或保留旧数据（不再使用） |

### 8.9 距离解锁条件 FormList

| FormList | 填充方法 |
|----------|---------|
| `TMHA_ProximityHomeIndices` | 当前留空（等待将来添加距离房产时，按任意顺序拖入 `TMHA_Index_*`） |

---

## 9. 创建 Quest 和 Alias

### 9.1 创建主 Quest
- 在 Object Window 中右键空白处 → New → Quest。
- Editor ID: `TMHA_Quest`
- 勾选 `Start Game Enabled`
- 勾选 `Run Once`

### 9.2 创建 Player Alias
- 在 Quest 窗口中选择 Alias 标签页，右键 → New Reference Alias。
- Alias Name: `TMHA_PlayerAlias`
- Fill Type: `Specific Reference`
- Click `Select Reference` → 选择 `PlayerRef`。
- 在 `Scripts` 标签页中添加脚本 `TMHA_PlayerScript`（脚本将在步骤 10 中创建）。

### 9.3 创建 Quest 脚本（可选）
- 创建一个空脚本 `TMHA_QuestScript`，附加到 Quest 上。此脚本仅用于承载 Alias，不做任何操作。

---

## 10. 编写脚本

你需要两个脚本文件：**TMHA_PlayerScript.psc** 和 **TMHA_Apparition_Effect.psc**。

将以下两个脚本保存到 `Data\Scripts\Source\` 目录下。然后使用 Papyrus Compiler 或直接在 CK 中编译为 `.pex` 文件，放入 `Data\Scripts\`。

### 10.1 `TMHA_PlayerScript.psc`

```papyrus
; 重要功能摘要：
; - 监听钥匙、炉火任务、CC任务、距离触发四种解锁方式。
; - 维护 HomeUnlocked 数组（0~65）。
; - 更新 TMHA_UnlockedHomes FormList。
; - 构建缓存数组供 Effect 脚本读取。
```

### 10.2 `TMHA_Apparition_Effect.psc`

```papyrus
; 功能摘要：
; - 在房产内显示简化菜单，在野外显示领地菜单。
; - 处理三级菜单交互，执行传送与特效。
; - 通过 CachedPS 访问缓存数据。