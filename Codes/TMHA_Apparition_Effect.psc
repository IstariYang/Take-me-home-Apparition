Scriptname TMHA_Apparition_Effect extends ActiveMagicEffect

; =============================================================================
; Take Me Home, Apparition - 幻影移形魔法效果 (统一索引版)
;
; 所有房产数据（Marker、名称、领地、Location 子表单）均通过 PlayerScript
; 的缓存数组 CachedMarkers、CachedNames、CachedHolds 获取，无需直接引用
; 各种 FormList。三种解锁方式（钥匙、任务、距离）共享统一索引池（0~65）。
;
; 特效流程：
;   施法 → InvFXShader 扭曲透明 3 秒 → 菜单弹出
;   选择目的地 → 传送 → 到达时 InvFXShader 扭曲透明 1 秒
; =============================================================================

; -----------------------------------------------------------------------------
; 属性 - 在 CK 中填充
; -----------------------------------------------------------------------------

; 已解锁房产的 XMarker 列表（动态填充）
FormList Property TMHA_UnlockedHomes Auto

; 野外记录点
ObjectReference Property TMHA_ReturnMarker Auto

; 到达时播放的粒子特效
Hazard Property TMHA_ApparitionHazard Auto

; 专属 Location 子表单的列表（用于排除当前房产，按房产索引排列）
FormList Property TMHA_AllHomeLocationLists Auto

; 到达时施放的短隐身法术（Duration = 1.0，扭曲透明 1 秒后消失）
Spell Property TMHA_Apparition_Spell_Arrive Auto

; -----------------------------------------------------------------------------
; 内部变量
; -----------------------------------------------------------------------------

; 玩家引用
Actor PlayerRef

; 领地索引数组（用于构建领地菜单）
int[] AvailableHolds

; 房产索引映射（用于房产菜单）
int[] HomeIndexMapping

; 每个领地的房产计数（预计算）
int[] holdCounts

; 房产索引缓存（预计算，避免重复遍历）
int[] homeIndexCache

; 领地去重标记（O(1) 查重）
bool[] HoldAdded

; 玩家施法时所在的 Location（用于排除当前房产）
Location cachedCurrentLoc

; 缓存的 PlayerScript 引用（避免重复 GetQuest + GetAliasByName）
TMHA_PlayerScript CachedPS

; =============================================================================
; 施法时触发
; =============================================================================

Event OnEffectStart(Actor akTarget, Actor akCaster)
    PlayerRef = akCaster
    CachedPS = GetPlayerScript()

    if CachedPS && CachedPS.IsPlayerInAnyHomeArea()
        ShowSimpleMenu()
    else
        TMHA_ReturnMarker.MoveTo(PlayerRef)
        Debug.Notification("This place lingers in my mind.")
        ShowHoldMenu()
    endif
EndEvent

; =============================================================================
; 获取 PlayerScript 引用（只调用一次，结果缓存到 CachedPS）
; =============================================================================

TMHA_PlayerScript Function GetPlayerScript()
    Quest q = Quest.GetQuest("TMHA_Quest")
    if !q
        return None
    endif
    return q.GetAliasByName("TMHA_PlayerAlias") as TMHA_PlayerScript
EndFunction

; =============================================================================
; 调试输出
; =============================================================================

Function PrintDebug(string msg)
    Debug.Trace(msg)
EndFunction

; =============================================================================
; 简化菜单 - 在房产内施法时显示
; =============================================================================

Function ShowSimpleMenu()
    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") as UIListMenu
    if !listMenu
        ReturnToRecordedPosition()
        return
    endif

    listMenu.AddEntryItem("Back to Where I Left")
    listMenu.AddEntryItem("Seek Another Sanctuary")
    listMenu.AddEntryItem("Stay Here")

    listMenu.OpenMenu()
    int result = listMenu.GetResultInt()

    if result == 0
        ReturnToRecordedPosition()
    elseif result == 1
        ShowHoldMenu()
    endif
EndFunction

; =============================================================================
; 领地菜单 - 在野外施法时显示
; =============================================================================

