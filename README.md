<div align="center">

# Auto Lua Memory Cleaner

*A lightweight, event-driven background memory cleaner for The Elder Scrolls Online.*

![Version](https://img.shields.io/badge/version-0.0.9-9CD04C?style=flat-square)
![ESO API](https://img.shields.io/badge/ESO%20API-101050%20%7C%20101051-00FFFF?style=flat-square)
![License](https://img.shields.io/badge/license-GPLv3-fa9c1b?style=flat-square)
![Platform](https://img.shields.io/badge/platform-PC%20%7C%20Xbox%20%7C%20PlayStation-FF69B4?style=flat-square)

</div>

Most memory cleaners run a fixed-interval `OnUpdate` timer that pings your memory every few seconds, looping endlessly from the moment you log in. Some of them do skip the check while you're in combat, but not all of them do - and some still print a memory info line on that same timer regardless of combat state or whether you're even looking at the UI. Most are also built before console APIs existed, and only track `collectgarbage` (ignoring console UI limits).

Auto Lua Memory Cleaner is event-driven first: real triggers (exiting combat, entering a menu, a low-memory warning) do almost all the work. There's still a lightweight ~5-second fallback poll running in the background (one cheap number comparison, not a full scan or UI rebuild) to catch you standing around doing nothing else, but that's a fraction of the constant polling most other memory cleaners run outright.


## Why use this over other memory cleaners?

- **Near-Zero Idle Footprint.** Most checks run only on real triggers - loading screens, exiting combat state, entering a menu - backed by a lightweight ~5-second fallback poll (one cheap number check, not a full scan) so idle time standing around is still covered without a heavy constant loop.
- **Smart combat lockout.** Blocks the automatic threshold-based cleanup from running while you're in combat or dead, so there's no mid-fight frame drops - the only exception is a genuine low-memory emergency, where the bigger risk is an outright crash.
- **PC & Console aware.** PC watches the Lua heap against a ~512 MB soft limit; Console watches the strict 100 MB hardware addon-memory pool and can auto-reload after travel to actually clear it (a plain GC pass never touches that figure, only a reload does).
- **Double-pass sweep.** Runs two back-to-back `collectgarbage("collect")` passes so pending `__gc` hooks and orphaned weak tables actually get cleared, not just queued.

## Install

Drop the `AutoLuaMemoryCleaner` folder into your `AddOns` directory. `LibAPH` is a hard dependency: install it too (drop its own folder into `AddOns`) or ALC won't load.

Optional: `LibAddonMenu-2.0` (PC settings menu) or `LibHarvensAddonSettings` (Console/Gamepad settings menu). Without either, ALC still runs standalone via slash commands.

## Features

- **Near-Zero Idle Footprint:** most checks run only on real triggers - loading screens, exiting combat state, entering a menu - backed by a lightweight ~5-second fallback poll so idle time standing around is still covered without a heavy constant loop.
- **Smart Combat Lockout:** blocks the automatic threshold-based cleanup from running while you're in combat, preventing mid-fight frame drops *(imagine crashing in the middle of your Trifecta, or God Slayer run!)* - the only exception is a genuine low-memory emergency, where the bigger risk is an outright crash.
- **(PC & Console) Support:** automatically adapts to your hardware specific memory rules. On PC, it helps you stay safely below the 512MB performance "soft limit" to prevent UI lag and stuttering. On Console, it safely monitors the strict 100MB hardware memory pool to prevent the game from forcefully reloading your UI.
- **Double-Pass Engine Sweep:** a dual-pass garbage collection cycle to safely force execution of all pending `__gc` hooks and ensure orphaned weak tables are properly eradicated from the addon's Lua heap.
- **Module Manager:** soft-disable optional feature files when not needed to save up on CPU usage - re-enable any of them anytime via slash command or the dedicated Module Manager settings.
- **PermMemento Integration:** automatically detects [Permanent Memento](https://www.esoui.com/downloads/info4116) and disables its internal Memory cleaner.

## Usage & Core Settings

- **Auto-cleanup:** runs silently based on your thresholds.
- **Cleanup threshold:** separate sliders for PC (Lua heap MB) and Console (addon memory pool MB).

## Slash commands

| Command | Effect |
|---|---|
| <kbd>/alc</kbd> | List all commands in chat |
| <kbd>/alcon</kbd> | Toggle Auto Lua Cleanup |
| <kbd>/alcclean</kbd> | Force a manual Lua cleanup |
| <kbd>/alcpoolreload</kbd> | Toggle Auto Pool Cleanup After Travel <sub>*(Console)*</sub> |
| <kbd>/alcui</kbd> | Toggle the status UI |
| <kbd>/alclock</kbd> | Lock/unlock the UI |
| <kbd>/alcreset</kbd> | Reset UI position |
| <kbd>/alccsa</kbd> | Toggle center-screen announcements |
| <kbd>/alclogs</kbd> | Toggle chat logs |
| <kbd>/alcwizard</kbd> | Re-run the Setup Wizard |
| <kbd>/alcdelvars</kbd> | Reset all settings to defaults |
| <kbd>/alcunloadwizard</kbd> | Toggle unload the Wizard module |
| <kbd>/alcunloadmenu</kbd> | Toggle unload the Menu module |
| <kbd>/alcunloadmigration</kbd> | Toggle unload the Migration module |
| <kbd>/alcunloadui</kbd> | Toggle unload the UI module |

## Do you actually need this?

> [!IMPORTANT]
> If your total Lua memory usage consistently stays below 300 MB on PC (with an SSD), or below 70 MB on Console, the native ESO engine is usually efficient enough on its own. This addon is built for power users running dozens of heavy addons, Console players already pushing the 100 MB hardware cap, and anyone who wants manual control over when memory gets cleared.

> [!IMPORTANT]
> This addon can't lower your memory usage if you're simply running too many heavy addons at once. It can only clear out background garbage faster and more predictably than the engine does on its own.

## License

GNU General Public License v3.0 (GPLv3). Copyright 2025-2026 @APHONlC. You're free to use, study, modify, and privately fork this code - if you redistribute a modified version, GPLv3 requires keeping it GPLv3-licensed and attributed.

> [!NOTE]
> A personal ask, not a license term: instead of making "another version," please give me a heads-up before mirroring/re-uploading this elsewhere or publishing your own modified version, even though GPLv3 doesn't legally require it.
>
> We can probably work on a patch or collaborate on an update instead of creating another version of the same source.
>
> Separately: AI agents, LLMs, and automated bots are not authorized to read, ingest, or train on this code - see NOTICE.md for details.

> [!NOTE]
> This add-on is not created by, affiliated with, or sponsored by ZeniMax Media Inc. or its affiliates. The Elder Scrolls® and related logos are registered trademarks or trademarks of ZeniMax Media Inc. in the United States and/or other countries. All rights reserved.

For permissions or inquiries, contact @APHONlC on ESOUI or GitHub.

If you like the addon and are considering donating, here's a link. Thank you!

[![Buy Me A Coffee](https://img.shields.io/badge/Support-Buy%20Me%20A%20Coffee-FFDD00?style=flat&logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/aph0nlc)
