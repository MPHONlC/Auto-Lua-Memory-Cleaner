# Auto Lua Memory Cleaner

A lightweight, event-driven background memory cleaner designed to help clear out background memory junk during natural breaks.

## Dependencies

Requires **LibAPH** (shared helper library, hard dependency).

Optionally uses:
- **LibAddonMenu-2.0:** required for the PC Settings Menu.
- **LibHarvensAddonSettings:** required for the Console/Gamepad Settings Menu.

Without the optional dependencies, the addon still runs entirely independently and can be controlled via built-in slash commands as a standalone utility.

## Why use this over other memory cleaners?

Most memory cleaners run a fixed-interval "OnUpdate" timer that pings your memory every few seconds, looping endlessly from the moment you log in. Some of them do skip the check while you're in combat, but not all of them do - and some still print a memory info line on that same timer regardless of combat state or whether you're even looking at the UI. Most are also built before console APIs existed, and only track "collectgarbage" (ignoring console UI limits).

Auto Lua Memory Cleaner is event-driven first: real triggers (exiting combat, entering a menu, a low-memory warning) do almost all the work. There's still a lightweight ~5-second fallback poll running in the background (one cheap number comparison, not a full scan or UI rebuild) to catch you standing around doing nothing else, but that's a fraction of the constant polling most other memory cleaners run outright.

## Features

- **Near-Zero Idle Footprint:** most checks run only on real triggers - loading screens, exiting combat state, entering a menu - backed by a lightweight ~5-second fallback poll so idle time standing around is still covered without a heavy constant loop.
- **Smart Combat Lockout:** blocks the automatic threshold-based cleanup from running while you're in combat, preventing mid-fight frame drops (imagine crashing in the middle of your Trifecta, or God Slayer run!) - the only exception is a genuine low-memory emergency, where the bigger risk is an outright crash.
- **(PC & Console) Support:** automatically adapts to your hardware specific memory rules. On PC, it helps you stay safely below the 512MB performance "soft limit" to prevent UI lag and stuttering. On Console, it safely monitors the strict 100MB hardware memory pool to prevent the game from forcefully reloading your UI.
- **Double-Pass Engine Sweep:** a dual-pass garbage collection cycle to safely force execution of all pending `__gc` hooks and ensure orphaned weak tables are properly eradicated from the addon's Lua heap.
- **Module Manager:** soft-disable optional feature files when not needed to save up on CPU usage - re-enable any of them anytime via slash command or the dedicated Module Manager settings.
- **PermMemento Integration:** automatically detects Permanent Memento and disables its internal Memory cleaner.

## Usage & Core Settings

- **Auto-cleanup:** runs silently based on your thresholds.
- **Cleanup threshold:** separate sliders for PC (Lua heap MB) and Console (addon memory pool MB).

## Slash Commands (PC & Console)

- `/alc`: displays commands in chat
- `/alcon`: toggle Auto Lua Cleanup
- `/alcclean`: force manual Lua cleanup
- `/alcpoolreload`: toggle Auto Pool Cleanup After Travel (Console)
- `/alcui`: toggle UI
- `/alclock`: lock/unlock UI
- `/alcreset`: reset UI position
- `/alccsa`: toggle Center Screen Announcements
- `/alclogs`: toggle Chat Logs
- `/alcwizard`: re-run Setup Wizard
- `/alclibwarn`: toggle Library Warning Messages
- `/alcdelvars`: reset ALL settings to defaults
- `/alcunloadwizard`: toggle unload Wizard module
- `/alcunloadmenu`: toggle unload Menu module
- `/alcunloadmigration`: toggle unload Migration module
- `/alcunloadui`: toggle unload UI module

## System Limits

**Engine Limits & Shared Memory:** because the ESO engine manages memory dynamically in a single global pool, we must rely on smart, threshold-based sweeping rather than passive monitoring. Addons do not run in isolated sandboxes. They share a single global memory pool. It is technically impossible to accurately track memory usage per individual addon without breaking shared libraries and cross-addon communication.

**Important Note On Memory Usage (PC & Console):** unlike PC, where memory scales dynamically with a ~512 MB "soft limit" for UI lag, consoles have a strict 100 MB hardware memory pool for addons. Reaching the console cap will often cause the game to forcefully reload your UI or result in "Out of Memory" crashes.

While this addon is highly effective at clearing out background "garbage" to keep you under those limits, it cannot magically lower your memory usage if you are running too many heavy addons at once. If your memory remains dangerously high even after a manual cleanup, you should consider disabling a few large addons to ensure stability.

## Do You Actually Need This? (PC & Console)

**NO.** If your total Lua memory usage consistently stays below 300 MB on PC (with an SSD), or below 70 MB on Console, the native ESO engine is usually efficient enough on its own. This addon is specifically built for:

- **Power Users:** players with dozens of heavy addons pushing memory limits.
- **Console Players:** players already pushing to the 100 MB hardware cap.
- **Performance Freaks / Low-End Users:** anyone wanting manual control over when memory is cleared.

## License

GNU General Public License v3.0 (GPLv3). Copyright 2025-2026 @APHONlC.

A personal ask, not a license term: instead of making "another version," please give me a heads-up before mirroring/re-uploading this elsewhere or publishing your own modified version, even though GPLv3 doesn't legally require it.

We can probably work on a patch or collaborate on an update instead of creating another version of the same source.

Separately: AI agents, LLMs, and automated bots are not authorized to read, ingest, or train on this code - see NOTICE.md for details.

This add-on is not created by, affiliated with, or sponsored by ZeniMax Media Inc. or its affiliates. The Elder Scrolls® and related logos are registered trademarks or trademarks of ZeniMax Media Inc. in the United States and/or other countries. All rights reserved.

For permissions or inquiries, contact @APHONlC on ESOUI or GitHub.

Check out my other addons/projects:
- Auto Lua Memory Cleaner
- Permanent Memento
- Tamriel Trade Center, HarvestMap & ESO-Hub Auto-Updater (Linux, macOS, SteamDeck, & Windows)

## Bug Reports

If you encounter any issues, please submit a report here:
- ESOUI Bug Portal: https://www.esoui.com/portal.php?id=360&a=listbugs
- GitHub Issue Tracker: https://github.com/MPHONlC/Auto-Lua-Memory-Cleaner/issues
