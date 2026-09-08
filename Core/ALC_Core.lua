-- AutoLuaMemoryCleaner - Copyright 2025-2026 @APHONlC. 
-- Licensed under the GNU General Public License v3.0 (GPLv3). 
-- See LICENSE.md and NOTICE.md.

-- Loads first

local function IsConsoleUI()
    return IsInGamepadPreferredMode()
end

ALC = {
    name = "AutoLuaMemoryCleaner",
    version = "0.0.9",
    schema_version = 2,
    defaults = {
        schema_version = 2,
        is_enabled = true,
        threshold_pc = 200,
        threshold_console = 60,
        pool_threshold_pc = 10,
        pool_threshold_console = 10,
        fallback_delay_sec = 300,
        is_csa_enabled = true,
        is_log_enabled = true,
        show_ui = true,
        is_ui_locked = true,
        ui_x = nil,
        ui_y = nil,
        ui_scale = 1.0,
        is_ui_global = false,
        has_shown_lib_warning_008 = false,
        is_lib_warning_enabled = true,
        wizard_completed = false,
        install_date = nil,
        last_version = nil,
        version_history = {},
        submenu_open = {},
        warned_module_labels = {},
        override_language = nil,
        auto_clear_pool_on_teleport = true,
        pool_reload_delay_sec = 3,
        pool_reload_test_pending = false,
        pool_reload_test_before_mb = 0,
        last_pool_reload_time = 0
    },
    mem_state = 0,
    is_mem_check_queued = false,
    session_mb_freed = 0,
    session_pool_mb_freed = 0,
    last_priority_save_time = 0,
    last_ui_update = 0,
    is_scene_callback_registered = false,
    scene_callback_fn = nil,
    ui_update_fn = nil
}

ALC.REQUIRED_LAM_VERSION = 43
ALC.REQUIRED_LHAS_VERSION = 20200

ALC._modules = {}
ALC.MODULE_FILE_FUNCS = {
    migration = { "migrate_data" },
    wizard = { "run_wizard", "run_wizard_if_needed" },
    menu = { "build_language_controls", "build_lam2_menu" },
    ui = { "get_gamepad_mover", "toggle_ui_update", "update_ui_anchor", "update_ui", "create_ui", "update_ui_scenes" },
}

function ALC.call_optional(fn, label, ...)
    return LibAPH.CallOptional(ALC.settings.warned_module_labels, "|c00FFFF[ALC]|r",
        "is unavailable (unloaded via Module Manager) - skipping.", fn, label, ...)
end

function ALC.toggle_module_disabled(mod_key, silent)
    local now_disabled = LibAPH.ToggleModuleDisabled(ALC.settings, ALC.MODULE_FILE_FUNCS, mod_key, function(disabled, key)
        local applied_live = LibAPH.HasModuleLifecycle(key)
        d("|c00FFFF[ALC]|r " .. (disabled and ALC.L("MODULE_TOGGLE_UNLOADED", key) or ALC.L("MODULE_TOGGLE_REENABLED", key)) ..
          (applied_live and ALC.L("MODULE_TOGGLE_LIVE") or ALC.L("MODULE_TOGGLE_RELOAD")))
    end, silent)

    if not now_disabled then
        ALC.settings.warned_module_labels = {}
    end
    LibAPH.SyncModuleLifecycle(ALC._modules, mod_key, now_disabled)
    return now_disabled
end

function ALC.apply_module_disable_overrides()
    LibAPH.ApplyModuleDisableOverrides(ALC.settings, ALC.MODULE_FILE_FUNCS, ALC._modules, function(fname)
        ALC[fname] = nil
    end)
end

function ALC.reset_to_defaults()
    LibAPH.ResetToDefaults(ALC.settings, ALC.defaults, {
        wizard_completed = true, has_shown_lib_warning_008 = true
    })
end

function ALC.get_hybrid_memory_data()
    return collectgarbage("count") / 1024
end

function ALC.get_console_pool_mb()
    return GetTotalUserAddOnMemoryPoolUsageMB() or 0
end

ALC.PC = ALC.PC or {}
ALC.Console = ALC.Console or {}

local function get_platform_module()
    return IsConsoleUI() and ALC.Console or ALC.PC
