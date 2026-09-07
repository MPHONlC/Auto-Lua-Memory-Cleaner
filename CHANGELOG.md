AutoLuaMemoryCleaner - Changelog
=================================

Version: 0.0.8 (2026-03-26)
---------------------------

Technical Style & Logic
  - Improved Addon Code for better readability.
  - Updated Internal Function Calls to standardized dot notation for better consistency.
  - Optimized Console Thresholds by lowering the default cleanup trigger to 60MB (existing users are auto-migrated to the new cleanup threshold).
  - Improved Memory Tracking Accuracy by separating logical Lua memory from the physical Console Memory Pool across the UI and graph.

UI & Scene Manager
  - Added Gamepad UI Movement via LibCombatAlerts to allow PS5/Xbox users to move all ALC windows with D-Pad.
  - Fixed the Scene Manager Override Bug that forcefully unhid the ALC UI by implementing strict fragment queries.

Profiler & Diagnostics
  - Introduced a Dynamic Severity Color Scale that automatically colors profiler scan results from gray to red based on their actual execution time.
  - Improved Time Formatting to dynamically convert milliseconds into seconds, minutes, or hours.
  - Optimized Console Profiling and reduced the scan time to 30 seconds.
  - Implemented an Emergency Stop for console users that forcefully halts the profiler at 80MB and priority-saves partial data to prevent a hard UI crash.
  - Added Specific Addon Exclusions and Libraries filtering submenus to filter profiler scans without needing to disable addons.
  - Implemented a Combat Safety Delay to pause the profiler from saving results if you are in combat, preventing in-game calculation freezes during combat scenarios.
  - Added a Profiler Results window inside the settings to display and save the complete list of all scan results.

General Additions
  - Added a Reset Button to safely wipe settings to default.
  - Added new slash commands /alcprolist and /alcprostop.


Version: 0.0.7 (2026-03-17)
---------------------------

Performance & API Updates
  - Updated API to 101049.
  - Optimized Event Dormancy to unregister background calls when sub-features are disabled.
  - Updated Performance-First Defaults to ensure the Graph, Chat Logs, and Trackers start OFF.
  - Optimized Priority Save logic to only trigger when statistics tracking is active.
  - Added a Track Statistics toggle (defaulted to OFF) for a more lightweight UX.
  - Added KB formatting for smaller memory cleanup reports.
  - Auto-Migration: new performance defaults automatically apply to existing users upon update.

UI & Console Updates
  - Added Console Positioning Sliders to allow PS5/Xbox users to move the UI (thanks to @Lily for the suggestion).
  - Introduced a Detachable Memory Graph Module (movable & lockable position).
  - Implemented Dynamic Visual Graph UI for real-time system monitoring.
  - Added a Dynamic Percentage Bar to indicate cleanup proximity based on user thresholds.
  - Added a Global Rendering Option to keep the UI visible while navigating menus.

Profiler Module & Dependency Warning
  - Added a Script Profiler Module to identify laggy addons via 60-second performance scans.
  - Added Optional Dependency Warning popups for missing or outdated LibAddonMenu-2.0.

Advanced Diagnostics & Session Tracking
  - Introduced a Detachable Session History UI to view previous session data.
  - Added Independent Session Data Logging for Peak, Average, and Final (Last Seen) states.
  - Added 21 new slash commands for full control over all diagnostic modules.


Version: 0.0.6 (2026-03-02)
---------------------------

General Updates
  - Improved cleanup routine checks for the built-in ALC logic.
  - Improved console event listener for more stability.
  - Changed LibAddonMenu-2.0 to an optional dependency. Core cleanup and /alc slash commands now work as a standalone utility.
  - Note: without the dependencies you can still run the addon independently and control its settings via built-in slash commands. Install the library if you want the settings GUI.


Version: 0.0.5 (2026-02-27)
---------------------------

UI & Slash Command Updates
  - Adjusted CSA messages to prevent text from being cut off.
  - Updated memory formatting to display MB, GB, or TB on the UI statistics panel.
  - Added a "Combat" state indicator to the draggable UI.
  - Updated the minimum memory reporting threshold to 0.01 MB.
  - Increased menu interaction memory check delay from 2s to 6s.
  - Updated slash commands and /alc output for better readability.
  - Updated settings menu tooltips to reflect command changes.


Version: 0.0.4 (2026-02-17)
---------------------------

Data & Performance
  - Added a "Live Statistics" panel to track memory usage and freed memory data.
  - Added Automatic Data Migration to prune obsolete SavedVariables from v0.0.1 through v0.0.3.
  - Added "Priority Save" for background SavedVariables to protect data during unexpected game closures.


Version: 0.0.3 (2026-02-16)
---------------------------

  - Updated LibAddonMenu-2.0 minimum requirement to version 41.


Version: 0.0.2 (2026-02-16)
---------------------------

  - Updated LibAddonMenu-2.0 to latest version requirement.


Version: 0.0.1 (2026-02-16)
---------------------------

  - Initial public release.
