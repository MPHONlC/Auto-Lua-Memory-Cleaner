-----------------------------------------------------------
-- Auto Lua Memory Cleaner (@APHONlC) | API: 101049
-----------------------------------------------------------
local ALC = {
    name = "AutoLuaMemoryCleaner",
    version = "0.0.5",
    -- Default settings
    defaults = {
        enabled = true,
        thresholdPC = 400,
        thresholdConsole = 85,
        fallbackDelayS = 300, -- 5 minutes (300 seconds)
        csaEnabled = true,
        logEnabled = not IsConsoleUI(),
        showUI = true,
        uiLocked = false,
        uiX = nil,
        uiY = nil,
        -- Stats
        totalCleanups = 0,
        totalMBFreed = 0,
        lastSessionCleanups = 0,
        lastSessionMBFreed = 0,
        prevSessionCleanups = 0,
        prevSessionMBFreed = 0,
        installDate = nil,
        versionHistory = {}
    },
    memState = 0,
    isMemCheckQueued = false,
    sessionCleanups = 0,
    sessionMBFreed = 0,
    lastPrioritySaveTime = 0
}
-- LibAddonMenu-2.0 Version
local REQUIRED_LAM_VERSION = 41

-- Check if LibAddonMenu-2.0 is running and get its loaded version
local function GetLAMVersion()
    local am = GetAddOnManager()
    for i = 1, am:GetNumAddOns() do
        local name, _, _, _, _, state = am:GetAddOnInfo(i)
        if name == "LibAddonMenu-2.0" and state == ADDON_STATE_ENABLED then
            return true, am:GetAddOnVersion(i)
        end
    end
    return false, 0
end

-- Live statistics
function ALC:GetStatsText()
    local currentMB = IsConsoleUI() and GetTotalUserAddOnMemoryPoolUsageMB() or (collectgarbage("count") / 1024)
    
    local memWarning = ""
    local luaLimitTxt = ""
    if IsConsoleUI() then
        luaLimitTxt = "100 MB (Hard Limit)"
        if currentMB > 85 then memWarning = "|cFF0000(EXCEEDS CONSOLE LIMIT)|r"
        else memWarning = "|c00FF00(Safe)|r" end
    else
        luaLimitTxt = "Dynamic [512MB] (Auto-Scaling)"
        if currentMB > 400 then memWarning = "|cFFA500(High Global Memory)|r"
        else memWarning = "|c00FF00(Safe)|r" end
    end
    
    local installDate = self.settings.installDate or "Unknown"
    local vHistory = self.settings.versionHistory or {self.version}
    local vHistoryText = table.concat(vHistory, ", ")
    
    local _, lamVersion = GetLAMVersion()
    local lamText = lamVersion > 0 and tostring(lamVersion) or "Not Installed"

    return string.format(
        "Installed Since: %s\nVersion History: %s\nLibAddonMenu-2.0 Version: %s\nMax Lua Memory: %s\nCurrent Global Memory: %.2f MB %s\n\n|c00FF00[Session Statistics]|r\nCleanups Triggered: %d\nMemory Freed: %.2f MB\n\n|cFFA500[Previous Session Statistics]|r\nCleanups Triggered: %d\nMemory Freed: %.2f MB\n\n|c00FFFF[Lifetime Statistics]|r\nTotal Cleanups: %d\nTotal Memory Freed: %.2f MB", 
        installDate, vHistoryText, lamText, luaLimitTxt, currentMB, memWarning,
        self.sessionCleanups, self.sessionMBFreed, 
        self.settings.prevSessionCleanups or 0, self.settings.prevSessionMBFreed or 0,
        self.settings.totalCleanups or 0, self.settings.totalMBFreed or 0
    )
end

-- Data Migration
function ALC:MigrateData()
    -- Erase obsolete data
    if self.settings then
        self.settings.pmOverridden = nil
    end

    if _G["AutoLuaCleaner"] then
        for worldName, worldData in pairs(_G["AutoLuaCleaner"]) do
            if type(worldData) == "table" then
                for accountName, accountData in pairs(worldData) do
                    if type(accountData) == "table" then
                        for profileId, profileData in pairs(accountData) do
                            if type(profileData) == "table" then
                                profileData["pmOverridden"] = nil
                            end
                        end
                    end
                end
            end
        end
    end