end

function ALC.get_active_memory_mb()
    local mod = get_platform_module()
    if mod.get_active_memory_mb then return mod.get_active_memory_mb() end
    return ALC.get_hybrid_memory_data()
end

function ALC.get_active_threshold()
    local mod = get_platform_module()
    if mod.get_threshold then return mod.get_threshold() end
    return ALC.settings.threshold_pc
end

function ALC.get_active_pool_threshold()
    local mod = get_platform_module()
    if mod.get_pool_threshold then return mod.get_pool_threshold() end
    return ALC.settings.pool_threshold_pc
end

function ALC.platform_build_threshold_slider(build_data)
    local mod = get_platform_module()
    if mod.build_threshold_slider then mod.build_threshold_slider(build_data) end
end

function ALC.platform_build_pool_threshold_slider(build_data)
    local mod = get_platform_module()
    if mod.build_pool_threshold_slider then mod.build_pool_threshold_slider(build_data) end
end

function ALC.platform_build_extra_options(build_data)
    local mod = get_platform_module()
    if mod.build_extra_options then mod.build_extra_options(build_data) end
end

local ALC_PC_SERVICE_NAMES = { Steam = "Steam", Epic = "Epic Games Store", ZOS = "ZOS Launcher", DMM = "DMM" }

function ALC.get_platform_str()
    local platform = LibAPH.GetPlatformString()
    if platform == "PC" then
        local service = ALC_PC_SERVICE_NAMES[LibAPH.GetPlatformServiceName()]
        if service then
            return string.format("%s (%s)", ALC.L("MODE_PC"), service)
        end
        return ALC.L("MODE_PC")
    elseif platform then
        return platform
    end
    return ALC.L("NOT_FOUND")
end

function ALC.get_settings_library()
    local lam_v, lam_e = LibAPH.CheckLibraryVersion("LibAddonMenu-2.0")
    local lhas_v, lhas_e = 0, false
    if IsConsoleUI() then
        lhas_v, lhas_e = LibAPH.CheckLibraryVersion("LibHarvensAddonSettings")
    end
    return lam_v, lam_e, lhas_v, lhas_e
end

function ALC.format_memory(value_mb)
    if value_mb >= 1048576 then return string.format("%.2f TB", value_mb / 1048576)
    elseif value_mb >= 1024 then return string.format("%.2f GB", value_mb / 1024)
    elseif value_mb >= 1 then return string.format("%.2f MB", value_mb)
    else return string.format("%d KB", math.floor(value_mb * 1024)) end
end

function ALC.get_today_date_str()
    local raw_d = GetDate()
    if raw_d and type(raw_d) == "number" then raw_d = tostring(raw_d) end
    if raw_d and string.len(raw_d) == 8 then
        return string.sub(raw_d, 1, 4) .. "/" .. string.sub(raw_d, 5, 6) .. "/" .. string.sub(raw_d, 7, 8)
    end
    return GetDateStringFromTimestamp(GetTimeStamp())
end

ALC.COLOR_LUA_ACTIVE = "|c00FF00"   -- green: current Lua heap
ALC.COLOR_POOL_ACTIVE = "|c00FFFF"  -- cyan: current console pool
ALC.COLOR_CLEANED = "|c888888"      -- grey: amount freed

function ALC.get_lua_status_color(mb)
    if mb >= 512 then return "|cFF0000" elseif mb >= 320 then return "|cFFA500" else return ALC.COLOR_LUA_ACTIVE end
end
function ALC.get_pool_status_color(mb)
    local cap = GetTotalUserAddOnMemoryPoolCapacityMB() or 100
    if mb >= cap then return "|cFF0000" elseif mb >= cap * 0.6 then return "|cFFA500" else return ALC.COLOR_POOL_ACTIVE end
end

function ALC.build_memory_fragment(label, color, current_mb, cleaned_mb)
    local base = string.format("%s: %s%s|r", label, color, ALC.format_memory(current_mb))
    if cleaned_mb and cleaned_mb > 0.001 then
        base = base .. string.format(" %s(-%s)|r", ALC.COLOR_CLEANED, ALC.format_memory(cleaned_mb))
    end
    return base
