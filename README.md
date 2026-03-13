<div align="center">

# [**Auto Lua Memory Cleaner**](https://www.esoui.com/downloads/info4388-AutoLuaMemoryCleaner.html)
[![ESOUI](https://img.shields.io/badge/PC-ESOUI-orange.svg?style=for-the-badge)](https://www.esoui.com/downloads/fileinfo.php?id=4388) [![Bethesda Mods](https://img.shields.io/badge/Console-Bethesda.net-black.svg?style=for-the-badge&logo=bethesda&logoColor=white)](https://mods.bethesda.net/en/elderscrollsonline/details/9926b8d4-d4ca-4215-8790-013c0b1630c0/AUTO_LUA_MEMORY_CLEANER)

A lightweight, event-driven background memory cleaner designed to help clear out background memory junk during natural breaks.

</div>

**Optional Dependencies:**
This addon requires the following optional library to access the settings GUI menu:
* [LibAddonMenu-2.0](https://www.esoui.com/downloads/info7-LibAddonMenu-2.0.html)

**Without the Dependencies:** You can still run the addon entirely independent, and control its settings via built-in slash commands as a standalone utility.

---

<a id="why-use-this"></a>
<div align="center">

[![WHY USE THIS OVER OTHER MEMORY CLEANERS?](https://img.shields.io/badge/WHY%20USE%20THIS%20OVER%20OTHER%20MEMORY%20CLEANERS%3F-D4A017?style=for-the-badge)](#why-use-this)

</div>

Other memory cleaners use constant "OnUpdate" timers that ping the game every few seconds to check your memory. The timer loops endlessly from the moment you log in. They do often pause the cleanup, but the polling loop keeps firing in the background even during fights. They also often calculate memory strings even when the UI is hidden or closed, are built before console APIs existed, and only track "collectgarbage" <sub>*(ignoring console UI limits)*</sub>, all of which unnecessarily wastes CPU cycles. 

Auto Lua Memory Cleaner uses a dormant, event-driven trigger. It stays completely asleep <sub>*(using 0% CPU)*</sub> and only wakes up to check your memory during natural breaks while playing, such as right after you exit combat or while inside a menu.

<p align="center">
  <img src="https://cdn-eso.mmoui.com/preview/pvw15216.png" alt="Auto Lua Memory Cleaner UI 1" />
  <br>
  <img src="https://cdn-eso.mmoui.com/preview/pvw15318.png" alt="Auto Lua Memory Cleaner UI 2" />
</p>

<a id="features"></a>
<div align="center">

[![FEATURES](https://img.shields.io/badge/FEATURES-D4A017?style=for-the-badge)](#features)

</div>

* <a id="feat-zero"></a>[![Zero Idle Footprint](https://img.shields.io/badge/Zero%20Idle%20Footprint-forestgreen?style=flat-square)](#feat-zero) : Event trigger ensures the addon only runs checks during loading screens, exiting combat state, or while inside a menu.
* <a id="feat-combat"></a>[![Smart Combat Lockout](https://img.shields.io/badge/Smart%20Combat%20Lockout-forestgreen?style=flat-square)](#feat-combat) : Will never force a garbage collection cycle while you are in combat or dead, preventing dangerous mid-fight frame drops <sub>*(Imagine crashing in the middle of your Trifecta, or God Slayer run!)*</sub>.
* <a id="feat-support"></a>[![PC & Console Support](https://img.shields.io/badge/PC%20%26%20Console%20Support-forestgreen?style=flat-square)](#feat-support) : Automatically adapts to your hardware specific memory rules. On PC, it helps you stay safely below the 512MB performance "soft limit" to prevent UI lag and stuttering. On Console, it safely monitors the strict 100MB hardware memory pool to prevent the game from forcefully reloading your UI.
* <a id="feat-sweep"></a>[![Double-Pass Engine Sweep](https://img.shields.io/badge/Double--Pass%20Engine%20Sweep-forestgreen?style=flat-square)](#feat-sweep) : A dual-pass garbage collection cycle to safely force execution of all pending __gc hooks and ensure orphaned weak tables are properly eradicated from the shared memory pool.
* <a id="feat-memento"></a>[![PermMemento Integration](https://img.shields.io/badge/PermMemento%20Integration-forestgreen?style=flat-square)](#feat-memento) : Automatically detects [Permanent Memento](https://www.esoui.com/downloads/info4116-PermanentMemento.html) and disables its internal ALC cleaner.

<a id="usage"></a>
<div align="center">

[![USAGE & SETTINGS](https://img.shields.io/badge/USAGE%20%26%20SETTINGS-purple?style=for-the-badge)](#usage)

</div>

* <kbd>AUTO-CLEANUP</kbd> : Runs silently based on your thresholds.
* <kbd>REPEAT DELAY</kbd> : Configure how long the addon waits to attempt again.
* <kbd>TRACK STATISTICS</kbd> : Toggle to enable session and lifetime tracking.
* <kbd>SCREEN ANNOUNCEMENTS</kbd> : Defaulted ON to show memory freed.
* <kbd>FORCE MANUAL CLEANUP</kbd> : Instantly wipes unused Lua memory.

<a id="commands"></a>
<div align="center">

[![SLASH COMMANDS](https://img.shields.io/badge/SLASH%20COMMANDS-orange?style=for-the-badge)](#commands)

</div>

* <kbd>/alc</kbd> : Displays commands in chat
* <kbd>/alcon</kbd> : Toggle Auto Cleanup
* <kbd>/alcui</kbd> : Toggle Memory UI visibility
* <kbd>/alclock</kbd> : Lock/Unlock UI dragging
* <kbd>/alcreset</kbd> : Reset UI position
* <kbd>/alccsa</kbd> : Toggle Screen Announcements
* <kbd>/alclogs</kbd> <sub>*(PC Only)*</sub> : Toggle Chat Logs
* <kbd>/alcstats</kbd> : Toggle Saving Statistics
* <kbd>/alcclean</kbd> : Force manual Lua memory cleanup

---

<a id="troubleshooting"></a>
<div align="center">

[![TROUBLESHOOTING & SYSTEM LIMITS](https://img.shields.io/badge/TROUBLESHOOTING%20%26%20SYSTEM%20LIMITS-red?style=for-the-badge)](#troubleshooting)

</div>

**Engine Limits & Shared Memory:**
Because the ESO engine manages memory dynamically in a single global pool, we must rely on smart,
threshold-based sweeping rather than passive monitoring. Addons do not run in isolated sandboxes.
They share a single global memory pool. It is technically impossible to accurately track memory usage
per individual addon without breaking shared libraries and cross-addon communication.

> [!WARNING]
> **Important Note On Memory Usage <sub>*(PC & Console)*</sub>:**
> Unlike PC, where memory scales dynamically with a ~512 MB "soft limit" for UI lag, consoles have
> a strict 100 MB hardware memory pool for addons. Reaching the console cap will often cause the
> game to forcefully reload your UI or result in "Out of Memory" crashes.
> 
> While this addon is highly effective at clearing out background "garbage" to keep you under those
> limits, it cannot magically lower your memory usage if you are running too many heavy addons at
> once. If your memory remains dangerously high <sub>*(above 90MB on Console, or 450MB+ on PC)*</sub>
> even after a manual cleanup, you should consider disabling a few large addons to ensure stability.

> [!NOTE]
> **Do You Actually Need This <sub>*(PC & Console)*</sub>?**
> **NO.** If your total Lua memory usage consistently stays below 300 MB on PC
> <sub>*(with an SSD)*</sub>, or below 85 MB on Console, the native ESO engine is
> usually efficient enough on its own. This addon is specifically built for:
> 
> **Power Users:** Players with dozens of heavy addons pushing memory limits.<br>
> **Console Players:** Players already pushing to the 100 MB hardware cap.<br>
> **Performance Freaks / Low-End Users:** Anyone wanting manual control over when memory is cleared.

**TESTED:** I have personally stress tested this addon while having 335+ active addons
enabled <sub>*(some of them are libraries)*</sub> during Dungeon Trifecta
runs on Linux <sub>*(while on Discord, with multiple browser tabs open)*</sub>
and had zero issues and crashes.

---

<a id="license"></a>
<div align="center">

[![LICENSE & USAGE](https://img.shields.io/badge/LICENSE%20%26%20USAGE-red?style=for-the-badge)](#license)

Copyright (c) 2021-2026 @APHONlC. All rights reserved.

**No Redistribution:** Please do not re-upload, mirror, or distribute this script to other platforms <sub>*(ESOUI, NexusMods, etc.)*</sub> without my explicit written permission.

**No Public Modifications:** You may not modify, transform, or build upon this code for the purpose of public release.

**Personal Use:** You are 100% free to tweak and modify the code for your own private, personal use.

Licensed under the **Apache License, Version 2.0**.

<sub>*(For permissions or inquiries, contact @APHONlC on ESOUI or GitHub.)*</sub>

**How to Attribute This Work:**
If you use, redistribute, or modify this script in your own project, please attribute it:<br>
**Project Name:** Auto Lua Memory Cleaner<br>
**Author:** @APHONlC<br>
**License:** Apache License 2.0

**Check out my other addons/projects:**

• [Auto Lua Memory Cleaner](https://www.esoui.com/downloads/fileinfo.php?id=4388#info) 
• [Permanent Memento](https://www.esoui.com/downloads/fileinfo.php?id=4116#info) 
• [Tamriel Trade Center, HarvestMap & ESO-Hub Auto-Updater <sub>*(Linux, macOS, SteamDeck, & Windows)*</sub>](https://www.esoui.com/downloads/fileinfo.php?id=3249#info)

<br>
<a id="bug-reports"></a>

[![BUG REPORTS](https://img.shields.io/badge/BUG%20REPORTS-ff3300?style=for-the-badge)](#bug-reports)

If you encounter any issues, please submit a report here:<br>
**[ESOUI Bug Portal](https://www.esoui.com/portal.php?id=360&a=listbugs) | [GitHub Issue Tracker](https://github.com/MPHONlC/Auto-Lua-Memory-Cleaner/issues)**

<a id="support"></a>

[![SUPPORT](https://img.shields.io/badge/SUPPORT-ff3300?style=for-the-badge)](#support)

If this project has been useful to you, consider supporting its development:<br>
<br>
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-FFDD00?style=for-the-badge&logo=buymeacoffee&logoColor=black)](https://buymeacoffee.com/aph0nlc)

</div>
