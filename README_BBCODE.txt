[SIZE="5"][COLOR="SeaGreen"]Auto Lua Memory Cleaner[/COLOR][/SIZE]

A lightweight, event-driven background memory cleaner designed to help clear out background memory junk during natural breaks.

[SIZE="3"][COLOR="DarkOrchid"]Dependencies:[/COLOR][/SIZE]

This addon requires:
[LIST]
[*] [COLOR="#FF69B4"]LibAPH[/COLOR] [COLOR="Gray"][i](Required Unified helpers shared with my addons)[/i][/COLOR]
[/LIST]

And optionally uses:
[LIST]
[*] [url="https://www.esoui.com/downloads/info7-LibAddonMenu-2.0.html"][COLOR="#FF69B4"]LibAddonMenu-2.0[/COLOR][/url] [COLOR="Gray"][i](Keyboard/PC Settings Menu)[/i][/COLOR]
[*] [COLOR="#FF69B4"]LibHarvensAddonSettings[/COLOR] [COLOR="Gray"][i](Gamepad/Console Settings Menu)[/i][/COLOR]
[/LIST]

[b]Without the optional Dependencies:[/b] You can still run the addon entirely independent, and control its settings via built-in slash commands as a standalone utility.

[SIZE="5"][COLOR="Yellow"]Why use this over other memory cleaners?[/COLOR][/SIZE]

Most memory cleaners run a fixed-interval "OnUpdate" timer that pings your memory every few seconds, looping endlessly from the moment you log in. Some of them do skip the check while you're in combat, but not all of them do - and some still print a memory info line on that same timer regardless of combat state or whether you're even looking at the UI. Most are also built before console APIs existed, and only track "collectgarbage" [COLOR="Gray"][i](ignoring console UI limits)[/i][/COLOR].

Auto Lua Memory Cleaner is event-driven first: exiting combat, entering a menu, a low-memory warning do almost all the work. There's still a lightweight ~5-second fallback poll running in the background (not a full scan or UI rebuild) to catch you standing around doing nothing else, but that's a fraction of the constant polling most other memory cleaners run outright.

[SIZE="5"][COLOR="Yellow"]Features[/COLOR][/SIZE]

[LIST]
[*] [b][COLOR="Lime"]Near-Zero Idle Footprint:[/COLOR][/b] Most checks run only on real triggers - loading screens, exiting combat state, entering a menu - backed by a lightweight ~5-second fallback poll so idle time standing around is still covered without a heavy constant loop.
[*] [b][COLOR="Lime"]Smart Combat Lockout:[/COLOR][/b] Blocks the automatic threshold-based cleanup from running while you're in combat, preventing mid-fight frame drops [COLOR="Gray"][i](Imagine crashing in the middle of your Trifecta, or God Slayer run!)[/i][/COLOR] - the only exception is a genuine low-memory emergency, where the bigger risk is an outright crash.
[*] [b][COLOR="Lime"](PC & Console) Support:[/COLOR][/b] Automatically adapts to your hardware specific memory rules. On PC, it helps you stay safely below the 512MB performance "soft limit" to prevent UI lag and stuttering. On Console, it safely monitors the strict 100MB hardware memory pool to prevent the game from forcefully reloading your UI.
[*] [b][COLOR="Lime"]Double-Pass Engine Sweep:[/COLOR][/b] A dual-pass garbage collection cycle to safely force execution of all pending __gc hooks and ensure orphaned weak tables are properly eradicated from the addon's Lua heap.
[*] [b][COLOR="Lime"]Module Manager:[/COLOR][/b] Soft-disable optional feature files when not needed to save up on CPU usage - re-enable any of them anytime via slash command or the dedicated Module Manager settings.
[*] [b][COLOR="Lime"]PermMemento Integration:[/COLOR][/b] Automatically detects [b][url="https://www.esoui.com/downloads/info4116-PermanentMemento.html"][color=yellow]Permanent Memento[/color][/url][/b] and disables its internal Memory cleaner.
[/LIST]