end

function ALC.build_memory_status_line(current_lua, lua_cleaned, current_pool, pool_cleaned)
    return ALC.build_memory_fragment(ALC.L("LABEL_LUA"), ALC.get_lua_status_color(current_lua), current_lua, lua_cleaned) ..
        "  " .. ALC.build_memory_fragment(ALC.L("LABEL_POOL"), ALC.get_pool_status_color(current_pool), current_pool, pool_cleaned)
end

function ALC.build_memory_status_lines(current_lua, lua_cleaned, current_pool, pool_cleaned)
    return ALC.build_memory_fragment(ALC.L("LABEL_LUA"), ALC.get_lua_status_color(current_lua), current_lua, lua_cleaned) ..
        "\n" .. ALC.build_memory_fragment(ALC.L("LABEL_POOL"), ALC.get_pool_status_color(current_pool), current_pool, pool_cleaned)
end

local function format_lib(ver, en, name, req)
    return LibAPH.FormatLibraryVersion(ver, en, req, {
        missing = function() return "|cFF0000" .. ALC.L("NOT_FOUND") .. "|r" end,
        disabled = function(v) return string.format("|cFF0000%s (v%d) %s|r", name, v, ALC.L("STATE_DISABLED")) end,
        exact = function(v) return string.format("|c00FF00%s (v%d)|r", name, v) end,
        old = function(v, r) return string.format("|c888888%s|r |cFF0000%s|r |c00FFFF%s|r", name, ALC.L("STATE_OLD", v), ALC.L("STATE_EXPECTED", r)) end,
        newer = function(v, r) return string.format("|c00FFFF%s %s %s|r", name, ALC.L("STATE_NEWER", v), ALC.L("STATE_EXPECTED", r)) end,
    })
end

local ALC_MODULE_FILES = {
    migration = "MODULE/ALC_Migration.lua",
    wizard = "MODULE/ALC_Wizard.lua",
    menu = "MODULE/ALC_Menu.lua",
    ui = "MODULE/ALC_UI.lua",
}

local function alc_module_state(mod_key)
    return (ALC._modules[mod_key] == false) and "unloaded" or "loaded"
end

function ALC.build_client_info_text()
    local lam_ver, lam_en, lhas_ver, lhas_en = ALC.get_settings_library()
    local lam_str = format_lib(lam_ver, lam_en, "LAM2", ALC.REQUIRED_LAM_VERSION)
    local lhas_str = format_lib(lhas_ver, lhas_en, "LHAS", ALC.REQUIRED_LHAS_VERSION)

    local install_date = ALC.settings.install_date or ALC.L("INSTALL_DATE_UNKNOWN")
    local today_str = ALC.get_today_date_str()
    local install_line = LibAPH.FormatInstallDateLine(install_date, today_str)

    local v_hist = ALC.settings.version_history or {ALC.version}
    local v_hist_str = LibAPH.FormatVersionHistory(v_hist, ALC.version)

    local wizard_str = ALC.settings.wizard_completed
        and ("|c00FF00" .. ALC.L("WIZARD_SETUP_DONE") .. "|r")
        or ("|cFFA500" .. ALC.L("WIZARD_NOT_YET_RUN") .. "|r")

    local file_lines_str = LibAPH.BuildModuleFileList(
        { "migration", "wizard", "menu", "ui" },
        ALC_MODULE_FILES,
        alc_module_state,
        { loaded = ALC.L("FILE_LOADED"), unloaded = ALC.L("FILE_UNLOADED_BY_USER") }
    )

    local libaph_str = "|c00FF00LibAPH (v" .. LibAPH.VERSION .. ")|r"
    local library_version_str = libaph_str .. ", " .. lam_str
    if IsConsoleUI() then
        library_version_str = library_version_str .. ", " .. lhas_str
    end

    local info_lines = {
        ALC.L("FIELD_INSTALLED_SINCE") .. " " .. install_line,
        ALC.L("FIELD_VERSION_HISTORY") .. " " .. v_hist_str,
        ALC.L("FIELD_LIBRARY_VERSION") .. " " .. library_version_str,
        ALC.L("FIELD_PLATFORM") .. " |cFFFFFF" .. ALC.get_platform_str() .. "|r",
    }
    table.insert(info_lines, ALC.L("FIELD_WIZARD") .. " " .. wizard_str)

    local lang_code = (ALC.settings and ALC.settings.override_language) or GetCVar("Language.2")
    table.insert(info_lines, ALC.L("FIELD_CURRENT_LANGUAGE") .. " |cFFFFFF" .. ALC.get_language_display_name(lang_code) .. "|r")

    table.insert(info_lines, ALC.L("FIELD_FILES") .. "\n  " .. file_lines_str)

    return table.concat(info_lines, "\n")