end

-- Memory Cleanup
function ALC:RunCleanup()
    self.memState = 1
    zo_callLater(function()
        local before = collectgarbage("count") / 1024
        collectgarbage("collect")
        local after = collectgarbage("count") / 1024
        local freed = before - after
        self.memState = 0
        
        -- Update session and lifetime statistics if memory was actually freed
        if freed > 0 then
            self.sessionCleanups = self.sessionCleanups + 1
            self.sessionMBFreed = self.sessionMBFreed + freed
            
            if self.settings then
                self.settings.totalCleanups = (self.settings.totalCleanups or 0) + 1
                self.settings.totalMBFreed = (self.settings.totalMBFreed or 0) + freed
                
                -- update last session data
                self.settings.lastSessionCleanups = self.sessionCleanups
                self.settings.lastSessionMBFreed = self.sessionMBFreed
                
                -- save without reloading UI
                local now = GetGameTimeMilliseconds()
                if (now - self.lastPrioritySaveTime) >= 900000 then
                    GetAddOnManager():RequestAddOnSavedVariablesPrioritySave(ALC.name)
                    self.lastPrioritySaveTime = now
                end
            end
        end
        
        local msg = string.format("Memory Freed %.2f MB", freed)
        
        if self.settings.logEnabled and CHAT_SYSTEM then
            CHAT_SYSTEM:AddMessage("|c00FFFF[ALC]|r " .. msg)
        end
        
        if self.settings.csaEnabled and CENTER_SCREEN_ANNOUNCE then
            local params = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.NONE)
            params:SetText("|c00FFFF" .. msg .. "|r")
            params:SetLifespanMS(4000)
            CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(params)
        end

        self:UpdateUI()
    end, 500)
end

function ALC:TriggerMemoryCheck(checkType, delay)
    if not self.settings.enabled then return end
    if self.memState == 1 or self.isMemCheckQueued then return end -- Prevent overlapping checks if a cleanup is already happening
    -- Check if memory is above platform threshold. If not, IGNORE.
    local currentMB = IsConsoleUI() and GetTotalUserAddOnMemoryPoolUsageMB() or (collectgarbage("count") / 1024)
    local threshold = IsConsoleUI() and self.settings.thresholdConsole or self.settings.thresholdPC 

    if currentMB >= threshold then
        local inCombat = IsUnitInCombat and IsUnitInCombat("player")
        if inCombat or IsUnitDead("player") then return end

        self.isMemCheckQueued = true -- Lock the queue
        -- Start delay
        zo_callLater(function()
            self.isMemCheckQueued = false
            if self.memState == 1 then return end
            -- check state after delay
            local stillInCombat = IsUnitInCombat and IsUnitInCombat("player")
            if stillInCombat or IsUnitDead("player") then return end
            -- Menu Intent Check
            if checkType == "Menu" then
                local inMenu = SCENE_MANAGER and not (SCENE_MANAGER:IsShowing("hud") or SCENE_MANAGER:IsShowing("hudui"))
                if not inMenu then return end -- Exited before 2s ran out, IGNORE
            end
            -- Memory Check & Execution
            local recheckMB = IsConsoleUI() and GetTotalUserAddOnMemoryPoolUsageMB() or (collectgarbage("count") / 1024)
            if recheckMB >= threshold then
                self:RunCleanup()
                -- Fallback timer
                EVENT_MANAGER:UnregisterForUpdate(ALC.name .. "_Fallback")
                EVENT_MANAGER:RegisterForUpdate(ALC.name .. "_Fallback", self.settings.fallbackDelayS * 1000, function() 
                    ALC:TriggerMemoryCheck("Fallback", 0) 
                end)
            end
        end, delay)
    else
        -- Go Dormant and kill Timers
        EVENT_MANAGER:UnregisterForUpdate(ALC.name .. "_Fallback")
        self.memState = 0
    end
end

