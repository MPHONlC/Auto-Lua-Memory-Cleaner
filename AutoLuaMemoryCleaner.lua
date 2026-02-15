-----------------------------------------------------------
-- Auto Lua Memory Cleaner (@APHONlC) | API: 101049
-----------------------------------------------------------
local ALC = {
    name = "AutoLuaMemoryCleaner",
    version = "0.0.2",
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
        uiY = nil
    },
    memState = 0,
    isMemCheckQueued = false
}

function ALC:RunCleanup()
    self.memState = 1
    zo_callLater(function()
        local before = collectgarbage("count") / 1024
        collectgarbage("collect")
        local after = collectgarbage("count") / 1024
        local freed = before - after
        self.memState = 0
        
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
    if self.memState == 1 or self.isMemCheckQueued then return end 

    local currentMB = IsConsoleUI() and GetTotalUserAddOnMemoryPoolUsageMB() or (collectgarbage("count") / 1024)
    local threshold = IsConsoleUI() and self.settings.thresholdConsole or self.settings.thresholdPC 

    if currentMB >= threshold then
        local inCombat = IsUnitInCombat and IsUnitInCombat("player")
        if inCombat or IsUnitDead("player") then return end

        self.isMemCheckQueued = true 

        zo_callLater(function()
            self.isMemCheckQueued = false
            if self.memState == 1 then return end

            local stillInCombat = IsUnitInCombat and IsUnitInCombat("player")
            if stillInCombat or IsUnitDead("player") then return end

            if checkType == "Menu" then
                local inMenu = SCENE_MANAGER and not (SCENE_MANAGER:IsShowing("hud") or SCENE_MANAGER:IsShowing("hudui"))
                if not inMenu then return end 
            end

            local recheckMB = IsConsoleUI() and GetTotalUserAddOnMemoryPoolUsageMB() or (collectgarbage("count") / 1024)
            if recheckMB >= threshold then
                self:RunCleanup()
                
                EVENT_MANAGER:UnregisterForUpdate(ALC.name .. "_Fallback")
                EVENT_MANAGER:RegisterForUpdate(ALC.name .. "_Fallback", self.settings.fallbackDelayS * 1000, function() 
                    ALC:TriggerMemoryCheck("Fallback", 0) 
                end)
            end
        end, delay)
    else
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

-- Settings Menu
function ALC:BuildMenu()
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
        ALC.settings.pmOverridden = true
    end
end

-- Initialization
function ALC:Init(eventCode, addOnName)
    if addOnName ~= self.name then return end
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
    
    local world = GetWorldName() or "Default"
    self.settings = ZO_SavedVars:NewAccountWide("AutoLuaCleaner", 1, "AccountWide", self.defaults, world)
    
    self:CreateUI()
    self:BuildMenu()
    
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
end

EVENT_MANAGER:RegisterForEvent(ALC.name, EVENT_ADD_ON_LOADED, function(...) ALC:Init(...) end)