end

function ALC.show_copy_text_box(plain_text)
    ALC.copy_box = ALC.copy_box or LibAPH.CreateCopyTextBox({
        name = "ALCCopyBox",
        closeText = ALC.L("BTN_CLOSE"),
        titleText = ALC.L("BUG_REPORT_COPY_TITLE"),
    })
    ALC.copy_box:Show(plain_text)
end

function ALC.get_bug_report_settings_fields()
    return {
        { key = "is_enabled", label = ALC.L("CHK_AUTO_LUA_CLEANUP") },
        { key = "is_csa_enabled", label = ALC.L("CHK_CSA") },
        { key = "is_log_enabled", label = ALC.L("CHK_CHAT_LOGS") },
        { key = "show_ui", label = ALC.L("CHK_SHOW_UI") },
        { key = "is_ui_locked", label = ALC.L("CHK_LOCK_UI") },
        { key = "is_ui_global", label = ALC.L("CHK_RENDER_IN_MENUS") },
        { key = "auto_clear_pool_on_teleport", label = ALC.L("CHK_AUTO_POOL_CLEANUP") },
    }
end

function ALC.show_bug_report_box()
    local error_section
    if ALC.last_own_error then
        error_section = ALC.L("BUG_REPORT_COPY_PROMPT") .. ALC.last_own_error
    else
        error_section = ALC.L("BUG_REPORT_NONE_CAPTURED", ALC.name) .. ALC.L("BUG_REPORT_DESCRIBE_INSTEAD")
    end

    local on_word, off_word = ALC.L("WORD_ON"), ALC.L("WORD_OFF")
    local settings_lines = LibAPH.FormatSettingsSnapshot(ALC.settings, ALC.get_bug_report_settings_fields(), on_word, off_word)

    local text = LibAPH.BuildBugReportText({
        statsText = ALC.build_client_info_text(),
        settingsLines = settings_lines,
        fieldSettingsLabel = ALC.L("FIELD_SETTINGS"),
        errorSection = error_section,
    })

    ALC.show_copy_text_box(text)
end

function ALC.hook_error_capture()
    LibAPH.HookErrorCapture(ALC.name, function(text)
        ALC.last_own_error = text
    end)
end

function ALC.build_command_list_text(double_spaced)
    local sep = double_spaced and "\n\n" or "\n"
    local lines = {}
    for _, cat in ipairs(ALC.COMMAND_CATEGORIES) do
        local cat_lines = {}
        for _, c in ipairs(cat.cmds) do
            local nonexistent_here = (c.pc_only and IsConsoleUI()) or (c.console_only and not IsConsoleUI())
            local is_off = c.disabled_check and c.disabled_check()
            if not nonexistent_here and not is_off then
                table.insert(cat_lines, string.format("|c00FFFF%s|r |cFFD700- %s|r%s", c.cmd, ALC.L(c.desc_key), sep))
            end
        end
        if #cat_lines > 0 then
            table.insert(lines, string.format("|c00FF00[%s]|r%s", ALC.L(cat.title_key), sep))
            for _, l in ipairs(cat_lines) do table.insert(lines, l) end
        end
    end
    return table.concat(lines)
end

