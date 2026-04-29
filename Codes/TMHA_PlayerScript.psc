Scriptname TMHA_PlayerScript extends ReferenceAlias

; =============================================================================
; Take Me Home, Apparition - 主房产监控脚本 (统一索引版)
; 支持三种解锁方式：钥匙、任务、距离。所有房产共享0~65索引池。
; 新增房产只需在CK中操作FormList，无需修改脚本。
; =============================================================================

; -----------------------------------------------------------------------------
; 钥匙房产 - 解锁条件：获得钥匙
; -----------------------------------------------------------------------------
FormList Property TMHA_AllHomeKeys Auto          ; 钥匙Form列表
FormList Property TMHA_KeyHomeIndices Auto        ; 对应钥匙的房产索引 GlobalVariable 列表

; -----------------------------------------------------------------------------
; 炉火房产 (硬编码，但索引仍是7-9)
; -----------------------------------------------------------------------------
Quest Property BYOHHouseFalkreathQuest Auto
Quest Property BYOHHouseHjaalmarchQuest Auto
Quest Property BYOHHousePaleQuest Auto

ObjectReference Property Marker_Lakeview Auto
ObjectReference Property Marker_Windstad Auto
ObjectReference Property Marker_Heljarchen Auto

int LAKEVIEW = 7
int WINDSTAD = 8
int HELJARCHEN = 9

; -----------------------------------------------------------------------------
; 任务房产 - 解锁条件：完成对应任务
; -----------------------------------------------------------------------------
FormList Property TMHA_AllHomeQuests Auto         ; Quest列表
FormList Property TMHA_QuestHomeIndices Auto       ; 对应任务房产索引 GlobalVariable 列表
FormList Property TMHA_QuestMarkers Auto           ; (不再用于数据存储，保留兼容)
FormList Property TMHA_QuestStages Auto            ; 任务完成阶段 GlobalVariable 列表

; -----------------------------------------------------------------------------
; 距离房产 - 解锁条件：靠近门口XMarker
; -----------------------------------------------------------------------------
FormList Property TMHA_ProximityHomeIndices Auto   ; 距离房产索引 GlobalVariable 列表

; -----------------------------------------------------------------------------
; 通用数据 - 按房产索引位置存储
; -----------------------------------------------------------------------------
FormList Property TMHA_UnlockedHomes Auto          ; 动态填充的已解锁Marker列表
FormList Property TMHA_AllHomeNames Auto           ; 房产名称 Message（索引位置）
FormList Property TMHA_AllHomeHolds Auto           ; 领地索引 GlobalVariable（索引位置）
FormList Property TMHA_HoldNames Auto              ; 领地名称 Message（0-8）
FormList Property TMHA_AllLocationsFlat Auto       ; 所有房产Location扁平列表
FormList Property TMHA_AllHomeLocationLists Auto   ; 房产Location子表单（索引位置）
FormList Property TMHA_AllHomeMarkers Auto         ; 房产XMarker（索引位置，备用）

Book Property TMHA_Tome_Apparition Auto

; -----------------------------------------------------------------------------
; 缓存数组 (公开供 Effect 脚本读取，O(1)访问)
; -----------------------------------------------------------------------------
ObjectReference[] Property CachedMarkers Auto
int[] Property CachedHolds Auto
string[] Property CachedNames Auto
string[] Property CachedHoldNames Auto

; -----------------------------------------------------------------------------
; 内部变量
; -----------------------------------------------------------------------------
bool[] HomeUnlocked
bool TomeGranted = false
Actor PlayerRef

int LastKeyCount = 0
int LastQuestCount = 0
int lastNameCount = 0
int LastProxCount = 0

; =============================================================================
; 初始化
; =============================================================================
Event OnInit()
    PlayerRef = Game.GetPlayer()
    
    HomeUnlocked = new bool[66]
    int i = 0
    while i < 66
        HomeUnlocked[i] = false
        i += 1
    endwhile
    
    BuildCache()
    LastKeyCount = TMHA_AllHomeKeys.GetSize()
    LastQuestCount = TMHA_AllHomeQuests.GetSize()
    lastNameCount = TMHA_AllHomeNames.GetSize()
    LastProxCount = TMHA_ProximityHomeIndices.GetSize()
    
    ; 初始检测（加载存档时）
    CheckExistingKeys()
    CheckExistingHearthfireQuests()
    CheckExistingQuests()
    UpdateUnlockedHomesFormList()
    RegisterForSingleUpdate(2.0)
