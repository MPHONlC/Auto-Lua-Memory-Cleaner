-- AutoLuaMemoryCleaner - Copyright 2025-2026 @APHONlC. 
-- Licensed under the GNU General Public License v3.0 (GPLv3). 
-- See LICENSE.md and NOTICE.md.

-- This file must load after Core/ALC_Core.lua.
if not ALC then return end

local function IsConsoleUI()
    return IsInGamepadPreferredMode()
end

function ALC.register_slash_commands()
    SLASH_COMMANDS["/alc"] = function(raw_arg)
        local parsed_cmd = raw_arg:lower()
        if parsed_cmd == "" then
            local msg = "|c00FF00Available ALC Commands:|r\n" .. ALC.build_command_list_text(false)
            LibAPH.SendRawChatLine(msg)
            return
        end
    end
    SLASH_COMMANDS["/autoluaclean"] = SLASH_COMMANDS["/alc"]

    SLASH_COMMANDS["/alcon"] = function()
        ALC.settings.is_enabled = not ALC.settings.is_enabled
        ALC.toggle_core_events()
    end
    SLASH_COMMANDS["/alcenable"] = SLASH_COMMANDS["/alcon"]

    SLASH_COMMANDS["/alcui"] = function()
        ALC.settings.show_ui = not ALC.settings.show_ui
        ALC.call_optional(ALC.toggle_ui_update, "UI module (toggle_ui_update)")
    end
    SLASH_COMMANDS["/alctoggleui"] = SLASH_COMMANDS["/alcui"]

    SLASH_COMMANDS["/alclock"] = function()
        if not ALC.settings.show_ui then return end
        ALC.settings.is_ui_locked = not ALC.settings.is_ui_locked
        if ALC.ui_window then ALC.ui_window:SetMovable(not ALC.settings.is_ui_locked) end
    end
    SLASH_COMMANDS["/alcuilock"] = SLASH_COMMANDS["/alclock"]

    SLASH_COMMANDS["/alcreset"] = function()
        if not ALC.settings.show_ui then return end
        ALC.settings.ui_x = nil
        ALC.settings.ui_y = nil
        ALC.call_optional(ALC.update_ui_anchor, "UI module (update_ui_anchor)")
    end
    SLASH_COMMANDS["/alcuireset"] = SLASH_COMMANDS["/alcreset"]

    SLASH_COMMANDS["/alccsa"] = function()
        ALC.settings.is_csa_enabled = not ALC.settings.is_csa_enabled
    end
    SLASH_COMMANDS["/alctogglecsa"] = SLASH_COMMANDS["/alccsa"]

    SLASH_COMMANDS["/alclogs"] = function()
        ALC.settings.is_log_enabled = not ALC.settings.is_log_enabled
    end
    SLASH_COMMANDS["/alcchatlogs"] = SLASH_COMMANDS["/alclogs"]

    SLASH_COMMANDS["/alcclean"] = function() ALC.run_manual_cleanup(true) end
    SLASH_COMMANDS["/alccleanup"] = SLASH_COMMANDS["/alcclean"]

    SLASH_COMMANDS["/alcpoolreload"] = function()
        ALC.settings.auto_clear_pool_on_teleport = not ALC.settings.auto_clear_pool_on_teleport
        d("|c00FFFF[ALC]|r " .. ALC.L("CHAT_POOL_RELOAD_TOGGLE", ALC.settings.auto_clear_pool_on_teleport and ALC.L("WORD_ON") or ALC.L("WORD_OFF")))
    end

    SLASH_COMMANDS["/alclibwarn"] = function()
        ALC.settings.is_lib_warning_enabled = not ALC.settings.is_lib_warning_enabled
        d("|c00FFFF[ALC]|r " .. ALC.L("CHAT_LIBWARN_TOGGLE", ALC.settings.is_lib_warning_enabled and ALC.L("WORD_ON") or ALC.L("WORD_OFF")))
    end

    SLASH_COMMANDS["/alcdelvars"] = function()
        d("|cFF0000[ALC] " .. ALC.L("CHAT_WIPING_SETTINGS") .. "|r")
        ALC.reset_to_defaults()
    end
    SLASH_COMMANDS["/alcwipe"] = SLASH_COMMANDS["/alcdelvars"]

    SLASH_COMMANDS["/alcwizard"] = function()
        ALC.call_optional(ALC.run_wizard, "Wizard module (run_wizard)")
    end

    -- modules
    SLASH_COMMANDS["/alcunloadwizard"] = function() ALC.toggle_module_disabled("wizard") end
    SLASH_COMMANDS["/alcunloadmenu"] = function() ALC.toggle_module_disabled("menu") end
    SLASH_COMMANDS["/alcunloadmigration"] = function() ALC.toggle_module_disabled("migration") end
    SLASH_COMMANDS["/alcunloadui"] = function() ALC.toggle_module_disabled("ui") end
end