function ALC.toggle_core_events()
    if ALC.settings.is_enabled then
        EVENT_MANAGER:RegisterForEvent(ALC.name .. "_CombatState", EVENT_PLAYER_COMBAT_STATE, 
            function(event_code, in_combat) 
                if not in_combat then ALC.trigger_memory_check("CombatEnd", 3000) end 
            end
        )
        EVENT_MANAGER:RegisterForEvent(ALC.name .. "_LowMem", EVENT_LUA_LOW_MEMORY, 
            function()
                if IsConsoleUI() then
                    ALC.run_manual_cleanup()
                end
            end
        )
        EVENT_MANAGER:RegisterForUpdate(ALC.name .. "_AutoSweep", 5000,
            function()
                if not IsPlayerMoving() then
                    ALC.trigger_memory_check("Idle", 1000)
                else
                    ALC.trigger_memory_check("AutoSweep", 0)
                end
            end
        )

        if not ALC.is_scene_callback_registered then
            ALC.scene_callback_fn = function(scene, old_state, new_state)
                if new_state == SCENE_SHOWN then
                    local s_name = scene:GetName()
                    if s_name ~= "hud" and s_name ~= "hudui" and s_name ~= "gamepad_hud" then 
                        ALC.trigger_memory_check("Menu", 6000) 
                    end
                end
            end
            SCENE_MANAGER:RegisterCallback("SceneStateChanged", ALC.scene_callback_fn)
            ALC.is_scene_callback_registered = true
        end
    else
        EVENT_MANAGER:UnregisterForEvent(ALC.name .. "_CombatState", EVENT_PLAYER_COMBAT_STATE)
        EVENT_MANAGER:UnregisterForEvent(ALC.name .. "_LowMem", EVENT_LUA_LOW_MEMORY)
        EVENT_MANAGER:UnregisterForUpdate(ALC.name .. "_AutoSweep")
        if ALC.is_scene_callback_registered then
            SCENE_MANAGER:UnregisterCallback("SceneStateChanged", ALC.scene_callback_fn)
            ALC.is_scene_callback_registered = false
        end
        EVENT_MANAGER:UnregisterForUpdate(ALC.name .. "_Fallback")
        ALC.mem_state = 0
        ALC.is_mem_check_queued = false
    end
end

function ALC.safe_csa(title, body, lifespan_ms)
    LibAPH.SafeCSA(ALC.settings.is_csa_enabled, title, body, lifespan_ms or 4000)
end

function ALC.run_manual_cleanup(force_feedback)
    ALC.mem_state = 1
    ALC.last_cleanup_time = GetGameTimeMilliseconds()
    LibAPH.RunDoubleGCPass({
        getPoolMB = ALC.get_console_pool_mb,
        onDone = function(before_lua, after_lua, freed, before_pool, after_pool, freed_pool)
            ALC.mem_state = 0

            if freed > 0.001 or freed_pool > 0.001 then
                ALC.session_mb_freed = ALC.session_mb_freed + freed
                ALC.session_pool_mb_freed = ALC.session_pool_mb_freed + freed_pool

                local msg = ALC.build_memory_status_line(after_lua, freed, after_pool, freed_pool)

                if ALC.settings.is_log_enabled then
                    ALC.chat:Print(msg)
                end
                ALC.safe_csa(ALC.L("CSA_TITLE_CLEANED"), ALC.build_memory_status_lines(after_lua, freed, after_pool, freed_pool))
            elseif force_feedback then
                local msg = ALC.build_memory_status_line(after_lua, 0, after_pool, 0) .. " |c888888" .. ALC.L("LABEL_ALREADY_CLEAN") .. "|r"
                if ALC.settings.is_log_enabled then
                    ALC.chat:Print(msg)
                end
                ALC.safe_csa(ALC.L("CSA_TITLE_ALREADY_CLEAN"), ALC.build_memory_status_lines(after_lua, 0, after_pool, 0))
            end

            if ALC.settings.show_ui then ALC.call_optional(ALC.update_ui, "UI module (update_ui)") end
        end,
    })
end

