-- AutoLuaMemoryCleaner - Copyright 2025-2026 @APHONlC. 
-- Licensed under the GNU General Public License v3.0 (GPLv3). 
-- See LICENSE.md and NOTICE.md.

-- This file must load after Core/ALC_Core.lua.
if not ALC then return end
ALC.Console = ALC.Console or {}

local function IsConsoleUI()
    return IsInGamepadPreferredMode()
end

function ALC.Console.get_active_memory_mb()
    return ALC.get_console_pool_mb()
end

function ALC.Console.get_threshold()
    return ALC.settings.threshold_console
end

function ALC.Console.get_pool_threshold()
    return ALC.settings.pool_threshold_console
end

function ALC.Console.build_threshold_slider(build_data)
    table.insert(build_data, {
        type = "slider",
        name = function() return ALC.L("SLIDER_CONSOLE_LUA_THRESHOLD") end,
        min = 5, max = 95, step = 1,
        getFunc = function() return ALC.settings.threshold_console end,
        setFunc = function(v) ALC.settings.threshold_console = v end,
        disabled = function() return not ALC.settings.is_enabled end
    })
end

function ALC.Console.build_pool_threshold_slider(build_data)
    table.insert(build_data, {
        type = "slider",
        name = function() return ALC.L("SLIDER_CONSOLE_POOL_THRESHOLD") end,
        min = 0.01, max = 85, step = 0.5, decimals = 2,
        getFunc = function() return ALC.settings.pool_threshold_console end,
        setFunc = function(v) ALC.settings.pool_threshold_console = v end,
        disabled = function() return not ALC.settings.auto_clear_pool_on_teleport end
    })
end

function ALC.Console.build_extra_options(build_data)
    table.insert(build_data, {
        type = "checkbox",
        name = function() return ALC.L("CHK_CHAT_LOGS") end,
        getFunc = function() return ALC.settings.is_log_enabled end,
        setFunc = function(v) ALC.settings.is_log_enabled = v end
    })
end

function ALC.Console.create_gamepad_mover(target)
    return LibAPH.CreateGamepadMover(target)
end