-- UI
function ALC:UpdateUIAnchor()
    if not self.uiWindow then return end
    self.uiWindow:ClearAnchors()
    
    if self.settings.uiX and self.settings.uiY then
        -- UI drag logic
        self.uiWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.settings.uiX, self.settings.uiY)
    else
        -- No saved position, snap to the left side of the compass
        local xOffset = 0
        if _G["PP"] then xOffset = 0.5 end
        
        if IsConsoleUI() then 
            self.uiWindow:SetAnchor(RIGHT, ZO_Compass, LEFT, -15, 0)
        else 
            self.uiWindow:SetAnchor(RIGHT, ZO_Compass, LEFT, -25 - xOffset, -5) 
        end
    end
end

function ALC:UpdateUI()
    if not self.settings.showUI then return end
    
    local currentMB = IsConsoleUI() and GetTotalUserAddOnMemoryPoolUsageMB() or (collectgarbage("count") / 1024)
    local color = "|c00FF00"
    if currentMB >= 470 then
        color = "|cFF0000"
    elseif currentMB >= 400 then
        color = "|cFFA500"
    end
    
    self.uiLabel:SetText(string.format("|c00FFFF[ALC]|r Memory Usage: %s%.2f MB|r", color, currentMB))
    self.uiWindow:SetDimensions(self.uiLabel:GetTextWidth() + 20, self.uiLabel:GetTextHeight() + 10)
end

function ALC:UpdateUIScenes()
    if not self.hudFragment then return end
    
    -- Scene Manager, where UI can be seen
    local scenes = {"hud", "hudui", "gamepad_hud"}
    
    for _, name in ipairs(scenes) do
        local scene = SCENE_MANAGER:GetScene(name)
        if scene then
            if self.settings.showUI then
                scene:AddFragment(self.hudFragment)
            else
                scene:RemoveFragment(self.hudFragment)
            end
        end
    end
    
    if not self.settings.showUI then
        self.uiWindow:SetHidden(true)
    end
end

function ALC:CreateUI()
    local ui = WINDOW_MANAGER:CreateControl("AutoLuaCleanerUI", GuiRoot, CT_TOPLEVELCONTROL)
    ui:SetClampedToScreen(true)
    ui:SetMouseEnabled(true)
    ui:SetMovable(not self.settings.uiLocked)
    ui:SetHidden(true) -- Default to hidden, Scene Manager will reveal it
    
    self.uiWindow = ui
    self:UpdateUIAnchor()
    
    ui:SetHandler("OnMoveStop", function(control) 
        ALC.settings.uiX = control:GetLeft()
        ALC.settings.uiY = control:GetTop()
    end)
    
    local bg = WINDOW_MANAGER:CreateControl("AutoLuaCleanerBG", ui, CT_BACKDROP)
    bg:SetAnchor(TOPLEFT, ui, TOPLEFT, 0, 0)
    bg:SetAnchor(BOTTOMRIGHT, ui, BOTTOMRIGHT, 0, 0)
    bg:SetCenterColor(0, 0, 0, 0.6)
    bg:SetEdgeColor(0.6, 0.6, 0.6, 0.8)
    bg:SetEdgeTexture(nil, 1, 1, 1, 0)
    
    local label = WINDOW_MANAGER:CreateControl("AutoLuaCleanerLabel", ui, CT_LABEL)
    if IsInGamepadPreferredMode() then 
        label:SetFont("ZoFontGamepad22") 
    else 
        label:SetFont("ZoFontGameSmall") 
    end
    label:SetColor(1, 1, 1, 1)
    label:SetText("[ALC] Loading...")
    label:SetAnchor(CENTER, ui, CENTER, 0, 0)
    
    self.uiLabel = label
    
    -- UI update
    local lastUpdate = 0
    ui:SetHandler("OnUpdate", function(control, time)
        if not ALC.settings.showUI then return end
        if time - lastUpdate < 1.0 then return end
        lastUpdate = time
        ALC:UpdateUI()
    end)
    
    self.hudFragment = ZO_HUDFadeSceneFragment:New(ui)
    self:UpdateUIScenes()
end