function ALC.trigger_memory_check(check_type, delay)
    if not ALC.settings.is_enabled then return end
    if ALC.mem_state == 1 or ALC.is_mem_check_queued then return end
    
    local now_ms = GetGameTimeMilliseconds()
    local fallback_ms = ALC.settings.fallback_delay_sec * 1000
    if (now_ms - (ALC.last_cleanup_time or 0)) < fallback_ms then return end
    
    local current_metric = ALC.get_active_memory_mb()
    local limit_threshold = ALC.get_active_threshold()

    if current_metric >= limit_threshold then
        local in_combat = IsUnitInCombat("player")
        if in_combat or IsUnitDead("player") then 
            if ALC.settings.show_ui then ALC.call_optional(ALC.update_ui, "UI module (update_ui)") end
            return 
        end

        ALC.is_mem_check_queued = true
        zo_callLater(function()
            ALC.is_mem_check_queued = false
            if ALC.mem_state == 1 then return end
            
            local still_in_combat = IsUnitInCombat("player")
            if still_in_combat or IsUnitDead("player") then 
                if ALC.settings.show_ui then ALC.call_optional(ALC.update_ui, "UI module (update_ui)") end
                return 
            end
            
            if check_type == "Menu" then
                local is_hud = SCENE_MANAGER:IsShowing("hud")
                local is_hudui = SCENE_MANAGER:IsShowing("hudui")
                local in_menu = not (is_hud or is_hudui)
                if not in_menu then return end 
            end
            
            local recheck_metric = ALC.get_active_memory_mb()
            if recheck_metric >= limit_threshold then
                ALC.run_manual_cleanup()
                EVENT_MANAGER:UnregisterForUpdate(ALC.name .. "_Fallback")
                EVENT_MANAGER:RegisterForUpdate(ALC.name .. "_Fallback", 
                    ALC.settings.fallback_delay_sec * 1000, 
                    function() ALC.trigger_memory_check("Fallback", 0) end
                )
            end
        end, delay)
    else
        EVENT_MANAGER:UnregisterForUpdate(ALC.name .. "_Fallback")
        ALC.mem_state = 0
    end
end

function ALC.L(key, ...)
    local id = _G["SI_ALC_" .. key]
    local str = id and GetString(id) or key
    if select("#", ...) > 0 then
        return string.format(str, ...)
    end
    return str
end

function ALC.get_available_languages()
    local list = {}
    for code in pairs(ALC.Lang or {}) do
        table.insert(list, code)
    end
    table.sort(list)
    return list
end

function ALC.get_language_display_name(code)
    return ALC.LANGUAGE_NAMES[code] or code
end

function ALC.show_missing_library_warning()
    if not ALC.settings.is_lib_warning_enabled then return end

    local lam_ver, lam_en, lhas_ver, lhas_en = ALC.get_settings_library()

    local libwarn_templates = {
        missing = ALC.L("LIBWARN_MISSING"),
        disabled = ALC.L("LIBWARN_DISABLED"),
        old = ALC.L("LIBWARN_OLD"),
    }

    local alerts = {}
    local lam_alert = LibAPH.BuildLibraryWarning(libwarn_templates, "LibAddonMenu", "LAM", lam_ver, lam_en, ALC.REQUIRED_LAM_VERSION,
        ALC.L("LIBWARN_CONSEQUENCE_LAM"))
    if lam_alert then table.insert(alerts, lam_alert) end

    if IsConsoleUI() then
        local lhas_alert = LibAPH.BuildLibraryWarning(libwarn_templates, "LibHarvensAddonSettings", "LHAS", lhas_ver, lhas_en, ALC.REQUIRED_LHAS_VERSION,
            ALC.L("LIBWARN_CONSEQUENCE_LHAS"))
        if lhas_alert then table.insert(alerts, lhas_alert) end
    end

    if #alerts == 0 then return end

    if not ALC.settings.has_shown_lib_warning_008 then
        local dialog_id = "ALC_MISSING_LIBRARY_WARN"
        local popup_title = "|cFF0000" .. ALC.L("DIALOG_MISSING_LIBRARY_TITLE") .. "|r"
        local popup_body = ALC.L("DIALOG_MISSING_LIBRARY_BODY") .. "\n\n" .. table.concat(alerts, "\n\n")

        local function on_ack()
            ALC.settings.has_shown_lib_warning_008 = true
            local tick_ms = GetGameTimeMilliseconds()
            if (tick_ms - ALC.last_priority_save_time) >= 900000 then
                GetAddOnManager():RequestAddOnSavedVariablesPrioritySave(ALC.name)
                ALC.last_priority_save_time = tick_ms
            end
        end

        if not ESO_Dialogs[dialog_id] then
            ESO_Dialogs[dialog_id] = {
                canQueue = true,
                gamepadInfo = { dialogType = GAMEPAD_DIALOGS.BASIC },
                title = { text = popup_title },
                mainText = { text = popup_body },
                buttons = { { text = ALC.L("BTN_ACKNOWLEDGE_CLOSE"), keybind = "DIALOG_PRIMARY", callback = on_ack } }
            }
        end

        zo_callLater(function()
            if IsInGamepadPreferredMode() then ZO_Dialogs_ShowGamepadDialog(dialog_id)
            else ZO_Dialogs_ShowDialog(dialog_id) end
        end, 2000)
    end

    local combined_msg = table.concat(alerts, "\n")

    zo_callLater(function()
        ALC.chat_error:Print(combined_msg)

        if not ALC.settings.has_shown_lib_warning_008 then
            local params = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.NONE)
            params:SetText("|cFF0000" .. ALC.L("CSA_TITLE_SETTINGS_UNAVAILABLE") .. "|r", combined_msg)
            params:SetLifespanMS(10000)
            CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(params)
        end
    end, 4000)