Function ShowHoldMenu()
    float startTime = Utility.GetCurrentRealTime()

    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") as UIListMenu
    float menuGetTime = Utility.GetCurrentRealTime() - startTime
    PrintDebug("[TMHA] GetMenu: " + menuGetTime)

    if !listMenu
        TeleportToFirstHome()
        return
    endif

    cachedCurrentLoc = PlayerRef.GetCurrentLocation()
    int unlockedCount = TMHA_UnlockedHomes.GetSize()

    if unlockedCount == 0
        Debug.Notification("No sanctuary calls to me... yet.")
        return
    endif

    ; ========================================
    ; 预计算
    ; ========================================
    holdCounts = new int[9]
    homeIndexCache = new int[66]
    HoldAdded = new bool[66]
    AvailableHolds = new int[66]
    int holdCount = 0
    int i = 0

    while i < unlockedCount
        homeIndexCache[i] = -1
        ObjectReference marker = TMHA_UnlockedHomes.GetAt(i) as ObjectReference
        if marker
            int hIdx = FindHomeIndex(marker)
            homeIndexCache[i] = hIdx
            if hIdx >= 0
                int h = GetCachedHold(hIdx)
                FormList homeLocList = TMHA_AllHomeLocationLists.GetAt(hIdx) as FormList
                if homeLocList && homeLocList.Find(cachedCurrentLoc) < 0
                    holdCounts[h] = holdCounts[h] + 1
                endif
            endif
        endif
        i = i + 1
    endwhile

    ; 构建领地菜单
    i = 0
    while i < unlockedCount
        int homeIndex = homeIndexCache[i]
        if homeIndex >= 0
            int holdIndex = GetCachedHold(homeIndex)
            if holdIndex >= 0 && holdIndex < 66 && !HoldAdded[holdIndex]
                HoldAdded[holdIndex] = true
                AvailableHolds[holdCount] = holdIndex
                string holdName = GetCachedHoldName(holdIndex)
                listMenu.AddEntryItem(holdName + " (" + holdCounts[holdIndex] + ")")
                holdCount = holdCount + 1
            endif
        endif
        i = i + 1
    endwhile

    float buildTime = Utility.GetCurrentRealTime() - startTime
    PrintDebug("[TMHA] Build menu: " + buildTime)

    listMenu.AddEntryItem("Stay Here")
    listMenu.OpenMenu()
    float totalTime = Utility.GetCurrentRealTime() - startTime
    PrintDebug("[TMHA] Total: " + totalTime)

    int result = listMenu.GetResultInt()

    if result >= 0 && result < holdCount
        ShowHomeMenu(AvailableHolds[result])
    endif
EndFunction

; =============================================================================
; 房产菜单 - 玩家选择领地后显示该领地的所有房产
; =============================================================================

Function ShowHomeMenu(int holdIndex)
    UIListMenu listMenu = UIExtensions.GetMenu("UIListMenu") as UIListMenu
    if !listMenu
        TeleportToFirstHome()
        return
    endif

    HomeIndexMapping = new int[66]
    int optionCount = 0
    int unlockedCount = TMHA_UnlockedHomes.GetSize()

    int i = 0
    while i < unlockedCount
        int hIdx = homeIndexCache[i]
        if hIdx >= 0 && GetCachedHold(hIdx) == holdIndex
            FormList homeLocList = TMHA_AllHomeLocationLists.GetAt(hIdx) as FormList
            if homeLocList && homeLocList.Find(cachedCurrentLoc) < 0
                listMenu.AddEntryItem(GetCachedName(hIdx))
                HomeIndexMapping[optionCount] = hIdx
                optionCount = optionCount + 1
            endif
        endif
        i = i + 1
    endwhile

    if optionCount == 0
        Debug.Notification("No other homes in this hold.")
        ShowHoldMenu()
        return
    endif

    listMenu.AddEntryItem("Back to Holds")
    listMenu.AddEntryItem("Stay Here")
    listMenu.OpenMenu()
    int result = listMenu.GetResultInt()

    if result >= 0 && result < optionCount
        int targetIdx = HomeIndexMapping[result]
        ObjectReference targetMarker = GetMarkerByHomeIndex(targetIdx)
        if targetMarker
            PlayerRef.MoveTo(targetMarker)
            Utility.Wait(1.0)
            TMHA_Apparition_Spell_Arrive.Cast(PlayerRef, PlayerRef)
            Utility.Wait(1.0)
            PlayerRef.PlaceAtMe(TMHA_ApparitionHazard)
            Debug.Notification("Apparated to " + GetCachedName(targetIdx))
        endif
    elseif result == optionCount
        ShowHoldMenu()
    endif