EndEvent

; =============================================================================
; 每2秒更新检测
; =============================================================================
Event OnUpdate()
    CheckForNewKeys()
    CheckForNewHearthfireQuests()
    CheckForNewQuests()
    CheckProximityHomes()
    
    ; 如果FormList长度变化，重建缓存并更新已解锁列表
    if TMHA_AllHomeKeys.GetSize() != LastKeyCount || \
       TMHA_AllHomeQuests.GetSize() != LastQuestCount || \
       TMHA_AllHomeNames.GetSize() != lastNameCount || \
       TMHA_ProximityHomeIndices.GetSize() != LastProxCount
        BuildCache()
        UpdateUnlockedHomesFormList()
        LastKeyCount = TMHA_AllHomeKeys.GetSize()
        LastQuestCount = TMHA_AllHomeQuests.GetSize()
        lastNameCount = TMHA_AllHomeNames.GetSize()
        LastProxCount = TMHA_ProximityHomeIndices.GetSize()
    endif
    
    RegisterForSingleUpdate(2.0)
EndEvent

; =============================================================================
; 缓存构建 - 从统一FormList按索引读取
; =============================================================================
Function BuildCache()
    ; 分配固定大小缓存数组
    CachedMarkers = new ObjectReference[66]
    CachedHolds = new int[66]
    CachedNames = new string[66]
    
    ; 遍历所有索引 (0~65)，从对应FormList读取数据
    int i = 0
    while i < 66
        ; Marker
        if i < TMHA_AllHomeMarkers.GetSize()
            CachedMarkers[i] = TMHA_AllHomeMarkers.GetAt(i) as ObjectReference
        endif
        
        ; 领地索引
        if i < TMHA_AllHomeHolds.GetSize()
            GlobalVariable gv = TMHA_AllHomeHolds.GetAt(i) as GlobalVariable
            if gv
                CachedHolds[i] = gv.GetValueInt()
            endif
        endif
        
        ; 名称
        if i < TMHA_AllHomeNames.GetSize()
            Message msg = TMHA_AllHomeNames.GetAt(i) as Message
            if msg
                CachedNames[i] = msg.GetName()
            endif
        endif
        
        i += 1
    endwhile
    
    ; 炉火房产硬编码名称/领地后备（如果CK中未正确填充）
    if CachedNames[7] == ""
        CachedNames[7] = "Lakeview Manor"
        CachedHolds[7] = 2
    endif
    if CachedNames[8] == ""
        CachedNames[8] = "Windstad Manor"
        CachedHolds[8] = 4
    endif
    if CachedNames[9] == ""
        CachedNames[9] = "Heljarchen Hall"
        CachedHolds[9] = 5
    endif
    
    ; 领地名称缓存 (0~8)
    CachedHoldNames = new string[9]
    i = 0
    while i < 9 && i < TMHA_HoldNames.GetSize()
        Message msg = TMHA_HoldNames.GetAt(i) as Message
        if msg
            CachedHoldNames[i] = msg.GetName()
        else
            CachedHoldNames[i] = "Unknown Hold"
        endif
        i += 1
    endwhile
EndFunction

; =============================================================================
; 钥匙检测 - 遍历所有钥匙，如果玩家拥有则解锁对应房产
; =============================================================================
Function CheckForNewKeys()
    int count = TMHA_AllHomeKeys.GetSize()
    int i = 0
    while i < count
        Form houseKey = TMHA_AllHomeKeys.GetAt(i)
        if houseKey && PlayerRef.GetItemCount(houseKey) > 0
            ; 从TMHA_KeyHomeIndices获取房产索引
            GlobalVariable g = TMHA_KeyHomeIndices.GetAt(i) as GlobalVariable
            if g
                int homeIndex = g.GetValueInt()
                if homeIndex >= 0 && homeIndex < HomeUnlocked.Length && !HomeUnlocked[homeIndex]
                    UnlockHome(homeIndex)
                    UpdateUnlockedHomesFormList()
                endif
            endif
        endif
        i += 1
    endwhile
