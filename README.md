# [**Auto Lua Memory Cleaner**](https://www.esoui.com/downloads/info4388-AutoLuaMemoryCleaner.html)
[![ESOUI](https://img.shields.io/badge/PC-ESOUI-orange.svg?style=for-the-badge)](https://www.esoui.com/downloads/fileinfo.php?id=4388)
[![Bethesda Mods](https://img.shields.io/badge/Console-Bethesda.net-black.svg?style=for-the-badge&logo=bethesda&logoColor=white)](https://mods.bethesda.net/en/elderscrollsonline/details/9926b8d4-d4ca-4215-8790-013c0b1630c0/AUTO_LUA_MEMORY_CLEANER)

A lightweight, event-driven background memory cleaner designed to eliminate performance stuttering with 0% idle CPU usage.

## 🛠️ Optional Dependencies
This addon requires the following optional library to access the settings GUI menu:
* [LibAddonMenu-2.0](https://www.esoui.com/downloads/info7-LibAddonMenu-2.0.html)

**Without the Dependencies:** you can still run the addon entirely independent, and control its settings via built-in slash commands as a standalone control.

## ❓ Why use this over other memory cleaners? 
Other memory cleaners use constant "OnUpdate" timers that ping the game every few seconds to check your memory. The timer loops endlessly from the moment you log in; while they often pause the cleanup, the polling loop keeps firing in the background even during fights. They also often calculate memory strings even when the UI is hidden or closed. Many were built before console APIs existed and only track `collectgarbage`, ignoring console UI limits, all of which unnecessarily wastes CPU cycles. 

Auto Lua Memory Cleaner uses a **dormant, event-driven trigger**. It stays completely asleep (using 0% CPU) and only wakes up to check your memory during natural breaks while playing, such as right after you exit combat or close a menu.

<p align="center">
  <img src="https://cdn-eso.mmoui.com/preview/pvw15216.png" alt="Permanent Memento UI 1" />
  <br>
  <img src="https://cdn-eso.mmoui.com/preview/pvw15318.png" alt="Permanent Memento UI 2" />
</p>

## ✨ Features
* **Zero Idle Footprint:** Event trigger ensures the addon only runs checks during loading screens, exiting combat state, or closing a menu.
* **Smart Combat Lockout:** Will never force a garbage collection cycle while you are in combat or dead, preventing dangerous mid-fight frame drops. (Imagine crashing in the middle of your Trifecta, or God Slayer run!)
* **(PC & Console) Support:** Automatically adapts to your hardware-specific memory rules. On PC, it helps you stay safely below the 512MB performance "soft limit" to prevent UI lag and stuttering. On Console, it safely monitors the strict 100MB hardware memory pool to prevent the game from forcefully reloading your UI.
* **PermMemento Integration:** Automatically detects [**Permanent Memento**](https://www.esoui.com/downloads/info4116-PermanentMemento.html) and disables its internal ALC cleaner.

## ⚙️ Usage & Settings
* **AUTO-CLEANUP:** Runs silently in the background once installed.
* **REPEAT DELAY:** Configure how long the addon waits to attempt another cleanup if your memory is still over the limit.
* **TRACK STATISTICS:** Toggle this in the settings or via slash command to enable session/lifetime cleaned memory tracking.
* **SCREEN ANNOUNCEMENTS:** Defaulted **ON** to show you how much memory was freed.
* **FORCE MANUAL CLEANUP:** A button in the settings to instantly manually wipe unused Lua memory.

---

### ⌨️ Slash Commands

| Command | Description |
| :--- | :--- |
| `/alc` | Displays the help menu and all available commands in chat (Alias: `/autoluaclean`) |
| `/alcon` | Toggle the background Auto Cleanup system ON or OFF (Alias: `/alcenable`) |
| `/alcui` | Toggle the visibility of the on-screen Memory Monitor (Alias: `/alctoggleui`) |
| `/alclock` | Lock or Unlock the Memory Monitor UI to drag it around the screen (Alias: `/alcuilock`) |
| `/alcreset` | Reset the Memory Monitor position and scale to default (Alias: `/alcuireset`) |
| `/alcstats` | Toggle the tracking and saving of session/total memory statistics |
| `/alccsa` | Toggle large Screen Announcements for memory cleanup events (Alias: `/alctogglecsa`) |
| `/alcclean` | Immediately force a manual Lua memory garbage collection sweep (Alias: `/alccleanup`) |

<div align="center">

### ⚠️ IMPORTANT NOTE ON MEMORY USAGE ⚠️
The ESO engine scales Lua memory dynamically, meaning there is no strict hard cap. However, **512 MB** is generally the "soft limit" on PC where slower loading screens and UI lag begin as garbage collection becomes more taxing on the CPU.

While highly effective at clearing background garbage, this addon cannot magically lower memory usage if you are running too many heavy addons. If memory remains high after a cleanup, consider disabling large addons.

### SO, DO YOU ACTUALLY NEED THIS?
If your total Lua memory usage stays below **300 MB** and you run on an SSD, the native engine is usually efficient enough. This addon is built for:

* **Power Users:** Players with dozens of heavy addons pushing memory limits.
* **Console Players:** Players already pushing to the **100 MB** hardware cap.
* **Performance Freaks/Low End Users:** Anyone wanting manual control over *when* memory is cleared.

</div>

**TESTED:** I have personally stress tested this addon while having **335+ active addons** enabled (some of them are libraries) during **Dungeon Trifecta** runs on Linux (while on Discord, with multiple browser tabs open among other things) and had zero issues.

---

## 📜 LICENSE

**Copyright 2025-2026 @APHONlC**

Licensed under the **Apache License, Version 2.0** (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at:

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, **WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND**, either express or implied. See the License for the specific language governing permissions and limitations under the License.

*For permissions or inquiries, contact @APHONlC on ESOUI or GitHub.*

### How to Attribute This Work
If you use, redistribute, or modify this script in your own project, please use the following attribution format:

* **Project Name:** Auto Lua Memory Cleaner
* **Author:** @APHONlC
* **License:** Apache License 2.0
* **Original Source:** [Auto Lua Memory Cleaner](https://www.esoui.com/downloads/info4388-AutoLuaMemoryCleanerPCampConsole.html)

### 📂 Check out my other addons/projects:
* [Auto Lua Memory Cleaner](https://www.esoui.com/downloads/fileinfo.php?id=4388#info) - Intelligent, low footprint event based LUA memory garbage collection for PC and Console.
* [Permanent Memento](https://www.esoui.com/downloads/fileinfo.php?id=4116#info) - Automate and loop or share your favorite mementos.
* [Tamriel Trade Center, HarvestMap & ESO-Hub Auto-Updater (Linux, macOS, SteamDeck, & Windows)](https://www.esoui.com/downloads/fileinfo.php?id=3249#info) - Cross-platform data updater for Linux, macOS, SteamDeck, and Windows.

<div align="center">

### 🐛 BUG REPORTS
If you encounter any issues, please submit a report here:
[ESOUI Bug Portal](https://www.esoui.com/portal.php?id=360&a=listbugs) | [GitHub Issue Tracker](https://github.com/MPHONlC/Auto-Lua-Memory-Cleaner/issues)

## Support

If this project has been useful to you, consider supporting its development:

[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://buymeacoffee.com/aph0nlc)

</div>