EndFunction

; =============================================================================
; 降级传送 - 菜单系统不可用时直接传送到第一个已解锁房产
; =============================================================================

Function TeleportToFirstHome()
    int unlockedCount = TMHA_UnlockedHomes.GetSize()
    if unlockedCount == 0
        Debug.Notification("No sanctuary calls to me... yet.")
        return
    endif
    ObjectReference firstMarker = TMHA_UnlockedHomes.GetAt(0) as ObjectReference
    if firstMarker
        PlayerRef.MoveTo(firstMarker)
        Utility.Wait(1.0)
        TMHA_Apparition_Spell_Arrive.Cast(PlayerRef, PlayerRef)
        Utility.Wait(1.0)
        PlayerRef.PlaceAtMe(TMHA_ApparitionHazard)
        Debug.Notification("Apparated to safety.")
    endif
EndFunction

; =============================================================================
; 返回野外记录点
; =============================================================================

Function ReturnToRecordedPosition()
    if TMHA_ReturnMarker.GetParentCell() != none
        PlayerRef.MoveTo(TMHA_ReturnMarker)
        Utility.Wait(1.0)
        TMHA_Apparition_Spell_Arrive.Cast(PlayerRef, PlayerRef)
        Utility.Wait(1.0)
        PlayerRef.PlaceAtMe(TMHA_ApparitionHazard)
        TMHA_ReturnMarker.MoveToMyEditorLocation()
        Debug.Notification("Returned to where I left off.")
    else
        Debug.Notification("My mind wanders... no place to return to.")
    endif
EndFunction

; =============================================================================
; 辅助函数
; =============================================================================

; -----------------------------------------------------------------------------
; FindHomeIndex - 根据 XMarker 查找对应的房产索引，遍历缓存数组
; -----------------------------------------------------------------------------
int Function FindHomeIndex(ObjectReference marker)
    if !CachedPS
        return -1
    endif
    int i = 0
    while i < CachedPS.CachedMarkers.Length
        if CachedPS.CachedMarkers[i] == marker
            return i
        endif
        i += 1
    endwhile
    return -1
EndFunction

; -----------------------------------------------------------------------------
; GetMarkerByHomeIndex - 直接从缓存获取 Marker
; -----------------------------------------------------------------------------
ObjectReference Function GetMarkerByHomeIndex(int homeIndex)
    if !CachedPS
        return None
    endif
    if homeIndex >= 0 && homeIndex < CachedPS.CachedMarkers.Length
        return CachedPS.CachedMarkers[homeIndex]
    endif
    return None
EndFunction

; -----------------------------------------------------------------------------
; GetCachedName - 从缓存获取房产名称
; -----------------------------------------------------------------------------
string Function GetCachedName(int index)
    if CachedPS && index >= 0 && index < CachedPS.CachedNames.Length
        return CachedPS.CachedNames[index]
    endif
    return "Your Sanctuary"
EndFunction

; -----------------------------------------------------------------------------
; GetCachedHold - 从缓存获取房产所属领地索引
; -----------------------------------------------------------------------------
int Function GetCachedHold(int index)
    if CachedPS && index >= 0 && index < CachedPS.CachedHolds.Length
        return CachedPS.CachedHolds[index]
    endif
    return 0
EndFunction

; -----------------------------------------------------------------------------
; GetCachedHoldName - 从缓存获取领地名称
; -----------------------------------------------------------------------------
string Function GetCachedHoldName(int holdIndex)
    if CachedPS && holdIndex >= 0 && holdIndex < CachedPS.CachedHoldNames.Length
        return CachedPS.CachedHoldNames[holdIndex]
    endif
    return "Unknown Hold"
EndFunction