EndFunction

Function CheckExistingKeys()
    int count = TMHA_AllHomeKeys.GetSize()
    int i = 0
    while i < count
        Form houseKey = TMHA_AllHomeKeys.GetAt(i)
        if houseKey && PlayerRef.GetItemCount(houseKey) > 0
            GlobalVariable g = TMHA_KeyHomeIndices.GetAt(i) as GlobalVariable
            if g
                int homeIndex = g.GetValueInt()
                if homeIndex >= 0 && homeIndex < HomeUnlocked.Length && !HomeUnlocked[homeIndex]
                    UnlockHome(homeIndex)
                endif
            endif
        endif
        i += 1
    endwhile
    UpdateUnlockedHomesFormList()
EndFunction

; =============================================================================
; 通用解锁函数 - 设置HomeUnlocked标记，通知并检查法术书
; =============================================================================
Function UnlockHome(int index)
    if index < 0 || index >= HomeUnlocked.Length
        return
    endif
    if HomeUnlocked[index]
        return
    endif
    HomeUnlocked[index] = true
    Debug.Notification(GetCachedName(index) + " now answers my call.")
    CheckTomeGrant()
EndFunction

Function CheckTomeGrant()
    if !TomeGranted && TMHA_Tome_Apparition
        TomeGranted = true
        PlayerRef.AddItem(TMHA_Tome_Apparition, 1)
        Debug.Notification("A tome of Apparition materializes in my pack.")
    endif
EndFunction

; =============================================================================
; 炉火任务检测 (硬编码索引7-9)
; =============================================================================
Function CheckForNewHearthfireQuests()
    if BYOHHouseFalkreathQuest && BYOHHouseFalkreathQuest.GetStage() >= 100 && !HomeUnlocked[LAKEVIEW]
        HomeUnlocked[LAKEVIEW] = true
        Debug.Notification(GetCachedName(LAKEVIEW) + " now answers my call.")
        UpdateUnlockedHomesFormList()
        CheckTomeGrant()
    endif
    if BYOHHouseHjaalmarchQuest && BYOHHouseHjaalmarchQuest.GetStage() >= 100 && !HomeUnlocked[WINDSTAD]
        HomeUnlocked[WINDSTAD] = true
        Debug.Notification(GetCachedName(WINDSTAD) + " now answers my call.")
        UpdateUnlockedHomesFormList()
        CheckTomeGrant()
    endif
    if BYOHHousePaleQuest && BYOHHousePaleQuest.GetStage() >= 100 && !HomeUnlocked[HELJARCHEN]
        HomeUnlocked[HELJARCHEN] = true
        Debug.Notification(GetCachedName(HELJARCHEN) + " now answers my call.")
        UpdateUnlockedHomesFormList()
        CheckTomeGrant()
    endif
EndFunction

Function CheckExistingHearthfireQuests()
    if BYOHHouseFalkreathQuest && BYOHHouseFalkreathQuest.GetStage() >= 100 && !HomeUnlocked[LAKEVIEW]
        HomeUnlocked[LAKEVIEW] = true
    endif
    if BYOHHouseHjaalmarchQuest && BYOHHouseHjaalmarchQuest.GetStage() >= 100 && !HomeUnlocked[WINDSTAD]
        HomeUnlocked[WINDSTAD] = true
    endif
    if BYOHHousePaleQuest && BYOHHousePaleQuest.GetStage() >= 100 && !HomeUnlocked[HELJARCHEN]
        HomeUnlocked[HELJARCHEN] = true
    endif
EndFunction