end

function ALC.on_player_teleported()
    if not ALC.settings.auto_clear_pool_on_teleport then return end

    local pool_mb = ALC.get_console_pool_mb()
    if pool_mb < ALC.get_active_pool_threshold() then return end

    local now = GetTimeStamp()
    if (now - (ALC.settings.last_pool_reload_time or 0)) < ALC.settings.fallback_delay_sec then return end
    ALC.settings.last_pool_reload_time = now

    ALC.settings.pool_reload_test_pending = true
    ALC.settings.pool_reload_test_before_mb = pool_mb
    ALC.settings.pool_reload_test_before_lua_mb = ALC.get_hybrid_memory_data()

    local reload_delay_sec = ALC.settings.pool_reload_delay_sec or 3
    ALC.safe_csa("|c00FFFF" .. ALC.L("CHAT_POOL_RELOAD_NOTICE", reload_delay_sec) .. "|r")

    ALC.pool_reload_token = (ALC.pool_reload_token or 0) + 1
    local my_token = ALC.pool_reload_token
    zo_callLater(function()
        if ALC.pool_reload_token ~= my_token
            or not IsPlayerActivated()
            or IsUnitInCombat("player")
            or IsUnitDead("player") then
            ALC.settings.pool_reload_test_pending = false
            return
        end
        ReloadUI("ingame")
    end, reload_delay_sec * 1000)
end

function ALC.report_pool_reload_result(before_pool, before_lua, after_pool)
    local after_lua = ALC.get_hybrid_memory_data()
    local freed_pool = math.max(before_pool - after_pool, 0)
    local freed_lua = math.max(before_lua - after_lua, 0)

    if freed_lua > 0.01 then ALC.session_mb_freed = ALC.session_mb_freed + freed_lua end
    if freed_pool > 0.01 then ALC.session_pool_mb_freed = ALC.session_pool_mb_freed + freed_pool end

    if ALC.settings.is_log_enabled then
        ALC.chat:Print(ALC.build_memory_status_line(after_lua, freed_lua, after_pool, freed_pool))
    end
    ALC.safe_csa(ALC.L("CSA_TITLE_POOL_CLEARED"), ALC.build_memory_status_lines(after_lua, freed_lua, after_pool, freed_pool))
    if ALC.settings.show_ui then ALC.call_optional(ALC.update_ui, "UI module (update_ui)") end
end

function ALC.check_pool_reload_test_result()
    if not ALC.settings.pool_reload_test_pending then return end
    ALC.settings.pool_reload_test_pending = false

    local before_pool = ALC.settings.pool_reload_test_before_mb or 0
    local before_lua = ALC.settings.pool_reload_test_before_lua_mb or 0
    local last_reading = nil

    local function poll(attempt)
        local cur_pool = ALC.get_console_pool_mb()
        local settled = last_reading and math.abs(cur_pool - last_reading) < 0.01
        if settled or attempt >= 6 then
            ALC.report_pool_reload_result(before_pool, before_lua, cur_pool)
            return
        end
        last_reading = cur_pool
        zo_callLater(function() poll(attempt + 1) end, 500)
    end

    zo_callLater(function() poll(1) end, 500)
