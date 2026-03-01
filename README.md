# [**Auto Lua Memory Cleaner**](https://www.esoui.com/downloads/info4388-AutoLuaMemoryCleaner.html)
[![ESOUI](https://img.shields.io/badge/PC-ESOUI-orange.svg?style=for-the-badge)](https://www.esoui.com/downloads/fileinfo.php?id=4388)
[![Bethesda Mods](https://img.shields.io/badge/Console-Bethesda.net-black.svg?style=for-the-badge&logo=bethesda&logoColor=white)](https://mods.bethesda.net/en/elderscrollsonline/details/9926b8d4-d4ca-4215-8790-013c0b1630c0/AUTO_LUA_MEMORY_CLEANER)

A lightweight, event driven background memory cleaner designed to eliminate performance stuttering with 0% idle CPU usage.

## Optional Dependencies
This addon requires the following optional library to access the settings GUI menu:
* [LibAddonMenu-2.0](https://www.esoui.com/downloads/info7-LibAddonMenu-2.0.html)

**Without the Dependencies:** you can still run the addon entirely independent, and control its settings via built-in slash commands as a standalone control.

## Why use this over other memory cleaners? 
Other memory cleaners uses a constant "OnUpdate" timers that pings the game every few seconds to check your memory, the timer loops endlessly from the moment you log in, they do often pauses the cleanup, but the polling loop keeps firing in the background even during fights, they also often calculate memory strings even when the UI is hidden or closed, they are built before console APIs existed, they only track "collectgarbage", ignoring console UI limits, all of which unnecessarily wastes CPU cycles. Auto Lua Memory Cleaner uses a **dormant, event driven trigger**. It stays completely asleep (using 0% CPU) and only wakes up to check your memory during natural breaks while playing, such as right after you exit combat or close a menu.

<p align="center">
  <img src="https://cdn-eso.mmoui.com/preview/pvw15216.png" alt="Permanent Memento UI 1" />
  <br>
  <img src="https://cdn-eso.mmoui.com/preview/pvw15318.png" alt="Permanent Memento UI 2" />
</p>

## Features
* **Zero Idle Footprint:** Event trigger ensures the addon only runs checks during loading screens, exiting combat, or closing a menu.
* **Smart Combat Lockout:** Will never force a garbage collection cycle while you are in combat or dead, preventing dangerous mid fight frame drops. (Imagine crashing in the middle of your Trifecta, or God Slayer run!)
* **(PC & Console) Support:** Automatically adapts to your hardware specific memory rules. On PC, it helps you stay safely below the 512MB performance "soft limit" to prevent UI lag and stuttering. On Console, it safely monitors the strict 100MB hardware memory pool to prevent the game from forcefully reloading your UI.
* **Customizable Thresholds:** Set exactly how much memory can build up before a cleanup is triggered (Defaults to 400MB on PC, and 85MB on Console).
* **PermMemento Integration:** Automatically detects if my [**PermMemento**](https://www.esoui.com/downloads/info4116-PermanentMemento.html) addon is installed and quietly disables its internal memory cleaner so they never fight each other.

## Usage & Settings
* **AUTO-CLEANUP:** Runs silently in the background once installed.
* **SETTINGS MENU:** Allows you to adjust PC and Console memory thresholds independently.
* **REPEAT DELAY:** Configure how long the addon waits to attempt another cleanup if your memory is still over the limit.
* **SCREEN ANNOUNCEMENTS:** Toggle the on screen text alert showing exactly how many Megabytes of memory were freed.
* **FORCE MANUAL CLEANUP:** A button in the settings to instantly manually wipe unused Lua memory.

---

### Slash Commands

| Command | Description |
| :--- | :--- |
| `/alc` | Displays commands list (Alias: `/autoluaclean`) |
| `/alcon` | Toggle Auto Cleanup (Alias: `/alcenable`) |
| `/alcui` | Toggle Memory UI visibility (Alias: `/alctoggleui`) |
| `/alclock` | Lock/Unlock UI dragging (Alias: `/alcuilock`) |
| `/alcreset` | Reset Memory UI position (Alias: `/alcuireset`) |
| `/alccsa` | Toggle Screen Announcements (Alias: `/alctogglecsa`) |
| `/alcclean` | Force manual Lua memory cleanup (Alias: `/alccleanup`) |
| `/alclogs` | **(PC Only)** Toggle Chat Logs (Alias: `/alcchatlogs`) |

<div align="center">

### ⚠️ IMPORTANT NOTE ON MEMORY USAGE ⚠️
The ESO engine now dynamically scales Lua memory, meaning there is no strict hard cap crash limit on PC. However, **512 MB** is generally the "soft limit" where players will start to notice slower loading screens, UI lag, and general performance degradation. You can test this yourself by disabling all your addons and turning them back on one by one to feel the performance drop.

While this addon is highly effective at clearing out unused background garbage, it cannot magically lower your memory usage if you are simply running too many heavy addons at once. If your memory remains dangerously high even after a cleanup, you will need to consider disabling a few large addons to stay within safe limits.

<br>

> ### BUG REPORTS
> [ESOUI Bug Portal](https://www.esoui.com/portal.php?id=360&a=listbugs)

If you encounter any issues, please submit a report here or on ESOUI.

</div>

## Support

If this project has been useful to you, consider supporting its development:

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://buymeacoffee.com/aph0nlc)
