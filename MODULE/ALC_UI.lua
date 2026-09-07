-- AutoLuaMemoryCleaner - Copyright 2025-2026 @APHONlC. 
-- Licensed under the GNU General Public License v3.0 (GPLv3). 
-- See LICENSE.md and NOTICE.md.

-- This file must load after Core/ALC_Core.lua.
if not ALC then return end

function ALC.get_gamepad_mover(target)
    if ALC.Console.create_gamepad_mover then
        return ALC.Console.create_gamepad_mover(target)
    end
    return nil
end

function ALC.toggle_ui_update()
    if not ALC.ui_window then return end
    if ALC.settings.show_ui then
        ALC.ui_window:SetHandler("OnUpdate", ALC.ui_update_fn)
    else
        ALC.ui_window:SetHandler("OnUpdate", nil)
    end
    ALC.update_ui_scenes()
end

function ALC.update_ui_anchor()
    if not ALC.ui_window then return end
    ALC.ui_window:ClearAnchors()
    ALC.ui_window:SetScale(ALC.settings.ui_scale or 1.0)
    if ALC.settings.ui_x and ALC.settings.ui_y then
        ALC.ui_window:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, ALC.settings.ui_x, ALC.settings.ui_y)
    else
        if ZO_CompassFrame then
            ALC.ui_window:SetAnchor(RIGHT, ZO_CompassFrame, LEFT, -15, 0)
        else
            ALC.ui_window:SetAnchor(TOP, GuiRoot, TOP, -300, 40)
        end
    end
    ALC.ui_window:SetDimensions(150, 40)
end

function ALC.update_ui()
    if not ALC.settings.show_ui then return end
    local current_lua = ALC.get_hybrid_memory_data()
    local pool_mb = ALC.get_console_pool_mb()
    local combat_str = IsUnitInCombat("player") and ("|cFF0000" .. ALC.L("LABEL_COMBAT") .. "|r ") or ""
    local status_line = ALC.build_memory_status_line(
        current_lua, ALC.session_mb_freed, pool_mb, ALC.session_pool_mb_freed
    )
    ALC.ui_label:SetText(combat_str .. status_line)
    ALC.ui_window:SetDimensions(ALC.ui_label:GetTextWidth() + 20, 40)
end

function ALC.create_ui()
    local is_pad = IsInGamepadPreferredMode()

    local win, text_lbl = LibAPH.CreateStatusWindow({
        name = "AutoLuaCleanerUI",
        movable = not ALC.settings.is_ui_locked,
        isGamepad = is_pad,
        onMoveStop = function(left, top)
            ALC.settings.ui_x = left
            ALC.settings.ui_y = top
        end,
    })

    ALC.ui_window = win
    ALC.update_ui_anchor()

    ALC.ui_mover = ALC.get_gamepad_mover(win)
    if ALC.ui_mover then
        ALC.ui_mover:RegisterCallback(ALC.name .. "_UI", 2, function(new_pos)
            if type(new_pos.left) == "number" then ALC.settings.ui_x = new_pos.left end
            if type(new_pos.top) == "number" then ALC.settings.ui_y = new_pos.top end
        end)
    end

    ALC.ui_label = text_lbl

    ALC.ui_update_fn = function(ctrl, frame_time)
        if not ALC.settings.show_ui then return end
        if frame_time - ALC.last_ui_update < 1.0 then return end
        ALC.last_ui_update = frame_time
        ALC.update_ui()
    end
    ALC.hud_fragment = ZO_HUDFadeSceneFragment:New(win)
end

function ALC.update_ui_scenes()
    if not ALC.hud_fragment then return end
    local valid_scenes = {"hud", "hudui", "gamepad_hud"}

    LibAPH.RemoveFragmentFromScenes(ALC.hud_fragment, valid_scenes)

    if ALC.settings.show_ui and not ALC.settings.is_ui_global then
        LibAPH.AddFragmentToScenes(ALC.hud_fragment, valid_scenes)
    end

    local cur_scene = SCENE_MANAGER:GetCurrentScene()

    if ALC.ui_window then
        if not ALC.settings.show_ui then
            ALC.ui_window:SetHidden(true)
        else
            local should_show = ALC.settings.is_ui_global or (cur_scene and cur_scene:HasFragment(ALC.hud_fragment))
            ALC.ui_window:SetHidden(not should_show)
        end
    end
end

ALC._modules.ui = true