-- LibAddonMenu UI Settings
function ALC:BuildMenu()
    -- Check LAM version and prevent menu from loading if LAM is outdated
    local isLAMInstalled, lamVersion = GetLAMVersion()
    if not isLAMInstalled then return end

    if lamVersion < REQUIRED_LAM_VERSION then
        zo_callLater(function()
            local msg = string.format("|cFFFF00Warning: LibAddonMenu is outdated (v%d). Update to v%d+ for ALC menu.|r", lamVersion, REQUIRED_LAM_VERSION)
            if CHAT_SYSTEM then CHAT_SYSTEM:AddMessage("|cFF0000[ALC]|r " .. msg) end
            if CENTER_SCREEN_ANNOUNCE then
                local params = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.NONE)
                params:SetText(msg); params:SetLifespanMS(6000)
                CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(params)
            end
        end, 4000)
        return
    end

    local LAM = LibAddonMenu2 or _G["LibAddonMenu"]
    if not LAM then return end

    local panelData = {
        type = "panel",
        name = "|c9CD04CAuto Lua Memory Cleaner|r",
        displayName = "|c00FFFFAuto Lua Memory Cleaner|r",
        author = "@|ca500f3A|r|cb400e6P|r|cc300daH|r|cd200cdO|r|ce100c1NlC|r",
        version = self.version,
        registerForRefresh = true
    }
    
    local optionsData = {}
    
    if IsConsoleUI() then
        table.insert(optionsData, { type = "button", name = "|c00FF00ALC LIVE STATS|r", tooltip = function() return ALC:GetStatsText() end, func = function() end, width = "full" })
        local consoleCmds = "|c00FF00/alcon|r - Toggle Auto Cleanup\n|c00FF00/alcui|r - Toggle Memory UI visibility\n|c00FF00/alclock|r - Lock/Unlock UI dragging\n|c00FF00/alcreset|r - Reset Memory UI position\n|c00FF00/alccsa|r - Toggle Screen Announcements\n|c00FF00/alcclean|r - Force manual cleanup"
        table.insert(optionsData, { type = "button", name = "|c00FF00COMMANDS INFO|r", tooltip = consoleCmds, func = function() end, width = "full" })
    end
    
    local isEU = (GetWorldName() == "EU Megaserver")
    if not IsConsoleUI() and not isEU then
        table.insert(optionsData, {
            type = "button",
            name = "|cFFD700DONATE|r to @|ca500f3A|r|cb400e6P|r|cc300daH|r|cd200cdO|r|ce100c1NlC|r",
            tooltip = "Opens the in-game mail. Thank you! Donations help support continued development and maintenance.",
            func = function()
                SCENE_MANAGER:Show("mailSend")
                zo_callLater(function()
                    ZO_MailSendToField:SetText("@APHONlC")
                    ZO_MailSendSubjectField:SetText("Auto Lua Cleaner Support")
                    ZO_MailSendBodyField:TakeFocus()
                end, 200)
            end,
            width = "full"
        })
        table.insert(optionsData, { type = "divider" })
    end
    
    table.insert(optionsData, {
        type = "checkbox",
        name = "Enable Auto Cleanup",
        tooltip = "Allows the addon to clean memory automatically when it hits your thresholds.",
        getFunc = function() return ALC.settings.enabled end,
        setFunc = function(value) ALC.settings.enabled = value end
    })

    if IsConsoleUI() then
        table.insert(optionsData, {
            type = "slider",
            name = "Console Memory Threshold (MB)",
            tooltip = "Triggers a cleanup when console memory hits this amount (Default: 85). Console hard-limit is 100MB.",
            min = 10, max = 95, step = 1,
            getFunc = function() return ALC.settings.thresholdConsole end,
            setFunc = function(value) ALC.settings.thresholdConsole = value end
        })
    else
        table.insert(optionsData, {
            type = "slider",
            name = "PC Memory Threshold (MB)",
            tooltip = "Triggers a cleanup when global Lua memory hits this amount (Default: 400).",
            min = 50, max = 800, step = 10,
            getFunc = function() return ALC.settings.thresholdPC end,
            setFunc = function(value) ALC.settings.thresholdPC = value end
        })
    end

    table.insert(optionsData, {
        type = "slider",
        name = "Repeat Cleanup Delay (Seconds)",
        tooltip = "If memory is still over the threshold after a cleanup, how long should it wait before trying again? (Default: 300s / 5mins)",
        min = 30, max = 1200, step = 10,
        getFunc = function() return ALC.settings.fallbackDelayS end,
        setFunc = function(value) ALC.settings.fallbackDelayS = value end
    })
    
    table.insert(optionsData, { type = "divider" })
    
    if not IsConsoleUI() then
        table.insert(optionsData, {
            type = "checkbox",
            name = "Enable Chat Logs",
            tooltip = "Shows status messages in your chat window when memory is cleaned.",
            getFunc = function() return ALC.settings.logEnabled end,
            setFunc = function(value) ALC.settings.logEnabled = value end
        })
    end
    
    table.insert(optionsData, {
        type = "checkbox",
        name = "Screen Announcements",
        tooltip = "Shows a large text alert on screen when memory is freed.",
        getFunc = function() return ALC.settings.csaEnabled end,
        setFunc = function(value) ALC.settings.csaEnabled = value end
    })
    
    table.insert(optionsData, { type = "divider" })
    
    table.insert(optionsData, {
        type = "checkbox",
        name = "Show Memory UI",
        tooltip = "Displays a draggable on-screen tracker of your current Lua memory usage.",
        getFunc = function() return ALC.settings.showUI end,
        setFunc = function(value) 
            ALC.settings.showUI = value
            ALC:UpdateUIScenes() 
        end
    })
    
    table.insert(optionsData, {
        type = "checkbox",
        name = "Lock UI Position",
        tooltip = "Prevents the Memory UI from being dragged.",
        getFunc = function() return ALC.settings.uiLocked end,
        setFunc = function(value) 
            ALC.settings.uiLocked = value
            if ALC.uiWindow then ALC.uiWindow:SetMovable(not value) end
        end,
        disabled = function() return not ALC.settings.showUI end
    })

    table.insert(optionsData, {
        type = "button",
        name = "|cFF0000RESET UI POSITION|r",
        tooltip = "Snaps the UI back to the left side of the compass.",
        func = function() 
            ALC.settings.uiX = nil
            ALC.settings.uiY = nil
            ALC:UpdateUIAnchor()
            if ALC.settings.logEnabled and CHAT_SYSTEM then
                CHAT_SYSTEM:AddMessage("|c00FFFF[ALC]|r UI Position Reset.")
            end
        end,
        disabled = function() return not ALC.settings.showUI end
    })

    table.insert(optionsData, { type = "divider" })

    table.insert(optionsData, {
        type = "button",
        name = "|c00FFFFFORCE MANUAL CLEANUP|r",
        tooltip = "Instantly clears Lua memory.",
        func = function() ALC:RunCleanup() end,
        width = "full"
    })
    
    if not IsConsoleUI() then
        local liveStatsBlock = { type = "submenu", name = "ALC Live Statistics", tooltip = "Live tracking of memory cleanup data.", controls = {
            { type = "description", title = "|c00FFFFLive Statistics|r", text = "Loading statistics...", reference = "ALC_StatsText" }
        }}
        
        local pcCmdsText = "|c00FF00/alcon|r - Toggle Auto Cleanup\n|c00FF00/alcui|r - Toggle Memory UI visibility\n|c00FF00/alclock|r - Lock/Unlock UI dragging\n|c00FF00/alcreset|r - Reset Memory UI position\n|c00FF00/alccsa|r - Toggle Screen Announcements\n|c00FF00/alclogs|r - Toggle Chat Logs\n|c00FF00/alcclean|r - Force manual cleanup"
        local commandsInfoBlock = { type = "description", title = "Commands Info", text = pcCmdsText }
        
        table.insert(optionsData, liveStatsBlock)
        table.insert(optionsData, commandsInfoBlock)
    end
    
    table.insert(optionsData, { type = "divider" })
    
    if IsConsoleUI() then
        table.insert(optionsData, {
            type = "button",
            name = "|cFFD700Buy Me A Coffee|r",
            tooltip = "Thank you! Donations help support continued development and maintenance!\n\nLink: https://buymeacoffee.com/aph0nlc",
            func = function() end,
            width = "full"
        })
        table.insert(optionsData, {
            type = "button",
            name = "|cFF0000BUG REPORT|r",
            tooltip = "Found an issue? Report it on ESOUI or Github:\n\nhttps://www.esoui.com/portal.php?id=360&a=listbugs",
            func = function() end,
            width = "full"
        })
    else
        table.insert(optionsData, {
            type = "button",
            name = "|cFFD700Buy Me A Coffee|r",
            tooltip = "Thank you! Donations help support continued development and maintenance! Opens a secure link to my Buy Me A Coffee page in your default web browser.",
            func = function() 
                RequestOpenUnsafeURL("https://buymeacoffee.com/aph0nlc") 
            end,
            width = "full"
        })
        table.insert(optionsData, {
            type = "button",
            name = "|cFF0000BUG REPORT|r",
            tooltip = "Found an issue? Opens the Bug Portal on ESOUI in your default web browser.",
            func = function() 
                RequestOpenUnsafeURL("https://www.esoui.com/portal.php?id=360&a=listbugs") 
            end,
            width = "full"
        })
    end

    LAM:RegisterAddonPanel("AutoLuaCleanerOptions", panelData)
    LAM:RegisterOptionControls("AutoLuaCleanerOptions", optionsData)
