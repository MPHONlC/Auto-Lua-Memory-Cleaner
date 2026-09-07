-- AutoLuaMemoryCleaner - Copyright 2025-2026 @APHONlC. 
-- Licensed under the GNU General Public License v3.0 (GPLv3). 
-- See LICENSE.md and NOTICE.md.

-- TEMPLATE FOR TRANSLATORS:
-- Copy this file to lang/<code>.lua (the code ESO's GetCVar("Language.2")
-- returns for your language, e.g. "de", "fr", "ru", "jp"). Translate only
-- the string VALUES after each "=", never the ALL_CAPS keys. Keep any
-- "%d"/"%g"/"%s" sequence somewhere in your translation.
-- Save as lang/<code>.lua, add it to AutoLuaMemoryCleaner.addon's file
-- list next to the other lang/*.lua entries, and submit it via the
-- Feature Request thread: https://www.esoui.com/portal.php?id=360&a=featurereq

ALC = ALC or {}
ALC.Lang = ALC.Lang or {}

ALC.Lang.en = {
    YES = "Yes",
    NO = "No",
    USE_DEFAULT = "Use Default",
    CUSTOMIZE = "Customize",
    LOW = "Low (%s)",
    HIGH = "High (%s)",
    SHORT = "Short (%s)",
    LONG = "Long (%s)",

    -- Setup wizard: welcome
    WELCOME_TITLE = "Welcome to Auto Lua Memory Cleaner!",
    WELCOME_BODY = "Run a quick first-time setup? A few short questions, then you're done. Everything here can be changed later in the settings menu or via /alc.",
    QUICK_SETUP = "Quick Setup",
    SKIP = "Skip",

    -- Setup wizard: simple yes/no questions
    CHATLOGS_BODY = "Log cleanups to chat?",
    CSA_BODY = "Show screen announcements when memory gets cleaned?",
    MEMORY_UI_BODY = "Show the on-screen memory display?",
    RENDER_MENUS_BODY = "Keep the memory UI visible while menus/inventory are open too?",
    POOL_CLEANUP_BODY = "Enable Auto Pool Cleanup After Travel (wayshrine, recall, etc.)?",

    -- Setup wizard: default-or-customize questions (%d/%g gets replaced with the actual default number)
    LUA_THRESHOLD_BODY = "Lua cleanup threshold: use the default (%d MB), or customize it?",
    LUA_THRESHOLD_CUSTOM_BODY = "Low or high Lua threshold?",
    POOL_THRESHOLD_BODY = "Pool cleanup threshold: use the default (%g MB), or customize it?",
    POOL_THRESHOLD_CUSTOM_BODY = "Low or high pool threshold?",
    LUA_DELAY_BODY = "Lua Cleanup Delay: use the default (300 sec / 5 min) before re-checking after a cleanup, or customize it?",
    LUA_DELAY_CUSTOM_BODY = "Short or long Lua Cleanup Delay?",
    POOL_DELAY_BODY = "Pool Cleanup Delay: use the default (2 seconds) before reloading after high pool usage, or customize it?",
    POOL_DELAY_CUSTOM_BODY = "Short or long Pool Cleanup Delay?",

    -- Wizard: closing chat message
    WIZARD_FINISH_MSG = "Setup complete. Adjust anytime under Cleanup Settings / UI Configuration, or /alcdelvars to start over.",

    -- Setup wizard: language
    WIZARD_LANGUAGE_BODY = "Setup will run in your current display language (%s). Continue, or open Language Settings first to pick a different one?",
    WIZARD_LANGUAGE_CONTINUE = "Continue",
    WIZARD_LANGUAGE_CHANGE = "Change Language First",
    WIZARD_LANGUAGE_CHANGE_MSG = "Setup paused. Open Settings > Auto Lua Memory Cleaner > Language to pick your preferred display language, then run /alcwizard to continue setup in that language.",

    -- Always-on-screen memory display / chat / CSA
    LABEL_LUA = "Lua",
    LABEL_POOL = "Pool",
    LABEL_COMBAT = "(Combat)",
    LABEL_ALREADY_CLEAN = "(Already Clean)",
    CSA_TITLE_CLEANED = "Memory Cleaned",
    CSA_TITLE_ALREADY_CLEAN = "Already Clean",
    CSA_TITLE_POOL_CLEARED = "Pool Cleaned",
    CSA_TITLE_SETTINGS_UNAVAILABLE = "Settings Menu Unavailable",
    LHAS_STATE_NOT_INSTALLED = "not installed",
    LHAS_STATE_NOT_ENABLED = "not enabled",
    LHAS_WARN_MSG = "LibHarvensAddonSettings is %s - the settings menu won't appear on console without it.",
    LHAS_WARN_TITLE = "ALC - Settings Menu Won't Appear",
    LHAS_WARN_BODY_SUFFIX = "Install/enable LibHarvensAddonSettings to see ALC's settings.",
    CHAT_UI_POSITION_RESET = "UI Position Reset.",
    CHAT_UI_SIZE_RESET = "UI Size Reset.",
    CHAT_WIPING_SETTINGS = "Wiping all settings...",
    CHAT_POOL_RELOAD_NOTICE = "Reloading in %.1f seconds to clear pool usage.",
    CHAT_SETTINGS_RESET_OLDVERSION = "Settings from an older, incompatible version detected - resetting to current defaults.",
    WORD_ON = "ON",
    WORD_OFF = "OFF",
    CHAT_POOL_RELOAD_TOGGLE = "Auto Pool Cleanup After Travel: %s",
    WARN_LAM_OUTDATED = "Warning: LibAddonMenu is outdated (v%d). Update to v%d+ for ALC.",
    MODULE_TOGGLE_UNLOADED = "Module unloaded: %s",
    MODULE_TOGGLE_REENABLED = "Module re-enabled: %s",
    MODULE_TOGGLE_LIVE = " - applied live.",
    MODULE_TOGGLE_RELOAD = ". /reloadui to apply.",
    DIALOG_MISSING_LIBRARY_TITLE = "ALC - Optional Dependency Alert",
    DIALOG_MISSING_LIBRARY_BODY = "For full functionality, please update or install and enable:",
    BTN_ACKNOWLEDGE_CLOSE = "Acknowledge / Close",

    -- Client Info panel: field labels
    FIELD_INSTALLED_SINCE = "Installed Since:",
    FIELD_VERSION_HISTORY = "Version History:",
    FIELD_PLATFORM = "Platform:",
    FIELD_LIBRARY_VERSION = "Library Version:",
    FIELD_WIZARD = "Wizard:",
    FIELD_CURRENT_LANGUAGE = "Current Language:",
    FIELD_FILES = "Files:",
    FIELD_SETTINGS = "Settings:",
    INSTALL_DATE_UNKNOWN = "Unknown",

    -- Client Info panel: library version status
    NOT_FOUND = "Not Found",
    STATE_DISABLED = "(Disabled)",
    STATE_OLD = "(v%s - Old)",
    STATE_NEWER = "(v%s - Newer)",
    STATE_EXPECTED = "(Expected v%s)",

    -- Client Info panel: wizard/file status
    WIZARD_SETUP_DONE = "(Setup Done)",
    WIZARD_NOT_YET_RUN = "(Not Yet Run)",
    FILE_LOADED = "(Loaded)",
    FILE_UNLOADED_BY_USER = "(Unloaded)",

    -- Popup UI: Bug Report
    BTN_CLOSE = "Close",
    BUG_REPORT_COPY_TITLE = "COPY & PASTE THIS TO YOUR BUG REPORT",
    BUG_REPORT_COPY_PROMPT = "Copy this and paste it into your bug report:\n\n",
    BUG_REPORT_NONE_CAPTURED = "No %s errors have been captured yet this session.\n\n",
    BUG_REPORT_DESCRIBE_INSTEAD = "If you just saw an error message on screen, please describe what you were doing when it happened in the bug report instead.",

    -- Settings menu: section headers
    HEADER_CLEANUP_SETTINGS = "Cleanup Settings",
    HEADER_UI_CONFIG = "UI Configuration",
    HEADER_CLIENT_INFO = "Client Information",
    HEADER_LANGUAGE = "Language",
    HEADER_ADVANCED_SETTINGS = "Advanced Settings",
    HEADER_MODULE_MANAGER = "Module Manager",
    HEADER_MODULE_FILE_STATUS = "Module File Status",
    LABEL_MODULE = "Module",
    BTN_RELOAD_UI = "Reload UI",
    COMMANDS_INFO_TITLE = "Commands Info",

    -- Settings menu: checkboxes
    CHK_AUTO_LUA_CLEANUP = "Auto Lua Cleanup",
    CHK_AUTO_POOL_CLEANUP = "Auto Pool Cleanup After Travel",
    CHK_CSA = "Center Screen Announcements",
    CHK_SHOW_UI = "Show UI",
    CHK_RENDER_IN_MENUS = "Render UI in Menus",
    CHK_LOCK_UI = "Lock UI Position",
    SLIDER_UI_SCALE = "UI Scale",
    CHK_CHAT_LOGS = "Chat Logs",

    -- Settings menu: sliders
    SLIDER_LUA_DELAY = "Lua Cleanup Delay (Seconds)",
    SLIDER_POOL_DELAY = "Pool Cleanup Delay (Seconds)",
    SLIDER_PC_LUA_THRESHOLD = "PC Lua Threshold (MB)",
    SLIDER_PC_POOL_THRESHOLD = "PC Pool Threshold (MB)",
    SLIDER_CONSOLE_LUA_THRESHOLD = "Console Lua Threshold (MB)",
    SLIDER_CONSOLE_POOL_THRESHOLD = "Console Pool Threshold (MB)",

    -- Settings menu: buttons and their tooltips
    MENU_COMMANDS_INFO = "COMMANDS INFO",
    MENU_MANUAL_CLEANUP = "MANUAL CLEANUP",
    MENU_MAIL = "Mail",
    TOOLTIP_MAIL = "Opens the in-game mail. Thank you!",
    MENU_RUN_WIZARD = "SETUP WIZARD",
    MENU_RESET_DEFAULTS = "RESET TO DEFAULTS",
    TOOLTIP_RESET_DEFAULTS = "RESETS ALL SETTINGS TO DEFAULT VALUES.",
    MENU_BUG_REPORT = "BUG REPORT",
    TOOLTIP_BUG_REPORT = "Link: %s",
    MENU_MOVE_UI = "Move UI (Right Stick)",
    MENU_RESET_UI_POSITION = "RESET UI POSITION",
    MENU_RESET_UI_SIZE = "RESET UI SIZE",
    MENU_CHANGE_MODE = "Change Mode",
    MODE_PC = "PC",
    MODE_CONSOLE = "Console",

    -- Settings menu: Language submenu
    CURRENT_LANGUAGE_LABEL = "Current Language:",
    LANGUAGE_SELECTOR_NAME = "Select Language",
    LANGUAGE_AUTO = "Auto (Client Language)",
    BTN_APPLY_LANGUAGE = "Apply Selected Language",

    -- Commands Info: category titles
    CAT_CLEANUP = "Cleanup",
    CAT_MEMORY_UI = "Memory UI",
    CAT_GENERAL = "General",
    CAT_MODULE_MANAGER = "Module Manager",

    -- Commands Info: per-command descriptions
    CMD_ALCON = "Toggle Auto Lua Cleanup",
    CMD_ALCCLEAN = "Force manual Lua cleanup",
    CMD_ALCPOOLRELOAD = "Toggle Auto Pool Cleanup After Travel",
    CMD_ALCUI = "Toggle UI",
    CMD_ALCLOCK = "Lock/Unlock UI",
    CMD_ALCRESET = "Reset UI Position",
    CMD_ALCCSA = "Toggle Center Screen Announcements",
    CMD_ALCLOGS = "Toggle Chat Logs",
    CMD_ALCWIZARD = "Re-run Setup Wizard",
    CMD_ALCDELVARS = "Reset ALL settings to defaults",
    CMD_ALCUNLOADWIZARD = "Toggle unload Wizard module",
    CMD_ALCUNLOADMENU = "Toggle unload Menu module",
    CMD_ALCUNLOADMIGRATION = "Toggle unload Migration module",
}