end

function ALC.integrate_with_perm_memento()
    local pm_core = _G["PermMementoCore"]
    if pm_core and type(pm_core) == "table" and pm_core.settings then
        pm_core.settings.is_auto_cleanup = false
        pm_core.settings.is_csa_cleanup_enabled = false
        EVENT_MANAGER:UnregisterForUpdate(pm_core.name .. "_MemFallback")
    end
end

function ALC.init(event_code, addon_name)
    if addon_name ~= ALC.name then return end
    EVENT_MANAGER:UnregisterForEvent(ALC.name, EVENT_ADD_ON_LOADED)

    ALC.chat = LibAPH.CreateChatLogger("ALC", "00FFFF")
    ALC.chat_error = LibAPH.CreateChatLogger("ALC Error", "FF0000")

    LibAPH.LoadLocalization("SI_ALC_", ALC.Lang, "en")

    local active_world = GetWorldName() or "Default"
    local sv_name = "AutoLuaCleaner"
    local account = GetDisplayName()

    if _G[sv_name] and _G[sv_name][active_world] and _G[sv_name][active_world][account] then
        _G[sv_name][active_world] = nil
    end

    local existing_ns = _G[sv_name] and _G[sv_name]["Default"] and _G[sv_name]["Default"][account]
        and _G[sv_name]["Default"][account]["$AccountWide"]
    local existing_data = existing_ns and existing_ns[active_world]
    if existing_data and existing_data.schema_version ~= ALC.schema_version then
        existing_ns[active_world] = nil
        d("|c00FFFF[ALC]|r " .. ALC.L("CHAT_SETTINGS_RESET_OLDVERSION"))
    end

    ALC.settings = ZO_SavedVars:NewAccountWide(
        sv_name, 1, active_world, ALC.defaults
    )
    ALC.settings.schema_version = ALC.schema_version

    if ALC.settings.override_language then
        LibAPH.LoadLocalization("SI_ALC_", ALC.Lang, "en", ALC.settings.override_language)
    end

    ALC.settings.module_disabled = ALC.settings.module_disabled or {}
    local migration_needs_run = (ALC.settings.migrated_version ~= ALC.version)
    if migration_needs_run then
        ALC.settings.module_disabled.migration = false
    end

    ALC.apply_module_disable_overrides()

    ALC.call_optional(ALC.migrate_data, "Migration module (migrate_data)")
    if migration_needs_run then
        ALC.settings.migrated_version = ALC.version
        ALC.settings.module_disabled.migration = true
    end
    ALC.check_pool_reload_test_result()
    
    if not ALC.settings.install_date then
        ALC.settings.install_date = ALC.get_today_date_str()
    end
    
    LibAPH.CheckSelfVersion(ALC.settings, ALC.version)

    ALC.show_missing_library_warning()

    ALC.session_mb_freed = 0
    ALC.session_pool_mb_freed = 0
    
    ALC.call_optional(ALC.create_ui, "UI module (create_ui)")
    ALC.call_optional(ALC.build_lam2_menu, "Menu module (build_lam2_menu)")
    ALC.hook_error_capture()
    ALC.toggle_core_events()
    ALC.call_optional(ALC.toggle_ui_update, "UI module (toggle_ui_update)")
    ALC.call_optional(ALC.run_wizard_if_needed, "Wizard module (run_wizard_if_needed)")

    EVENT_MANAGER:RegisterForEvent(ALC.name, EVENT_PLAYER_ACTIVATED, function()
        ALC.integrate_with_perm_memento()
        ALC.trigger_memory_check("ZoneLoad", 5000)
        ALC.on_player_teleported()
    end)

    EVENT_MANAGER:RegisterForEvent(ALC.name .. "_PoolReloadGuard", EVENT_PLAYER_DEACTIVATED, function()
        ALC.pool_reload_token = (ALC.pool_reload_token or 0) + 1
    end)

    ALC.register_slash_commands()
end

EVENT_MANAGER:RegisterForEvent(
    ALC.name,
    EVENT_ADD_ON_LOADED,
    function(...) ALC.init(...) end
)