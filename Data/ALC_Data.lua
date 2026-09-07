-- AutoLuaMemoryCleaner - Copyright 2025-2026 @APHONlC. 
-- Licensed under the GNU General Public License v3.0 (GPLv3). 
-- See LICENSE.md and NOTICE.md.

-- This file must load after Core/ALC_Core.lua.
if not ALC then return end

ALC.COMMAND_CATEGORIES = {
    { title_key = "CAT_CLEANUP", cmds = {
        { cmd = "/alcon", desc_key = "CMD_ALCON" },
        { cmd = "/alcclean", desc_key = "CMD_ALCCLEAN" },
        { cmd = "/alcpoolreload", desc_key = "CMD_ALCPOOLRELOAD" },
    }},
    { title_key = "CAT_MEMORY_UI", cmds = {
        { cmd = "/alcui", desc_key = "CMD_ALCUI" },
        { cmd = "/alclock", desc_key = "CMD_ALCLOCK", disabled_check = function() return not ALC.settings.show_ui end },
        { cmd = "/alcreset", desc_key = "CMD_ALCRESET", disabled_check = function() return not ALC.settings.show_ui end },
    }},
    { title_key = "CAT_GENERAL", cmds = {
        { cmd = "/alccsa", desc_key = "CMD_ALCCSA" },
        { cmd = "/alclogs", desc_key = "CMD_ALCLOGS", pc_only = true },
        { cmd = "/alcwizard", desc_key = "CMD_ALCWIZARD", disabled_check = function() return ALC._modules.wizard == false end },
        { cmd = "/alcdelvars", desc_key = "CMD_ALCDELVARS" },
    }},
    { title_key = "CAT_MODULE_MANAGER", cmds = {
        { cmd = "/alcunloadwizard", desc_key = "CMD_ALCUNLOADWIZARD" },
        { cmd = "/alcunloadmenu", desc_key = "CMD_ALCUNLOADMENU" },
        { cmd = "/alcunloadmigration", desc_key = "CMD_ALCUNLOADMIGRATION" },
    }}
}

ALC.LANGUAGE_NAMES = {
    en = "English",
    de = "Deutsch",
}