end

function ALC:IntegrateWithPermMemento()
    local pmCore = _G["PermMementoCore"]
    if pmCore and type(pmCore) == "table" and pmCore.settings then
        pmCore.settings.autoCleanup = false
        pmCore.settings.csaCleanupEnabled = false
        EVENT_MANAGER:UnregisterForUpdate(pmCore.name .. "_MemFallback")
    end
end

-- Initialization
function ALC:Init(eventCode, addOnName)
    if addOnName ~= self.name then return end
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
    
    local world = GetWorldName() or "Default"
    self.settings = ZO_SavedVars:NewAccountWide("AutoLuaCleaner", 1, "AccountWide", self.defaults, world)
    
    -- Run Data Migration first
    self:MigrateData()

    -- Manage Session Statistics for previous session data
    self.settings.prevSessionCleanups = self.settings.lastSessionCleanups or 0
    self.settings.prevSessionMBFreed = self.settings.lastSessionMBFreed or 0
    self.settings.lastSessionCleanups = 0
    self.settings.lastSessionMBFreed = 0
    
    if not self.settings.installDate then
        local d = GetDate()
        if d and type(d) == "number" then d = tostring(d) end
        if d and string.len(d) == 8 then
            self.settings.installDate = string.sub(d, 1, 4) .. "/" .. string.sub(d, 5, 6) .. "/" .. string.sub(d, 7, 8)
        else
            self.settings.installDate = GetDateStringFromTimestamp(GetTimeStamp())
        end
    end
    
    if not self.settings.versionHistory then self.settings.versionHistory = {} end
    local vLen = #self.settings.versionHistory
    if vLen == 0 or self.settings.versionHistory[vLen] ~= self.version then
        table.insert(self.settings.versionHistory, self.version)
        if #self.settings.versionHistory > 3 then table.remove(self.settings.versionHistory, 1) end
    end
    
    self:CreateUI()
    self:BuildMenu()
    
    if not IsConsoleUI() then
        EVENT_MANAGER:RegisterForUpdate(ALC.name .. "_StatsUpdate", 1000, function()
            local statsCtrl = _G["ALC_StatsText"]
            if statsCtrl and statsCtrl.desc and not statsCtrl:IsHidden() then
                statsCtrl.desc:SetText(ALC:GetStatsText())
            end
        end)
    end
    
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, function() 
        self:IntegrateWithPermMemento()
        self:TriggerMemoryCheck("ZoneLoad", 5000) 
    end)
    
    EVENT_MANAGER:RegisterForEvent(self.name .. "_CombatState", EVENT_PLAYER_COMBAT_STATE, function(eventCode, inCombat)
        if not inCombat then self:TriggerMemoryCheck("CombatEnd", 3000) end
    end)
    
    if SCENE_MANAGER then
        SCENE_MANAGER:RegisterCallback("SceneStateChanged", function(scene, oldState, newState)
            if newState == SCENE_SHOWN then
                if scene.name ~= "hud" and scene.name ~= "hudui" then
                    self:TriggerMemoryCheck("Menu", 2000)
                end
            end
        end)
    end

    -- Slash Commands
    SLASH_COMMANDS["/alc"] = function(extra)
        local cmd = extra:lower()
        if cmd == "" then
            local cmds = "|c00FF00Available ALC Commands:|r\n"
            cmds = cmds .. "|c00FFFF/alcon|r - Toggle Auto Cleanup\n"
            cmds = cmds .. "|c00FFFF/alcui|r - Toggle Memory UI visibility\n"
            cmds = cmds .. "|c00FFFF/alclock|r - Lock/Unlock UI dragging\n"
            cmds = cmds .. "|c00FFFF/alcreset|r - Reset Memory UI position\n"
            cmds = cmds .. "|c00FFFF/alccsa|r - Toggle Screen Announcements\n"
            if not IsConsoleUI() then
                cmds = cmds .. "|c00FFFF/alclogs|r - Toggle Chat Logs\n"
            end
            cmds = cmds .. "|c00FFFF/alcclean|r - Force a manual Lua memory cleanup"
            if CHAT_SYSTEM then CHAT_SYSTEM:AddMessage(cmds) end
            return
        end
    end
    -- Command Aliases
    SLASH_COMMANDS["/alcon"] = function()
        self.settings.enabled = not self.settings.enabled
        local status = self.settings.enabled and "|c00FF00ON|r" or "|cFF0000OFF|r"
        if CHAT_SYSTEM then CHAT_SYSTEM:AddMessage("|c00FFFF[ALC]|r Auto Cleanup: " .. status) end
    end

    SLASH_COMMANDS["/alcui"] = function()
        self.settings.showUI = not self.settings.showUI
        self:UpdateUIScenes()
        local status = self.settings.showUI and "|c00FF00VISIBLE|r" or "|cFF0000HIDDEN|r"
        if CHAT_SYSTEM then CHAT_SYSTEM:AddMessage("|c00FFFF[ALC]|r Memory UI: " .. status) end
    end

    SLASH_COMMANDS["/alclock"] = function()
        self.settings.uiLocked = not self.settings.uiLocked
        if self.uiWindow then self.uiWindow:SetMovable(not self.settings.uiLocked) end
        local status = self.settings.uiLocked and "|cFF0000LOCKED|r" or "|c00FF00UNLOCKED|r"
        if CHAT_SYSTEM then CHAT_SYSTEM:AddMessage("|c00FFFF[ALC]|r UI Position: " .. status) end
    end

    SLASH_COMMANDS["/alcreset"] = function()
        self.settings.uiX = nil; self.settings.uiY = nil; self:UpdateUIAnchor()
        if CHAT_SYSTEM then CHAT_SYSTEM:AddMessage("|c00FFFF[ALC]|r UI Position Reset.") end
    end

    SLASH_COMMANDS["/alccsa"] = function()
        self.settings.csaEnabled = not self.settings.csaEnabled
        local status = self.settings.csaEnabled and "|c00FF00ON|r" or "|cFF0000OFF|r"
        if CHAT_SYSTEM then CHAT_SYSTEM:AddMessage("|c00FFFF[ALC]|r Screen Announcements: " .. status) end
    end

    if not IsConsoleUI() then
        SLASH_COMMANDS["/alclogs"] = function()
            self.settings.logEnabled = not self.settings.logEnabled
            local status = self.settings.logEnabled and "|c00FF00ON|r" or "|cFF0000OFF|r"
            if CHAT_SYSTEM then CHAT_SYSTEM:AddMessage("|c00FFFF[ALC]|r Chat Logs: " .. status) end
        end
    end

    SLASH_COMMANDS["/alcclean"] = function() self:RunCleanup() end
end

EVENT_MANAGER:RegisterForEvent(ALC.name, EVENT_ADD_ON_LOADED, function(...) ALC:Init(...) end)