; =============================================================================
; 任务房产检测 (数据驱动)
; =============================================================================
Function CheckForNewQuests()
    int i = 0
    int count = TMHA_AllHomeQuests.GetSize()
    while i < count
        Quest q = TMHA_AllHomeQuests.GetAt(i) as Quest
        if q
            bool unlocked = false
            GlobalVariable stageVar = TMHA_QuestStages.GetAt(i) as GlobalVariable
            int requiredStage = 0
            if stageVar
                requiredStage = stageVar.GetValueInt()
            endif
            
            if requiredStage == 0
                unlocked = q.IsCompleted()
            else
                unlocked = q.GetStage() >= requiredStage
            endif
            
            if unlocked
                GlobalVariable g = TMHA_QuestHomeIndices.GetAt(i) as GlobalVariable
                if g
                    int homeIndex = g.GetValueInt()
                    if homeIndex >= 0 && homeIndex < HomeUnlocked.Length && !HomeUnlocked[homeIndex]
                        HomeUnlocked[homeIndex] = true
                        Debug.Notification(GetCachedName(homeIndex) + " now answers my call.")
                        UpdateUnlockedHomesFormList()
                        CheckTomeGrant()
                    endif
                endif
            endif
        endif
        i += 1
    endwhile
EndFunction

Function CheckExistingQuests()
    int i = 0
    int count = TMHA_AllHomeQuests.GetSize()
    while i < count
        Quest q = TMHA_AllHomeQuests.GetAt(i) as Quest
        if q
            bool unlocked = false
            GlobalVariable stageVar = TMHA_QuestStages.GetAt(i) as GlobalVariable
            int requiredStage = 0
            if stageVar
                requiredStage = stageVar.GetValueInt()
            endif
            
            if requiredStage == 0
                unlocked = q.IsCompleted()
            else
                unlocked = q.GetStage() >= requiredStage
            endif
            
            if unlocked
                GlobalVariable g = TMHA_QuestHomeIndices.GetAt(i) as GlobalVariable
                if g
                    int homeIndex = g.GetValueInt()
                    if homeIndex >= 0 && homeIndex < HomeUnlocked.Length && !HomeUnlocked[homeIndex]
                        HomeUnlocked[homeIndex] = true
                    endif
                endif
            endif
        endif
        i += 1
    endwhile
EndFunction

; =============================================================================
; 距离检测 - 遍历所有距离房产，靠近则解锁
; =============================================================================
Function CheckProximityHomes()
    int count = TMHA_ProximityHomeIndices.GetSize()
    int i = 0
    while i < count
        GlobalVariable g = TMHA_ProximityHomeIndices.GetAt(i) as GlobalVariable
        if g
            int homeIndex = g.GetValueInt()
            if homeIndex >= 0 && homeIndex < HomeUnlocked.Length && !HomeUnlocked[homeIndex]
                ; 从缓存获取Marker
                ObjectReference marker = None
                if homeIndex < CachedMarkers.Length
                    marker = CachedMarkers[homeIndex]
                endif
                if marker && PlayerRef.GetDistance(marker) < 300.0
                    HomeUnlocked[homeIndex] = true
                    string name = GetCachedName(homeIndex)
                    Debug.Notification(name + " now answers my call.")
                    UpdateUnlockedHomesFormList()
                    CheckTomeGrant()
                endif
            endif
        endif
        i += 1
    endwhile
EndFunction

; =============================================================================
; 更新已解锁列表 - 统一遍历HomeUnlocked数组，加入CachedMarkers非空的Marker
; =============================================================================
Function UpdateUnlockedHomesFormList()
    TMHA_UnlockedHomes.Revert()
    
    int i = 0
    while i < HomeUnlocked.Length
        if HomeUnlocked[i]
            ObjectReference marker = CachedMarkers[i]
            if marker
                ; 避免重复添加（理论上不会重复，但安全）
                if TMHA_UnlockedHomes.Find(marker) < 0
                    TMHA_UnlockedHomes.AddForm(marker)
                endif
            endif
        endif
        i += 1
    endwhile
EndFunction

; =============================================================================
; 从缓存获取名称
; =============================================================================
string Function GetCachedName(int index)
    if index >= 0 && index < CachedNames.Length
        return CachedNames[index]
    endif
    return "Your Sanctuary"
EndFunction

; =============================================================================
; 判断玩家是否在任意房产范围内
; =============================================================================
bool Function IsPlayerInAnyHomeArea()
    Location currentLoc = PlayerRef.GetCurrentLocation()
    if !currentLoc
        return false
    endif
    return TMHA_AllLocationsFlat.Find(currentLoc) >= 0
EndFunction