[b][COLOR="RoyalBlue"]Usage & Core Settings:[/COLOR][/b]
[LIST]
[*] [b][color=#00FFFF]AUTO-CLEANUP:[/color][/b] Runs silently based on your thresholds.
[*] [b][color=#00FFFF]CLEANUP THRESHOLD:[/color][/b] Separate sliders for PC (Lua heap MB) and Console (addon memory pool MB).
[/LIST]

[b][COLOR="RoyalBlue"]Slash Commands [COLOR="Gray"][i](PC & Console)[/i][/COLOR]:[/COLOR][/b]
[LIST]
[*] [b][color=#00FFFF]/alc[/color][/b] - Displays commands in chat
[*] [b][color=#00FFFF]/alcon[/color][/b] - Toggle Auto Lua Cleanup
[*] [b][color=#00FFFF]/alcclean[/color][/b] - Force manual Lua cleanup
[*] [b][color=#00FFFF]/alcpoolreload[/color][/b] - Toggle Auto Pool Cleanup After Travel
[*] [b][color=#00FFFF]/alcpoolconfirm[/color][/b] - Toggle Auto Pool Cleanup After Travel Confirmation
[*] [b][color=#00FFFF]/alcsinglepass[/color][/b] - Toggle Single Pass Cleanup
[*] [b][color=#00FFFF]/alcui[/color][/b] - Toggle UI
[*] [b][color=#00FFFF]/alclock[/color][/b] - Lock/Unlock UI
[*] [b][color=#00FFFF]/alcreset[/color][/b] - Reset UI Position
[*] [b][color=#00FFFF]/alccsa[/color][/b] - Toggle Center Screen Announcements
[*] [b][color=#00FFFF]/alclogs[/color][/b] - Toggle Chat Logs
[*] [b][color=#00FFFF]/alcwizard[/color][/b] - Re-run Setup Wizard
[*] [b][color=#00FFFF]/alclibwarn[/color][/b] - Toggle Library Warning Messages
[*] [b][color=#00FFFF]/alcbugreport[/color][/b] - Open the bug report copy box
[*] [b][color=#00FFFF]/alcdelvars[/color][/b] - Reset ALL settings to defaults
[*] [b][color=#00FFFF]/alcunloadwizard[/color][/b] - Toggle unload Wizard module
[*] [b][color=#00FFFF]/alcunloadmenu[/color][/b] - Toggle unload Menu module
[*] [b][color=#00FFFF]/alcunloadmigration[/color][/b] - Toggle unload Migration module
[*] [b][color=#00FFFF]/alcunloadui[/color][/b] - Toggle unload UI module
[/LIST]

[center]
[SIZE="5"][COLOR="Red"]System Limits[/COLOR][/SIZE]

[b][COLOR="Orange"]Engine Limits & Shared Memory:[/COLOR][/b]
Because the ESO engine manages memory dynamically in a single global pool, we must rely on smart,
threshold-based sweeping rather than passive monitoring. Addons do not run in isolated sandboxes.
They share a single global memory pool. It is technically impossible to accurately track memory usage
per individual addon without breaking shared libraries and cross-addon communication.

[b][COLOR="Orange"]⚠️ Important Note On Memory Usage [COLOR="Gray"][i](PC & Console)[/i][/COLOR]: ⚠️[/COLOR][/b]
Unlike PC, where memory scales dynamically with a ~512 MB "soft limit" for UI lag, consoles have
a strict 100 MB hardware memory pool for addons. Reaching the console cap will often cause the
game to forcefully reload your UI or result in "Out of Memory" crashes.

While this addon is highly effective at clearing out background "garbage" to keep you under those
limits, it cannot magically lower your memory usage if you are running too many heavy addons at
once. If your memory remains dangerously high even after a manual cleanup, you should consider
disabling a few large addons to ensure stability.

[b][COLOR="Orange"]Do You Actually Need This [COLOR="Gray"][i](PC & Console)[/i][/COLOR]?[/COLOR][/b]
[b][SIZE="4"][COLOR="Red"]NO.[/COLOR][/SIZE][/b] If your total Lua memory usage consistently stays below 300 MB on PC
[COLOR="Gray"][i](with an SSD)[/i][/COLOR], or below 70 MB on Console, the native ESO engine is
usually efficient enough on its own. This addon is specifically built for:

[b][COLOR="Lime"]Power Users:[/COLOR][/b] Players with dozens of heavy addons pushing memory limits.
[b][COLOR="Lime"]Console Players:[/COLOR][/b] Players already pushing to the 100 MB hardware cap.
[b][COLOR="Lime"]Performance Freaks / Low-End Users:[/COLOR][/b] Anyone wanting manual control over when memory is cleared.

[SIZE="5"][COLOR="Red"]LICENSE & USAGE[/COLOR][/SIZE]

Copyright (c) 2025-2026 [COLOR="#FF69B4"]@APHONlC[/COLOR].

Licensed under the [b]GNU General Public License v3.0 (GPLv3)[/b] [COLOR="Gray"][i]
(see LICENSE.md and NOTICE.md in the source)[/i][/COLOR].

[COLOR="Gray"][i](A personal ask, not a license term: Instead of making "another version" please give me a heads-up before mirroring/re-uploading this elsewhere or publishing your own modified version, even though GPLv3 doesn't legally require it.)[/i][/COLOR]

[COLOR="Gray"][i](We can probably work on a patch or collaborate on an update instead of creating another version of the same source)[/i][/COLOR]

[COLOR="Gray"][i](Separately: AI agents, LLMs, and automated bots are not authorized to read, ingest, or train on this code - see NOTICE.md for details.)[/i][/COLOR]

[COLOR="Gray"][i](For permissions or inquiries, contact [COLOR="#FF69B4"]@APHONlC[/COLOR] on ESOUI or GitHub.)[/i][/COLOR]

[b][color=#9CD04C]Check out my other addons/projects:[/color][/b]

[LIST]
[*] [url="https://www.esoui.com/downloads/fileinfo.php?id=4388#info"][color=#fa9c1b]Auto Lua Memory Cleaner[/color][/url]
[*] [url="https://www.esoui.com/downloads/fileinfo.php?id=4116#info"][color=#fa9c1b]Permanent Memento[/color][/url]
[*] [url="https://www.esoui.com/downloads/fileinfo.php?id=3249#info"][color=#fa9c1b]Tamriel Trade Center, HarvestMap & ESO-Hub Auto-Updater[/color][/url] [COLOR="Gray"][i](Linux, macOS, SteamDeck, & Windows)[/i][/COLOR]
[/LIST]

[b][color=#ff3300][SIZE="4"]BUG REPORTS[/SIZE][/color][/b]
If you encounter any issues, please submit a report here:
[url="https://www.esoui.com/portal.php?id=360&a=listbugs"]ESOUI Bug Portal[/url] | [url="https://github.com/MPHONlC/Auto-Lua-Memory-Cleaner/issues"]GitHub Issue Tracker[/url]
[/center]
