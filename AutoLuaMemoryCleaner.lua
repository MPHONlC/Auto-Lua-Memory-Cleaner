-- Auto Lua Memory Cleaner
-- LICENSE
-- Copyright 2025-2026 @APHONlC
-- Licensed under the Apache License, Version 2.0.

-- TESTED: 2026-03-13 | Release v0.0.7 | APIVersion: 101049 | LAM2 v41
local is_release_build = true
local REQUIRED_LAM_VERSION = 41

local AutoLuaCleaner = {
    name = "AutoLuaMemoryCleaner",
    version = "0.0.7",
    defaults = {
        is_enabled = true,
        threshold_pc = 400,
        threshold_console = 85,
        fallback_delay_sec = 300,
        is_csa_enabled = true,
        is_log_enabled = false,
        show_ui = false,
        is_ui_locked = false,
        ui_x = nil,
        ui_y = nil,
        track_stats = false,
        is_migrated_007 = false,
        has_shown_lib_warning_007 = false,
        total_cleanups = 0,
        total_mb_freed = 0,
        last_session_cleanups = 0,
        last_session_mb_freed = 0,
        prev_session_cleanups = 0,
        prev_session_mb_freed = 0,
        install_date = nil,
        is_graph_enabled = false,
        is_stats_log_enabled = false,
        session_history = {},
        graph_x = nil,
        graph_y = nil,
        is_graph_locked = false,
        is_graph_detached = false,
        is_graph_global = false,
        version_history = {},
        show_mem_ui_bar = false,
        show_graph_diags = false,
        lite_mode = false,
        track_fps = false,
        track_ping = false,
        track_memory_gains = false,
        show_session_ui = false,
        session_ui_x = nil,
        session_ui_y = nil,
        is_session_locked = false,
        session_track_peak = false,
        session_track_avg = false,
        session_track_final = false,
        session_track_cleaned = false
    },
    mem_state = 0,
    is_mem_check_queued = false,
    session_cleanups = 0,
    session_mb_freed = 0,
    last_priority_save_time = 0,
    last_ui_update = 0,
    is_scene_callback_registered = false,
    scene_callback_fn = nil,
    ui_update_fn = nil
}

local graph_window = nil
local max_points = 60
local last_graph_mb = 0
local session_peak_mb = 0

local graph_labels = {}
local graph_segments = {}
local graph_grid_lines = {}
local graph_labels_x = {}
local graph_grid_lines_v = {}
local graph_latency_dots = {}
local graph_labels_lat = {}
local graph_latency_pool = {}

local diag_labels = {}
local graph_last_diag_time = 0
local graph_last_sec_mb = 0

local stat_ticks = 0
local stat_total_ping = 0
local stat_baseline_fps = 0
local stat_fps_stable_ticks = 0
local stat_last_fps_raw = 0
local stat_baseline_ping = 0
local stat_ping_stable_ticks = 0
local stat_last_ping_raw = 0

local session_window = nil
local history_label = nil
local stat_session_ticks = 0
local stat_session_fps_loss_max = 0
local stat_session_fps_loss_final = 0
local stat_session_ping_max = 0
local stat_session_ping_final = 0
local stat_session_ping_total = 0
local stat_session_kb_max = 0
local stat_session_kb_final = 0
local stat_session_kb_total = 0
local stat_session_mb_max = 0
local stat_session_mb_final = 0
local stat_session_mb_total = 0
local stat_session_fps_loss_total = 0
local stat_session_current_mb_total = 0

function AutoLuaCleaner:get_hybrid_memory_data()
    if IsConsoleUI() then return GetTotalUserAddOnMemoryPoolUsageMB() end
    return collectgarbage("count") / 1024
end

function AutoLuaCleaner:get_alc_color(val, is_spike_mb)
    local limit = IsConsoleUI() and self.settings.threshold_console or self.settings.threshold_pc
    local pct = math.min((val / limit) * 100, 100)
    
    if is_spike_mb then
        if pct >= 90 then return 1, 0, 0, "|cFF0000"
        elseif pct >= 75 then return 1, 0.5, 0, "|cFFA500"
        else return 0, 1, 0, "|c00FF00" end
    else
        if val > (IsConsoleUI() and 90 or 475) then return 1, 0, 0, "|cFF0000"
        elseif val > (IsConsoleUI() and 75 or 300) then return 1, 1, 0, "|cFFFF00"
        else return 0, 1, 0, "|c00FF00" end
    end
end

function AutoLuaCleaner:get_gradient_color(block_mb, peak_mb)
    if IsConsoleUI() then
        if block_mb <= 75 then 
            local f = block_mb / 75; return 0, 0.3 + (0.7 * f), 0 
        elseif block_mb <= 85 then 
            local f = (block_mb - 75) / 10; return 0.6 + (0.4 * f), 0.3 + (0.3 * f), 0 
        else 
            local f = math.min((block_mb - 85) / math.max(peak_mb - 85, 1), 1)
            return 0.6 + (0.4 * f), 0.2 * f, 0.2 * f 
        end
    else
        if block_mb <= 300 then 
            local f = block_mb / 300; return 0, 0.3 + (0.7 * f), 0
        elseif block_mb <= 475 then 
            local f = (block_mb - 300) / 175; return 0.6 + (0.4 * f), 0.3 + (0.3 * f), 0
        else 
            local f = math.min((block_mb - 475) / math.max(peak_mb - 475, 1), 1)
            return 0.6 + (0.4 * f), 0.2 * f, 0.2 * f 
        end
    end
end

function AutoLuaCleaner:set_tag_alignment(l, y_off) 
    l:ClearAnchors()
    l:SetAnchor(LEFT, graph_window, TOPLEFT, 305, y_off - 6) 
end

function AutoLuaCleaner:check_session_peak()
    if not self.settings.is_stats_log_enabled then return end
    local current_mb = self:get_hybrid_memory_data()
    if current_mb > session_peak_mb then session_peak_mb = current_mb end
end

function AutoLuaCleaner:update_graph_visuals()
    local alc = self
    if not alc.settings.is_graph_enabled or not graph_window or graph_window:IsHidden() then
        return
    end
    
    if alc.settings.lite_mode and not alc.settings.show_graph_diags then return end
    alc.graph_data = alc.graph_data or {} 
    
    local is_lite = alc.settings.lite_mode
    local current_mb = alc:get_hybrid_memory_data()
    local current_lat = alc.settings.track_ping and GetLatency() or 0
    local fps = alc.settings.track_fps and GetFramerate() or 0
    local delta_mb = current_mb - last_graph_mb
    local gain_pop = (delta_mb > 0) and 1.0 or 0.3
    last_graph_mb = current_mb
    
    if not is_lite then
        local peak_mb = IsConsoleUI() and 100 or 512
        for _, v in ipairs(alc.graph_data) do 
            if v > peak_mb then peak_mb = v end 
        end
        
        if current_mb > peak_mb then peak_mb = current_mb end
        table.insert(alc.graph_data, current_mb)
        if #alc.graph_data > max_points then table.remove(alc.graph_data, 1) end
        
        if alc.settings.track_ping then
            table.insert(graph_latency_pool, current_lat)
            if #graph_latency_pool > max_points then table.remove(graph_latency_pool, 1) end
        end
        
        local max_rows = 36
        for i = 1, #alc.graph_data do
            local val = alc.graph_data[i]
            local lat_val = graph_latency_pool[i]
            local prev_val = (i > 1) and alc.graph_data[i-1] or val
            
            local is_kb_shift = alc.settings.track_memory_gains 
                and (val - prev_val) > 0.001 
                and (val - prev_val) < 1.0
                
            local tail_alpha = (0.2 + 0.8 * (i / max_points))
            local final_alpha = (i == #alc.graph_data) and gain_pop or tail_alpha
            local active_blocks = math.max(math.floor((val / peak_mb) * max_rows), 1)
            
            for j = 1, max_rows do
                local seg = graph_segments[i][j]
                if j == active_blocks then
                    local r, g, b = alc:get_gradient_color((j / max_rows) * peak_mb, peak_mb)
                    seg:SetColor(r, g, b, final_alpha)
                    seg:SetHidden(false)
                elseif j == (active_blocks + 1) and is_kb_shift then
                    local kb_factor = math.min((val - prev_val) / 1.0, 1.0)
                    local kr, kg, kb = 0.5 + (0.5 * kb_factor), 0.2 * kb_factor, 0.5 + (0.5 * kb_factor)
                    seg:SetColor(kr, kg, kb, final_alpha)
                    seg:SetHidden(false)
                else 
                    seg:SetHidden(true) 
                end
            end
            
            if alc.settings.track_ping and graph_latency_dots[i] and lat_val then
                local lat_peak = IsConsoleUI() and 350 or 1000
                local lat_active = math.max(math.floor((lat_val / lat_peak) * max_rows), 1)
                local seg = graph_segments[i][lat_active]
                if seg then
                    graph_latency_dots[i]:SetColor(1, 0, 0, final_alpha)
                    graph_latency_dots[i]:ClearAnchors()
                    graph_latency_dots[i]:SetAnchor(CENTER, seg, CENTER, 0, 0)
                    graph_latency_dots[i]:SetHidden(false)
                else 
                    graph_latency_dots[i]:SetHidden(true) 
                end
            else 
                if graph_latency_dots[i] then graph_latency_dots[i]:SetHidden(true) end 
            end
        end
        
        local markers = IsConsoleUI() 
            and {0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100} 
            or {0, 64, 128, 192, 256, 320, 384, 448, 512}
            
        if peak_mb > (IsConsoleUI() and 100 or 512) then 
            table.insert(markers, math.ceil(peak_mb)) 
        end
        
        local lat_peak = IsConsoleUI() and 350 or 1000
        local lat_markers = IsConsoleUI() 
            and {0, 50, 100, 150, 200, 250, 300, 350} 
            or {0, 125, 250, 375, 500, 625, 750, 875, 1000}
            
        for _, l in ipairs(graph_labels) do l:SetHidden(true) end
        for _, gl in ipairs(graph_grid_lines) do gl:SetHidden(true) end
        for _, l in ipairs(graph_labels_lat) do l:SetHidden(true) end
        
        for i, mark in ipairs(markers) do
            local lbl = graph_labels[i]
            local g_line = graph_grid_lines[i]
            if lbl and (mark <= peak_mb or mark == 0) then
                local y_offset = 180 - ((mark / peak_mb) * 180)
                alc:set_tag_alignment(lbl, y_offset)
                lbl:SetText(mark .. "MB")
                lbl:SetHidden(false)
                if g_line then
                    g_line:ClearAnchors()
                    g_line:SetAnchor(LEFT, graph_window, TOPLEFT, 60, y_offset)
                    g_line:SetAnchor(RIGHT, graph_window, TOPLEFT, 300, y_offset)
                    g_line:SetHidden(false)
                end
            end
        end
        
        if alc.settings.track_ping then
            for i, mark in ipairs(lat_markers) do
                local lbl = graph_labels_lat[i]
                if lbl and (mark <= lat_peak or mark == 0) then
                    local y_offset = 180 - ((mark / lat_peak) * 180)
                    lbl:ClearAnchors()
                    lbl:SetAnchor(RIGHT, graph_window, TOPLEFT, 55, y_offset - 6)
                    lbl:SetText(mark .. "ms")
                    lbl:SetHidden(false)
                end
            end
        end
        
        local x_vals = {"15s", "12s", "9s", "6s", "3s", "0s"}
        for i, l in ipairs(graph_labels_x) do 
            l:SetText(x_vals[i])
            l:SetHidden(false) 
        end
    end
    
    local current_time = GetFrameTimeMilliseconds()
    if not graph_last_diag_time or (current_time - graph_last_diag_time) >= 1000 then
        graph_last_diag_time = current_time
        local gain_mb = 0
        local gain_kb = 0
        
        local needs_math = alc.settings.show_graph_diags 
            or alc.settings.session_track_peak 
            or alc.settings.session_track_avg 
            or alc.settings.session_track_final
            
        if needs_math then
            graph_last_sec_mb = graph_last_sec_mb == 0 and current_mb or graph_last_sec_mb
            gain_mb = math.max(current_mb - graph_last_sec_mb, 0)
            graph_last_sec_mb = current_mb
            gain_kb = gain_mb * 1024
            
            if alc.settings.session_track_peak then
                if current_mb > session_peak_mb then session_peak_mb = current_mb end
                if gain_kb > stat_session_kb_max then stat_session_kb_max = gain_kb end
                if gain_mb > stat_session_mb_max then stat_session_mb_max = gain_mb end
                if alc.settings.track_ping and current_lat > stat_session_ping_max then 
                    stat_session_ping_max = current_lat 
                end
            end
            
            if alc.settings.session_track_avg then
                stat_session_ticks = stat_session_ticks + 1
                stat_session_kb_total = stat_session_kb_total + gain_kb
                stat_session_mb_total = stat_session_mb_total + gain_mb
                stat_session_current_mb_total = stat_session_current_mb_total + current_mb
                if alc.settings.track_ping then 
                    stat_session_ping_total = stat_session_ping_total + current_lat 
                end
            end
            
            if alc.settings.session_track_final then
                stat_session_kb_final = gain_kb
                stat_session_mb_final = gain_mb
                if alc.settings.track_ping then stat_session_ping_final = current_lat end
            end
        end
        
        if alc.settings.show_graph_diags then
            local limit = IsConsoleUI() and alc.settings.threshold_console or alc.settings.threshold_pc
            local pct = math.min((current_mb / limit) * 100, 100)
            local c_fps = "|c888888Off|r"; local c_drop = "|c888888Off|r"
            local c_ping = "|c888888Off|r"; local c_avg = "|c888888Off|r"
            local c_spike = "|c888888Off|r"
            local r, g, b, alc_status_color = alc:get_alc_color(current_mb, true)
            
            if alc.settings.track_fps then
                if stat_baseline_fps == 0 or fps > stat_baseline_fps then
                    stat_baseline_fps = fps
                    stat_fps_stable_ticks = 0
                elseif math.abs(fps - stat_last_fps_raw) <= 2 then
                    stat_fps_stable_ticks = stat_fps_stable_ticks + 1
                    if stat_fps_stable_ticks >= 60 then 
                        stat_baseline_fps = fps
                        stat_fps_stable_ticks = 0 
                    end
                else 
                    stat_fps_stable_ticks = 0 
                end
                stat_last_fps_raw = fps
                
                local fps_drop = math.max(stat_baseline_fps - fps, 0)
                if alc.settings.session_track_peak and fps_drop > stat_session_fps_loss_max then 
                    stat_session_fps_loss_max = fps_drop 
                end
                if alc.settings.session_track_final then 
                    stat_session_fps_loss_final = fps_drop 
                end
                if alc.settings.session_track_avg then 
                    stat_session_fps_loss_total = stat_session_fps_loss_total + fps_drop 
                end
                
                c_fps = fps >= 50 and "|c00FF00" or (fps >= 30 and "|cFFA500" or "|cFF0000")
                c_drop = fps_drop <= 5 and "|c00FF00" or (fps_drop <= 15 and "|cFFA500" or "|cFF0000")
                diag_labels.fps:SetText(string.format("FPS: %s%d|r", c_fps, fps))
                diag_labels.fps_drop:SetText(string.format("FPS Loss: %s-%d|r", c_drop, fps_drop))
            else 
                diag_labels.fps:SetText("FPS: Off")
                diag_labels.fps_drop:SetText("FPS Loss: Off") 
            end
            
            if alc.settings.track_ping then
                stat_ticks = stat_ticks + 1
                stat_total_ping = stat_total_ping + current_lat
                
                if stat_baseline_ping == 0 or current_lat < stat_baseline_ping then
                    stat_baseline_ping = current_lat
                    stat_ping_stable_ticks = 0
                elseif math.abs(current_lat - stat_last_ping_raw) <= 10 then
                    stat_ping_stable_ticks = stat_ping_stable_ticks + 1
                    if stat_ping_stable_ticks >= 60 then 
                        stat_baseline_ping = current_lat
                        stat_ping_stable_ticks = 0 
                    end
                else 
                    stat_ping_stable_ticks = 0 
                end
                stat_last_ping_raw = current_lat
                
                local current_spike = 0
                if current_lat > stat_baseline_ping + 50 then 
                    current_spike = current_lat - stat_baseline_ping 
                end
                
                local avg_ping = math.floor(stat_total_ping / stat_ticks)
                c_ping = current_lat <= 100 and "|c00FF00" or (current_lat <= 200 and "|cFFA500" or "|cFF0000")
                c_avg = avg_ping <= 100 and "|c00FF00" or (avg_ping <= 200 and "|cFFA500" or "|cFF0000")
                c_spike = current_spike == 0 and "|c00FF00" or (current_spike <= 100 and "|cFFA500" or "|cFF0000")
                
                diag_labels.ms:SetText(string.format("|cFF8C00ms|r: %s%d|r", c_ping, current_lat))
                diag_labels.avg_ms:SetText(string.format("Avg |cFF8C00ms|r: %s%d|r", c_avg, avg_ping))
                diag_labels.spike_pct:SetText(string.format("Spike: %s+%dms|r", c_spike, current_spike))
            else 
                diag_labels.ms:SetText("|cFF8C00ms|r: Off")
                diag_labels.avg_ms:SetText("Avg |cFF8C00ms|r: Off")
                diag_labels.spike_pct:SetText("Spike: Off") 
            end
            
            if alc.settings.track_memory_gains then
                local _, _, _, mb_status_color = alc:get_alc_color(current_mb, true)
                diag_labels.kb:SetText(string.format("|cFF00FFAvg KB|r: %d", gain_kb))
                diag_labels.mb:SetText(string.format("|cFFFFFFAvg MB|r: %s%.2f|r", mb_status_color, gain_mb))
            else 
                diag_labels.kb:SetText("|cFF00FFAvg KB|r: Off")
                diag_labels.mb:SetText("|cFFFFFFAvg MB|r: Off") 
            end
            
            diag_labels.pct:SetText(string.format("Total: %s%d%%|r", alc_status_color, pct))
        end
        
        if is_lite then alc:update_history_text() end
    end
end

function AutoLuaCleaner:get_settings_library()
    local addon_manager = GetAddOnManager()
    local lam_version = 0
    for i = 1, addon_manager:GetNumAddOns() do
        local addon_name, _, _, _, _, addon_state = addon_manager:GetAddOnInfo(i)
        if addon_name == "LibAddonMenu-2.0" and addon_state == ADDON_STATE_ENABLED then
            lam_version = addon_manager:GetAddOnVersion(i)
            return "LAM2", lam_version
        end
    end
    return "NONE", 0
end

function AutoLuaCleaner:format_memory(value_mb)
    if value_mb >= 1048576 then return string.format("%.2f TB", value_mb / 1048576)
    elseif value_mb >= 1024 then return string.format("%.2f GB", value_mb / 1024)
    elseif value_mb >= 1 then return string.format("%.2f MB", value_mb)
    else return string.format("%d KB", math.floor(value_mb * 1024)) end
end

function AutoLuaCleaner:refresh_stats_tracker()
    if not self.settings then return end
    if self.settings.track_stats and not IsConsoleUI() then
        EVENT_MANAGER:RegisterForUpdate(AutoLuaCleaner.name .. "_StatsUpdate", 1000, function()
            local stats_ctrl = _G["ALC_StatsText"]
            if stats_ctrl and stats_ctrl.desc and not stats_ctrl:IsHidden() then
                stats_ctrl.desc:SetText(AutoLuaCleaner:get_stats_text())
            end
        end)
    else 
        EVENT_MANAGER:UnregisterForUpdate(AutoLuaCleaner.name .. "_StatsUpdate") 
    end
end

function AutoLuaCleaner:toggle_core_events()
    if self.settings.is_enabled then
        EVENT_MANAGER:RegisterForEvent(self.name .. "_CombatState", EVENT_PLAYER_COMBAT_STATE, 
            function(event_code, in_combat) 
                if not in_combat then self:trigger_memory_check("CombatEnd", 3000) end 
            end
        )
        if SCENE_MANAGER and not self.is_scene_callback_registered then
            self.scene_callback_fn = function(scene, old_state, new_state)
                if new_state == SCENE_SHOWN then
                    if scene.name ~= "hud" and scene.name ~= "hudui" then 
                        AutoLuaCleaner:trigger_memory_check("Menu", 6000) 
                    end
                end
            end
            SCENE_MANAGER:RegisterCallback("SceneStateChanged", self.scene_callback_fn)
            self.is_scene_callback_registered = true
        end
    else
        EVENT_MANAGER:UnregisterForEvent(self.name .. "_CombatState", EVENT_PLAYER_COMBAT_STATE)
        if SCENE_MANAGER and self.is_scene_callback_registered then
            SCENE_MANAGER:UnregisterCallback("SceneStateChanged", self.scene_callback_fn)
            self.is_scene_callback_registered = false
        end
        EVENT_MANAGER:UnregisterForUpdate(AutoLuaCleaner.name .. "_Fallback")
        self.mem_state = 0
        self.is_mem_check_queued = false
    end
end

function AutoLuaCleaner:toggle_ui_update()
    if not self.ui_window then return end
    if self.settings.show_ui then
        self.ui_window:SetHandler("OnUpdate", self.ui_update_fn)
        self.ui_window:SetHidden(false)
    else 
        self.ui_window:SetHandler("OnUpdate", nil)
        self.ui_window:SetHidden(true) 
    end
    
    if self.settings.is_graph_enabled and self.settings.show_ui then
        if not graph_window then self:build_graph_ui() end
        graph_window:SetHidden(false)
        EVENT_MANAGER:RegisterForUpdate("ALC_GraphTick", 250, function() 
            AutoLuaCleaner:update_graph_visuals() 
        end)
    else
        EVENT_MANAGER:UnregisterForUpdate("ALC_GraphTick")
        if graph_window then graph_window:SetHidden(true) end
    end
    self:update_ui_scenes()
end

function AutoLuaCleaner:safe_csa(text, custom_limit)
    if not self.settings.is_csa_enabled or not CENTER_SCREEN_ANNOUNCE then return end
    local limit = custom_limit or 70 
    
    if string.len(text) <= limit then
        local params = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(CSA_CATEGORY_LARGE_TEXT, SOUNDS.NONE)
        params:SetText(text)
        params:SetLifespanMS(4000)
        CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(params)
        return
    end
    
    local chunks = {}
    local current_chunk = ""
    
    for word in string.gmatch(text, "%S+") do
        local test_str = (current_chunk == "") and word or (current_chunk .. " " .. word)
        if string.len(test_str) > limit and current_chunk ~= "" then 
            table.insert(chunks, current_chunk)
            current_chunk = word
        else 
            current_chunk = test_str 
        end
    end
    
    if current_chunk ~= "" then table.insert(chunks, current_chunk) end

    local delay_ms = 0
    local active_color = ""
    
    for i, chunk in ipairs(chunks) do
        local final_msg = chunk
        if i > 1 then final_msg = active_color .. "..." .. final_msg end
        if i < #chunks then final_msg = final_msg .. "..." end
        
        local idx = 1
        while idx <= string.len(chunk) do
            local c_tag = string.match(chunk, "^|c%x%x%x%x%x%x", idx)
            if c_tag then 
                active_color = c_tag; idx = idx + 8
            elseif string.sub(chunk, idx, idx + 1) == "|r" then 
                active_color = ""; idx = idx + 2
            else 
                idx = idx + 1 
            end
        end
        
        local opens = 0
        for _ in string.gmatch(final_msg, "|c%x%x%x%x%x%x") do opens = opens + 1 end
        local closes = 0
        for _ in string.gmatch(final_msg, "|r") do closes = closes + 1 end
        if opens > closes then final_msg = final_msg .. "|r" end

        if delay_ms > 0 then
            zo_callLater(function() 
                local params = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(
                    CSA_CATEGORY_LARGE_TEXT, SOUNDS.NONE
                )
                params:SetText(final_msg)
                params:SetLifespanMS(4000)
                CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(params)
            end, delay_ms)
        else
            local params = CENTER_SCREEN_ANNOUNCE:CreateMessageParams(
                CSA_CATEGORY_LARGE_TEXT, SOUNDS.NONE
            )
            params:SetText(final_msg)
            params:SetLifespanMS(4000)
            CENTER_SCREEN_ANNOUNCE:AddMessageWithParams(params)
        end
        delay_ms = delay_ms + 1500
    end
end

function AutoLuaCleaner:get_stats_text()
    if not self.settings.track_stats then 
        return "Tracking DISABLED. Enable 'Track Statistics' or type /alcstats to view live data." 
    end
    
    local current_mb = self:get_hybrid_memory_data()
    local mem_warning = ""
    local lua_limit_txt = ""
    
    if IsConsoleUI() then
        lua_limit_txt = "100 MB (Hard Limit)"
        mem_warning = current_mb > 85 and "|cFF0000(EXCEEDS CONSOLE LIMIT)|r" or "|c00FF00(Safe)|r" 
    else
        lua_limit_txt = "Dynamic [512MB] (Auto-Scaling)"
        mem_warning = current_mb > 400 and "|cFFA500(High Global Memory)|r" or "|c00FF00(Safe)|r" 
    end
    
    local install_date = self.settings.install_date or "Unknown"
    local v_history_text = table.concat(self.settings.version_history or {self.version}, ", ")
    local lib_type, lam_version = self:get_settings_library()
    local lib_text = lib_type == "LAM2" 
        and string.format("LibAddonMenu (v%d)", lam_version) 
        or "Not Installed"

    return string.format(
        "Installed Since: %s\nVersion History: %s\nActive Library: %s\n" ..
        "Max Lua Memory: %s\nCurrent Global Memory: %s %s\n\n" ..
        "|c00FF00[Session Statistics]|r\nCleanups Triggered: %d\nMemory Freed: %s\n\n" ..
        "|cFFA500[Previous Session Statistics]|r\nCleanups Triggered: %d\nMemory Freed: %s\n\n" ..
        "|c00FFFF[Lifetime Statistics]|r\nTotal Cleanups: %d\nTotal Memory Freed: %s", 
        install_date, v_history_text, lib_text, lua_limit_txt, self:format_memory(current_mb), 
        mem_warning, self.session_cleanups, self:format_memory(self.session_mb_freed), 
        self.settings.prev_session_cleanups or 0, 
        self:format_memory(self.settings.prev_session_mb_freed or 0),
        self.settings.total_cleanups or 0, 
        self:format_memory(self.settings.total_mb_freed or 0)
    )
end

function AutoLuaCleaner:migrate_data()
    if self.settings then
        self.settings.pmOverridden = nil
        if not self.settings.is_migrated_007 then
            self.settings.show_ui = false
            self.settings.track_stats = false
            self.settings.is_log_enabled = false
            self.settings.is_migrated_007 = true
        end
    end
    if _G["AutoLuaCleaner"] then
        for world_name, world_data in pairs(_G["AutoLuaCleaner"]) do
            if type(world_data) == "table" then
                for account_name, account_data in pairs(world_data) do
                    if type(account_data) == "table" then
                        for profile_id, profile_data in pairs(account_data) do
                            if type(profile_data) == "table" then 
                                profile_data["pmOverridden"] = nil 
                            end
                        end
                    end
                end
            end
        end
    end
end

function AutoLuaCleaner:run_manual_cleanup()
    self.mem_state = 1
    zo_callLater(function()
        local before = collectgarbage("count") / 1024
        for i = 1, 2 do collectgarbage("collect") end
        local after = collectgarbage("count") / 1024
        local freed = before - after
        self.mem_state = 0
        
        if freed > 0.001 then
            self.session_cleanups = self.session_cleanups + 1
            self.session_mb_freed = self.session_mb_freed + freed
            
            if self.settings and self.settings.track_stats then
                self.settings.total_cleanups = (self.settings.total_cleanups or 0) + 1
                self.settings.total_mb_freed = (self.settings.total_mb_freed or 0) + freed
                self.settings.last_session_cleanups = self.session_cleanups
                self.settings.last_session_mb_freed = self.session_mb_freed
                
                local now = GetGameTimeMilliseconds()
                if (now - self.last_priority_save_time) >= 900000 then
                    GetAddOnManager():RequestAddOnSavedVariablesPrioritySave(AutoLuaCleaner.name)
                    self.last_priority_save_time = now
                end
            end
            
            local msg = string.format("Memory Freed %s", self:format_memory(freed))
            if self.settings.is_log_enabled and CHAT_SYSTEM then 
                CHAT_SYSTEM:AddMessage("|c00FFFF[ALC]|r " .. msg) 
            end
            self:safe_csa("|c00FFFF" .. msg .. "|r", 90)
        end
        
        if self.settings.show_ui then self:update_ui() end
    end, 500)
end

function AutoLuaCleaner:trigger_memory_check(check_type, delay)
    if not self.settings.is_enabled then return end
    if self.mem_state == 1 or self.is_mem_check_queued then return end
    
    local current_mb = self:get_hybrid_memory_data()
    local limit_threshold = IsConsoleUI() 
        and self.settings.threshold_console 
        or self.settings.threshold_pc

    if current_mb >= limit_threshold then
        local in_combat = IsUnitInCombat and IsUnitInCombat("player")
        if in_combat or IsUnitDead("player") then 
            if self.settings.show_ui then AutoLuaCleaner:update_ui() end
            return 
        end

        self.is_mem_check_queued = true
        zo_callLater(function()
            self.is_mem_check_queued = false
            if self.mem_state == 1 then return end
            
            local still_in_combat = IsUnitInCombat and IsUnitInCombat("player")
            if still_in_combat or IsUnitDead("player") then 
                if self.settings.show_ui then AutoLuaCleaner:update_ui() end
                return 
            end
            
            if check_type == "Menu" then
                local is_hud = SCENE_MANAGER:IsShowing("hud")
                local is_hudui = SCENE_MANAGER:IsShowing("hudui")
                local in_menu = SCENE_MANAGER and not (is_hud or is_hudui)
                if not in_menu then return end 
            end
            
            local recheck_mb = self:get_hybrid_memory_data()
            if recheck_mb >= limit_threshold then
                self:run_manual_cleanup()
                EVENT_MANAGER:UnregisterForUpdate(AutoLuaCleaner.name .. "_Fallback")
                EVENT_MANAGER:RegisterForUpdate(AutoLuaCleaner.name .. "_Fallback", 
                    self.settings.fallback_delay_sec * 1000, 
                    function() AutoLuaCleaner:trigger_memory_check("Fallback", 0) end
                )
            end
        end, delay)
    else
        EVENT_MANAGER:UnregisterForUpdate(AutoLuaCleaner.name .. "_Fallback")
        self.mem_state = 0
    end
end

function AutoLuaCleaner:save_session_history()
    if not self.settings.is_stats_log_enabled or session_peak_mb == 0 then return end
    
    local session_data = {
        date = GetDateStringFromTimestamp(GetTimeStamp()) .. " " .. GetTimeString(),
        has_peak = self.settings.session_track_peak, 
        has_avg = self.settings.session_track_avg,
        has_final = self.settings.session_track_final, 
        has_cleaned = self.settings.session_track_cleaned
    }
    
    if self.settings.session_track_peak then
        session_data.peak_mb = string.format("%.2f", session_peak_mb)
        session_data.peak_ping = stat_session_ping_max
        session_data.peak_fps_loss = stat_session_fps_loss_max
        session_data.peak_kb = stat_session_kb_max
    end
    
    if self.settings.session_track_avg then
        session_data.avg_ping = stat_session_ticks > 0 
            and math.floor(stat_session_ping_total / stat_session_ticks) or 0
        session_data.avg_kb = stat_session_ticks > 0 
            and math.floor(stat_session_kb_total / stat_session_ticks) or 0
        session_data.avg_fps_loss = stat_session_ticks > 0 
            and math.floor(stat_session_fps_loss_total / stat_session_ticks) or 0
        session_data.avg_current_mb = stat_session_ticks > 0 
            and (stat_session_current_mb_total / stat_session_ticks) or 0
    end
    
    if self.settings.session_track_final then
        local current_mb = self:get_hybrid_memory_data()
        session_data.final_mb = string.format("%.2f", current_mb)
        session_data.final_ping = stat_session_ping_final
        session_data.final_fps_loss = stat_session_fps_loss_final
        session_data.final_kb = stat_session_kb_final
    end
    
    if self.settings.session_track_cleaned then
        if self.settings.is_enabled then 
            session_data.mem_cleaned_str = self:format_memory(self.session_mb_freed or 0)
        else 
            session_data.mem_cleaned_str = "OFF" 
        end
    end
    
    table.insert(self.settings.session_history, session_data)
    if #self.settings.session_history > 50 then 
        table.remove(self.settings.session_history, 1) 
    end
end

function AutoLuaCleaner:format_history(entry)
    local lines = { string.format("|c00FFFF[%s]|r", entry.date or "?") }
    
    if entry.has_peak then
        table.insert(lines, string.format(
            "  |cFF0000Peak:|r %sMB | ms: %d | FPS Loss: %d | Gain: %dKB", 
            entry.peak_mb or "?", entry.peak_ping or 0, 
            entry.peak_fps_loss or 0, entry.peak_kb or 0
        ))
    end
    
    if entry.has_avg then
        table.insert(lines, string.format(
            "  |cFFA500Average:|r %sMB | ms: %d | FPS Loss: %d | Gain: %dKB", 
            string.format("%.2f", entry.avg_current_mb or 0), entry.avg_ping or 0, 
            entry.avg_fps_loss or 0, entry.avg_kb or 0
        ))
    end
    
    if entry.has_final then
        table.insert(lines, string.format(
            "  |cFFFFFFFinal:|r %sMB | ms: %d | FPS Loss: %d | Gain: %dKB", 
            entry.final_mb or "?", entry.final_ping or 0, 
            entry.final_fps_loss or 0, entry.final_kb or 0
        ))
    end
    
    if entry.has_cleaned then
        table.insert(lines, string.format("  |c00FFFFMemCleaned:|r %s", entry.mem_cleaned_str or "OFF"))
    end
    
    if not entry.has_peak and not entry.has_avg and not entry.has_final and not entry.has_cleaned then
        table.insert(lines, string.format("  |cFF0000Peak:|r %sMB", entry.peak or "?"))
    end
    
    return table.concat(lines, "\n")
end

function AutoLuaCleaner:update_history_text()
    if not history_label then return end
    local hist_txt = "|c00FFFF[Previous Sessions]|r\n"
    if #self.settings.session_history == 0 then 
        hist_txt = hist_txt .. "No data logged yet." 
    else
        local start_idx = math.max(1, #self.settings.session_history - 2)
        for i = start_idx, #self.settings.session_history do
            hist_txt = hist_txt .. self:format_history(self.settings.session_history[i]) .. "\n"
        end
    end
    history_label:SetText(hist_txt)
    
    if session_window then
        local text_w = history_label:GetTextWidth()
        local text_h = history_label:GetTextHeight()
        session_window:SetDimensions(text_w + 20, text_h + 15)
    end
end

function AutoLuaCleaner:update_session_anchor()
    if not session_window then return end
    session_window:ClearAnchors()
    if self.settings.session_ui_x and self.settings.session_ui_y then
        session_window:SetAnchor(
            TOPLEFT, GuiRoot, TOPLEFT, 
            self.settings.session_ui_x, self.settings.session_ui_y
        )
    else
        if graph_window and not graph_window:IsHidden() then 
            session_window:SetAnchor(TOPLEFT, graph_window, BOTTOMLEFT, 0, 15)
        else 
            session_window:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, 50, 400) 
        end
    end
end

function AutoLuaCleaner:build_session_ui()
    if not session_window then
        session_window = WINDOW_MANAGER:CreateControl("ALC_SessionUI", GuiRoot, CT_TOPLEVELCONTROL)
        session_window:SetDimensions(700, 250)
        session_window:SetClampedToScreen(true) 
        session_window:SetMouseEnabled(true)
        session_window:SetMovable(not self.settings.is_session_locked)
        
        session_window:SetHandler("OnMoveStop", function(ctrl)
            self.settings.session_ui_x = ctrl:GetLeft()
            self.settings.session_ui_y = ctrl:GetTop()
        end)
        
        local bg = WINDOW_MANAGER:CreateControl(nil, session_window, CT_BACKDROP)
        bg:SetAnchorFill(session_window)
        bg:SetCenterColor(0, 0, 0, 0.4)
        bg:SetEdgeColor(0, 0, 0, 0)
        
        local is_pad = IsInGamepadPreferredMode()
        local font_hist = is_pad and "ZoFontGamepad18" or "$(CHAT_FONT)|14|soft-shadow-thin"
        
        history_label = WINDOW_MANAGER:CreateControl(nil, session_window, CT_LABEL)
        history_label:SetFont(font_hist)
        history_label:SetColor(0.8, 0.8, 0.8, 1)
        history_label:SetAnchor(TOPLEFT, session_window, TOPLEFT, 5, 5)
        self.session_fragment = ZO_HUDFadeSceneFragment:New(session_window)
    end
    self:update_session_anchor()
    
    if session_window then
        session_window:SetHidden(not self.settings.show_session_ui)
        if self.settings.show_session_ui then self:update_history_text() end
    end
end

function AutoLuaCleaner:update_ui_anchor()
    if not self.ui_window then return end
    self.ui_window:ClearAnchors()
    if self.settings.ui_x and self.settings.ui_y then
        self.ui_window:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, self.settings.ui_x, self.settings.ui_y)
    else
        if ZO_CompassFrame then 
            self.ui_window:SetAnchor(RIGHT, ZO_CompassFrame, LEFT, -40, 0)
        else 
            self.ui_window:SetAnchor(TOP, GuiRoot, TOP, -300, 40) 
        end
    end
    self.ui_window:SetDimensions(150, 40)
    
    if self.ui_label then
        local show_bar = self.settings.show_mem_ui_bar
        if show_bar and not self.percent_bar then
            local pct_bg = WINDOW_MANAGER:CreateControl("ALC_PercentBG", self.ui_label, CT_BACKDROP)
            pct_bg:SetDimensions(130, 8)
            pct_bg:SetAnchor(TOP, self.ui_label, BOTTOM, 0, 5)
            pct_bg:SetCenterColor(0, 0, 0, 0.4)
            pct_bg:SetEdgeColor(0, 0, 0, 1)
            self.percent_bg = pct_bg
            
            local pct_bar = WINDOW_MANAGER:CreateControl("ALC_PercentBar", pct_bg, CT_TEXTURE)
            pct_bar:SetAnchor(LEFT, pct_bg, LEFT, 0, 0)
            pct_bar:SetDimensions(0, 8)
            self.percent_bar = pct_bar
        end
        if self.percent_bg then self.percent_bg:SetHidden(not show_bar) end
        if self.percent_bar then self.percent_bar:SetHidden(not show_bar) end
    end
end

function AutoLuaCleaner:update_ui()
    if not self.settings.show_ui then return end
    
    local current_mb = self:get_hybrid_memory_data()
    local limit = IsConsoleUI() and self.settings.threshold_console or self.settings.threshold_pc
    local pct = math.min((current_mb / limit) * 100, 100)
    local r, g, b = 0, 1, 0
    local status_color = "|c00FF00"
    
    if pct >= 90 then 
        r, g, b = 1, 0, 0
        status_color = "|cFF0000"
    elseif pct >= 75 then 
        r, g, b = 1, 0.5, 0
        status_color = "|cFFA500" 
    end
    
    local t_str = IsUnitInCombat("player") and "|cFF0000[ALC] (Combat)|r" or "|c00FFFF[ALC]|r"
    local m_str = self:format_memory(current_mb)
    self.ui_label:SetText(string.format("%s Memory: %s%s|r", t_str, status_color, m_str))
    
    if self.percent_bar then
        self.percent_bar:SetDimensions(130 * (pct / 100), 8)
        self.percent_bar:SetColor(r, g, b, 1)
    end
    self.ui_window:SetDimensions(self.ui_label:GetTextWidth() + 20, 40)
end

function AutoLuaCleaner:create_ui()
    local win = WINDOW_MANAGER:CreateControl("AutoLuaCleanerUI", GuiRoot, CT_TOPLEVELCONTROL)
    win:SetClampedToScreen(true)
    win:SetMouseEnabled(true)
    win:SetMovable(not self.settings.is_ui_locked)
    win:SetHidden(true) 
    self.ui_window = win
    self:update_ui_anchor()
    
    win:SetHandler("OnMoveStop", function(ctrl) 
        AutoLuaCleaner.settings.ui_x = ctrl:GetLeft()
        AutoLuaCleaner.settings.ui_y = ctrl:GetTop()
    end)
    
    local bg_tex = WINDOW_MANAGER:CreateControl("AutoLuaCleanerBG", win, CT_BACKDROP)
    bg_tex:SetAnchor(TOPLEFT, win, TOPLEFT, 0, 0)
    bg_tex:SetAnchor(BOTTOMRIGHT, win, BOTTOMRIGHT, 0, 0)
    bg_tex:SetCenterColor(0, 0, 0, 0.6)
    bg_tex:SetEdgeColor(0.6, 0.6, 0.6, 0.8)
    bg_tex:SetEdgeTexture(nil, 1, 1, 1, 0)
    
    local is_pad = IsInGamepadPreferredMode()
    local font_main = is_pad and "ZoFontGamepad22" or "ZoFontGameSmall"
    
    local text_lbl = WINDOW_MANAGER:CreateControl("AutoLuaCleanerLabel", win, CT_LABEL)
    text_lbl:SetFont(font_main)
    text_lbl:SetColor(1, 1, 1, 1)
    text_lbl:SetText("[ALC] Loading...")
    text_lbl:SetAnchor(CENTER, win, CENTER, 0, 0)
    self.ui_label = text_lbl
    
    self.ui_update_fn = function(ctrl, frame_time)
        if not AutoLuaCleaner.settings.show_ui then return end
        if frame_time - AutoLuaCleaner.last_ui_update < 1.0 then return end
        AutoLuaCleaner.last_ui_update = frame_time
        AutoLuaCleaner:update_ui()
    end
    self.hud_fragment = ZO_HUDFadeSceneFragment:New(win)
end

function AutoLuaCleaner:update_ui_scenes()
    if not self.hud_fragment then return end
    local valid_scenes = {"hud", "hudui", "gamepad_hud"}
    
    if self.graph_fragment then
        for _, s_name in ipairs(valid_scenes) do
            local scene = SCENE_MANAGER:GetScene(s_name)
            if scene then scene:RemoveFragment(self.graph_fragment) end
        end
    end
    
    if self.session_fragment then
        for _, s_name in ipairs(valid_scenes) do
            local scene = SCENE_MANAGER:GetScene(s_name)
            if scene then scene:RemoveFragment(self.session_fragment) end
        end
    end
    
    for _, s_name in ipairs(valid_scenes) do
        local hud_scene = SCENE_MANAGER:GetScene(s_name)
        if hud_scene then
            if self.settings.show_ui then 
                hud_scene:AddFragment(self.hud_fragment) 
            else 
                hud_scene:RemoveFragment(self.hud_fragment) 
            end
            
            if self.graph_fragment and self.settings.is_graph_enabled and self.settings.show_ui then
                if not self.settings.is_graph_global then 
                    hud_scene:AddFragment(self.graph_fragment) 
                end
            end
            
            if self.session_fragment and self.settings.show_session_ui then
                hud_scene:AddFragment(self.session_fragment)
            end
        end
    end
    
    if graph_window then
        if self.settings.is_graph_enabled and self.settings.show_ui then
            if self.settings.is_graph_global then graph_window:SetHidden(false) end
        else 
            graph_window:SetHidden(true) 
        end
    end
end

function AutoLuaCleaner:build_graph_ui()
    if not graph_window then
        graph_window = WINDOW_MANAGER:CreateControl("ALC_GraphUI", GuiRoot, CT_TOPLEVELCONTROL)
        graph_window:SetDimensions(360, 230)
        graph_window:SetClampedToScreen(true)
        graph_window:SetMouseEnabled(true)
        graph_window:SetMovable(not self.settings.is_graph_locked)
        graph_window:SetDrawLayer(DL_OVERLAY)
        graph_window:SetAnchor(TOPLEFT, self.ui_window, BOTTOMLEFT, 0, 5) 
        
        graph_window:SetHandler("OnMoveStop", function(ctrl)
            self.settings.graph_x = ctrl:GetLeft()
            self.settings.graph_y = ctrl:GetTop()
            self.settings.is_graph_detached = true
        end)
        
        local bg = WINDOW_MANAGER:CreateControl(nil, graph_window, CT_BACKDROP)
        bg:SetAnchor(TOPLEFT, graph_window, TOPLEFT, 60, 0)
        bg:SetAnchor(BOTTOMRIGHT, graph_window, TOPLEFT, 300, 180)
        bg:SetCenterColor(0, 0, 0, 0.4)
        bg:SetEdgeColor(0, 0, 0, 0)
        self.graph_bg = bg
        
        local is_pad = IsInGamepadPreferredMode()
        local font_lbl = is_pad and "ZoFontGamepad18" or "$(CHAT_FONT)|14|soft-shadow-thin"
        local font_diag = is_pad and "ZoFontGamepad18" or "$(CHAT_FONT)|12|soft-shadow-thin"
        
        self.graph_data = self.graph_data or {} 
        local col_w = 240 / max_points
        local max_rows = 36
        local row_h = 180 / max_rows 
        
        for i = 1, max_points do
            graph_segments[i] = {}
            for j = 1, max_rows do
                local seg = WINDOW_MANAGER:CreateControl(nil, graph_window, CT_TEXTURE)
                seg:SetAnchor(BOTTOMLEFT, bg, BOTTOMLEFT, (i - 1) * col_w, (j - 1) * row_h * -1)
                seg:SetDimensions(col_w - 1, row_h - 1)
                seg:SetHidden(true)
                table.insert(graph_segments[i], seg)
            end
            graph_latency_dots[i] = WINDOW_MANAGER:CreateControl(nil, graph_window, CT_TEXTURE)
            graph_latency_dots[i]:SetDimensions(3, 3)
            graph_latency_dots[i]:SetHidden(true)
        end
        
        graph_grid_lines = {}
        graph_grid_lines_v = {}
        graph_labels = {}
        graph_labels_lat = {}
        
        for i = 1, 12 do
            local gl = WINDOW_MANAGER:CreateControl(nil, graph_window, CT_LINE)
            gl:SetThickness(1); gl:SetColor(1, 1, 1, 0.15); gl:SetHidden(true)
            gl:SetAnchor(LEFT, bg, TOPLEFT, 0, (i-1)*(180/12))
            gl:SetAnchor(RIGHT, bg, TOPLEFT, 240, (i-1)*(180/12))
            table.insert(graph_grid_lines, gl)
            
            local l = WINDOW_MANAGER:CreateControl(nil, graph_window, CT_LABEL)
            l:SetFont(font_lbl); l:SetDimensions(55, 20)
            l:SetHorizontalAlignment(TEXT_ALIGN_LEFT); l:SetHidden(true)
            table.insert(graph_labels, l)
            
            local lat_l = WINDOW_MANAGER:CreateControl(nil, graph_window, CT_LABEL)
            lat_l:SetFont(font_lbl); lat_l:SetDimensions(55, 20)
            lat_l:SetHorizontalAlignment(TEXT_ALIGN_RIGHT)
            lat_l:SetColor(1, 0.65, 0, 1); lat_l:SetHidden(true)
            table.insert(graph_labels_lat, lat_l)
        end
        for i = 1, 6 do
            local glv = WINDOW_MANAGER:CreateControl(nil, graph_window, CT_LINE)
            glv:SetThickness(1); glv:SetColor(1, 1, 1, 0.15)
            glv:SetAnchor(TOPLEFT, bg, TOPLEFT, (i-1)*48, 0)
            glv:SetAnchor(BOTTOMRIGHT, bg, BOTTOMLEFT, (i-1)*48, 0)
            table.insert(graph_grid_lines_v, glv)
            
            local l = WINDOW_MANAGER:CreateControl(nil, graph_window, CT_LABEL)
            l:SetFont(font_lbl); l:SetDimensions(30, 20)
            l:SetHorizontalAlignment(TEXT_ALIGN_CENTER)
            l:SetAnchor(TOP, bg, BOTTOMLEFT, (i-1)*48, 2)
            table.insert(graph_labels_x, l)
        end
        
        local diag_win = WINDOW_MANAGER:CreateControl(nil, graph_window, CT_CONTROL)
        diag_win:SetDimensions(100, 140)
        self.diag_win = diag_win 
        
        local function make_lbl(name, y_off, text)
            local l = WINDOW_MANAGER:CreateControl(name, diag_win, CT_LABEL)
            l:SetFont(font_diag)
            l:SetAnchor(TOPLEFT, diag_win, TOPLEFT, 0, y_off)
            l:SetText(text)
            return l
        end
        
        diag_labels.pct = make_lbl("ALC_GraphPct", 0, "Total")
        diag_labels.fps = make_lbl("ALC_GraphFps", 14, "FPS")
        diag_labels.fps_drop = make_lbl("ALC_GraphFpsDrop", 28, "FPS Loss")
        diag_labels.ms = make_lbl("ALC_GraphMs", 42, "ms")
        diag_labels.avg_ms = make_lbl("ALC_GraphAvgMs", 56, "Avg ms")
        diag_labels.spike_pct = make_lbl("ALC_GraphSpikePct", 70, "Spike")
        diag_labels.kb = make_lbl("ALC_GraphKb", 84, "|cFF00FFAvg KB|r")
        diag_labels.mb = make_lbl("ALC_GraphMb", 98, "|cFFFFFFAvg MB|r")
        self.graph_fragment = ZO_HUDFadeSceneFragment:New(graph_window)
    end
    
    local is_lite = self.settings.lite_mode
    local is_diagnostics_on = self.settings.show_graph_diags
    
    if self.diag_win then
        self.diag_win:ClearAnchors()
        if is_lite then 
            self.diag_win:SetAnchor(TOPLEFT, graph_window, TOPLEFT, 65, 5) 
        else 
            self.diag_win:SetAnchor(TOPLEFT, self.graph_bg, TOPLEFT, 5, 15) 
        end
        self.diag_win:SetHidden(not is_diagnostics_on)
    end
    
    if self.graph_bg then self.graph_bg:SetHidden(is_lite) end
    if is_lite then
        for _, seg in ipairs(graph_segments) do 
            for _, s in ipairs(seg) do s:SetHidden(true) end 
        end
        for _, dt in ipairs(graph_latency_dots) do dt:SetHidden(true) end
        for _, gl in ipairs(graph_grid_lines) do gl:SetHidden(true) end
        for _, glv in ipairs(graph_grid_lines_v) do glv:SetHidden(true) end
        for _, l in ipairs(graph_labels) do l:SetHidden(true) end
        for _, l in ipairs(graph_labels_lat) do l:SetHidden(true) end
        for _, l in ipairs(graph_labels_x) do l:SetHidden(true) end
    end
    self:update_session_anchor()
end

function AutoLuaCleaner:show_missing_library_warning()
    local dialog_id = "ALC_MISSING_LIBRARY_WARN"
    local popup_title = "|cFF0000Auto Lua Memory Cleaner - Missing Dependency|r"
    local popup_body = "To configure Auto Lua Memory Cleaner via Settings UI, you MUST install " ..
                       "the required library.\n\nPlease install:\n|c00FFFFLibAddonMenu-2.0|r"
                       
    local function on_ack()
        AutoLuaCleaner.settings.has_shown_lib_warning_007 = true
        local tick_ms = GetGameTimeMilliseconds()
        if (tick_ms - AutoLuaCleaner.last_priority_save_time) >= 900000 then
            GetAddOnManager():RequestAddOnSavedVariablesPrioritySave(AutoLuaCleaner.name)
            AutoLuaCleaner.last_priority_save_time = tick_ms
        end
    end

    if not ESO_Dialogs[dialog_id] then
        ESO_Dialogs[dialog_id] = {
            canQueue = true, 
            gamepadInfo = { dialogType = GAMEPAD_DIALOGS.BASIC }, 
            title = { text = popup_title }, 
            mainText = { text = popup_body },
            buttons = { { text = "Acknowledge / Close", keybind = "DIALOG_PRIMARY", callback = on_ack } }
        }
    end

    zo_callLater(function()
        if IsInGamepadPreferredMode() then 
            ZO_Dialogs_ShowGamepadDialog(dialog_id) 
        else 
            ZO_Dialogs_ShowDialog(dialog_id) 
        end
    end, 2000)

    if CHAT_SYSTEM then 
        CHAT_SYSTEM:AddMessage("|cFF0000[ALC Setup Warning]|r Please install LibAddonMenu-2.0.") 
    end
end

function AutoLuaCleaner:build_lam2_menu()
    local lib_type, lam_ver = self:get_settings_library()
    if lib_type == "NONE" then return end

    if lib_type == "LAM2" and lam_ver > 0 and lam_ver < REQUIRED_LAM_VERSION then
        zo_callLater(function()
            local warn_msg = string.format(
                "|cFFFF00Warning: LibAddonMenu is outdated (v%d). Update to v%d+ for ALC.|r", 
                lam_ver, REQUIRED_LAM_VERSION
            )
            if CHAT_SYSTEM then CHAT_SYSTEM:AddMessage("|cFF0000[ALC]|r " .. warn_msg) end
            AutoLuaCleaner:safe_csa(warn_msg)
        end, 4000)
        return
    end

    local c_cmds = {
        "|c00FFFF/alcon|r |cFFD700- Toggle Auto Cleanup|r\n\n",
        "|c00FFFF/alcui|r |cFFD700- Toggle Memory UI|r\n\n",
        "|c00FFFF/alclock|r |cFFD700- Lock/Unlock UI|r\n\n",
        "|c00FFFF/alcreset|r |cFFD700- Reset UI position|r\n\n",
        "|c00FFFF/alcbar|r |cFFD700- Toggle Memory UI Bar|r\n\n",
        "|c00FFFF/alcgraph|r |cFFD700- Toggle Memory Graph|r\n\n",
        "|c00FFFF/alcgraphlock|r |cFFD700- Lock/Unlock Graph|r\n\n",
        "|c00FFFF/alcgraphreset|r |cFFD700- Reset Graph position|r\n\n",
        "|c00FFFF/alclite|r |cFFD700- Toggle Lite Mode|r\n\n",
        "|c00FFFF/alcdiags|r |cFFD700- Toggle Graph Diagnostics|r\n\n",
        "|c00FFFF/alcsession|r |cFFD700- Toggle Session UI|r\n\n",
        "|c00FFFF/alcsessionlock|r |cFFD700- Lock Session UI|r\n\n",
        "|c00FFFF/alcsessionreset|r |cFFD700- Reset Session UI|r\n\n",
        "|c00FFFF/alccsa|r |cFFD700- Toggle Announcements|r\n\n",
        "|c00FFFF/alcstats|r |cFFD700- Toggle Saving Statistics|r\n\n",
        "|c00FFFF/alcclean|r |cFFD700- Force manual Lua cleanup|r"
    }
    
    local pc_cmds = {
        "|c00FFFF/alcon|r |cFFD700- Toggle Auto Cleanup|r\n",
        "|c00FFFF/alcui|r |cFFD700- Toggle Memory UI|r\n",
        "|c00FFFF/alclock|r |cFFD700- Lock/Unlock UI|r\n",
        "|c00FFFF/alcreset|r |cFFD700- Reset UI position|r\n",
        "|c00FFFF/alcbar|r |cFFD700- Toggle Memory UI Bar|r\n",
        "|c00FFFF/alcgraph|r |cFFD700- Toggle Memory Graph|r\n",
        "|c00FFFF/alcgraphlock|r |cFFD700- Lock/Unlock Graph|r\n",
        "|c00FFFF/alcgraphreset|r |cFFD700- Reset Graph position|r\n",
        "|c00FFFF/alclite|r |cFFD700- Toggle Lite Mode|r\n",
        "|c00FFFF/alcdiags|r |cFFD700- Toggle Graph Diagnostics|r\n",
        "|c00FFFF/alcfps|r |cFFD700- Toggle FPS Tracking|r\n",
        "|c00FFFF/alcping|r |cFFD700- Toggle Latency Tracking|r\n",
        "|c00FFFF/alcgains|r |cFFD700- Toggle KB/MB Tracking|r\n",
        "|c00FFFF/alcsession|r |cFFD700- Toggle Session UI|r\n",
        "|c00FFFF/alcsessionlock|r |cFFD700- Lock Session UI|r\n",
        "|c00FFFF/alcsessionreset|r |cFFD700- Reset Session UI|r\n",
        "|c00FFFF/alcstatpeak|r |cFFD700- Toggle Session Peak Logs|r\n",
        "|c00FFFF/alcstatavg|r |cFFD700- Toggle Session Avg Logs|r\n",
        "|c00FFFF/alcstatfinal|r |cFFD700- Toggle Session Final Logs|r\n",
        "|c00FFFF/alcstatclean|r |cFFD700- Toggle Session Clean Logs|r\n",
        "|c00FFFF/alccsa|r |cFFD700- Toggle Announcements|r\n",
        "|c00FFFF/alclogs|r |cFFD700- Toggle Chat Logs|r\n",
        "|c00FFFF/alcstats|r |cFFD700- Toggle Saving Statistics|r\n",
        "|c00FFFF/alcclean|r |cFFD700- Force manual Lua cleanup|r"
    }

    local is_eu_server = (GetWorldName() == "EU Megaserver")
    local is_pad = IsConsoleUI() or IsInGamepadPreferredMode()
    local lib_lam = LibAddonMenu2 or _G["LibAddonMenu2"]
    if not lib_lam then return end
    
    local menu_header = { 
        type = "panel", 
        name = "|c9CD04CAuto Lua Memory Cleaner|r", 
        displayName = "|c00FFFFAuto Lua Memory Cleaner|r", 
        author = "@|ca500f3A|r|cb400e6P|r|cc300daH|r|cd200cdO|r|ce100c1NlC|r", 
        version = self.version, 
        registerForRefresh = true 
    }
    
    local build_data = {}
    
    if is_pad then
        table.insert(build_data, { 
            type = "button", 
            name = "|c00FF00ALC LIVE STATS|r", 
            tooltip = function() return AutoLuaCleaner:get_stats_text() end, 
            func = function() end, 
            width = "full" 
        })
        table.insert(build_data, { 
            type = "button", 
            name = "|c00FF00COMMANDS INFO|r", 
            tooltip = table.concat(c_cmds), 
            func = function() end, 
            width = "full" 
        })
    end
    
    if not is_pad and not is_eu_server then
        table.insert(build_data, { 
            type = "button", 
            name = "|cFFD700DONATE|r to @|ca500f3A|r|cb400e6P|r|cc300daH|r|cd200cdO|r|ce100c1NlC|r", 
            tooltip = "Opens the in-game mail. Thank you!", 
            func = function() 
                SCENE_MANAGER:Show("mailSend")
                zo_callLater(function() 
                    ZO_MailSendToField:SetText("@APHONlC")
                    ZO_MailSendSubjectField:SetText("Auto Lua Cleaner Support")
                    ZO_MailSendBodyField:TakeFocus() 
                end, 200) 
            end, 
            width = "full" 
        })
        table.insert(build_data, { type = "divider" })
    end
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Enable Auto Cleanup", 
        getFunc = function() return AutoLuaCleaner.settings.is_enabled end, 
        setFunc = function(v) 
            AutoLuaCleaner.settings.is_enabled = v
            AutoLuaCleaner:toggle_core_events() 
        end 
    })

    if IsConsoleUI() then 
        table.insert(build_data, { 
            type = "slider", 
            name = "Console Memory Threshold (MB)", 
            min = 5, max = 95, step = 1, 
            getFunc = function() return AutoLuaCleaner.settings.threshold_console end, 
            setFunc = function(v) AutoLuaCleaner.settings.threshold_console = v end 
        })
    else 
        table.insert(build_data, { 
            type = "slider", 
            name = "PC Memory Threshold (MB)", 
            min = 50, max = 800, step = 1, 
            getFunc = function() return AutoLuaCleaner.settings.threshold_pc end, 
            setFunc = function(v) AutoLuaCleaner.settings.threshold_pc = v end 
        }) 
    end

    table.insert(build_data, { 
        type = "slider", 
        name = "Repeat Cleanup Delay (Seconds)", 
        min = 30, max = 1200, step = 10, 
        getFunc = function() return AutoLuaCleaner.settings.fallback_delay_sec end, 
        setFunc = function(v) AutoLuaCleaner.settings.fallback_delay_sec = v end 
    })
    
    table.insert(build_data, { type = "divider" })
    
    if not is_pad then 
        table.insert(build_data, { 
            type = "checkbox", 
            name = "Enable Chat Logs", 
            getFunc = function() return AutoLuaCleaner.settings.is_log_enabled end, 
            setFunc = function(v) AutoLuaCleaner.settings.is_log_enabled = v end 
        }) 
    end
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Track Statistics", 
        getFunc = function() return AutoLuaCleaner.settings.track_stats end, 
        setFunc = function(v) 
            AutoLuaCleaner.settings.track_stats = v
            AutoLuaCleaner:refresh_stats_tracker()
            local s_ctrl = _G["ALC_StatsText"]
            if s_ctrl and s_ctrl.desc then s_ctrl.desc:SetText(AutoLuaCleaner:get_stats_text()) end 
        end 
    })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Screen Announcements", 
        getFunc = function() return AutoLuaCleaner.settings.is_csa_enabled end, 
        setFunc = function(v) AutoLuaCleaner.settings.is_csa_enabled = v end 
    })
    
    table.insert(build_data, { type = "divider" })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Show Memory UI", 
        getFunc = function() return AutoLuaCleaner.settings.show_ui end, 
        setFunc = function(v) 
            AutoLuaCleaner.settings.show_ui = v
            AutoLuaCleaner:toggle_ui_update() 
        end 
    })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Lock UI Position", 
        getFunc = function() return AutoLuaCleaner.settings.is_ui_locked end, 
        setFunc = function(v) 
            AutoLuaCleaner.settings.is_ui_locked = v
            if AutoLuaCleaner.ui_window then AutoLuaCleaner.ui_window:SetMovable(not v) end 
        end, 
        disabled = function() return not AutoLuaCleaner.settings.show_ui end 
    })
    
    table.insert(build_data, { 
        type = "button", 
        name = "|cFF0000RESET UI POSITION|r", 
        func = function() 
            AutoLuaCleaner.settings.ui_x = nil
            AutoLuaCleaner.settings.ui_y = nil
            AutoLuaCleaner:update_ui_anchor()
            if AutoLuaCleaner.settings.is_log_enabled and CHAT_SYSTEM then 
                CHAT_SYSTEM:AddMessage("|c00FFFF[ALC]|r UI Position Reset.") 
            end 
        end, 
        disabled = function() return not AutoLuaCleaner.settings.show_ui end 
    })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Enable Memory Graph", 
        getFunc = function() return AutoLuaCleaner.settings.is_graph_enabled end, 
        setFunc = function(v) 
            AutoLuaCleaner.settings.is_graph_enabled = v
            AutoLuaCleaner:toggle_ui_update() 
        end, 
        disabled = function() return not AutoLuaCleaner.settings.show_ui end 
    })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Log Session History", 
        getFunc = function() return AutoLuaCleaner.settings.is_stats_log_enabled end, 
        setFunc = function(v) 
            AutoLuaCleaner.settings.is_stats_log_enabled = v
            if v then 
                EVENT_MANAGER:RegisterForUpdate("ALC_StatsTick", 60000, function() 
                    AutoLuaCleaner:check_session_peak() 
                end) 
            else 
                EVENT_MANAGER:UnregisterForUpdate("ALC_StatsTick") 
            end 
        end 
    })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Render Graph in Menus", 
        getFunc = function() return AutoLuaCleaner.settings.is_graph_global end, 
        setFunc = function(v) 
            AutoLuaCleaner.settings.is_graph_global = v
            AutoLuaCleaner:update_ui_scenes() 
        end, 
        disabled = function() return not AutoLuaCleaner.settings.is_graph_enabled end 
    })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Lock Graph Position", 
        getFunc = function() return AutoLuaCleaner.settings.is_graph_locked end, 
        setFunc = function(v) 
            AutoLuaCleaner.settings.is_graph_locked = v
            if graph_window then graph_window:SetMovable(not v) end 
        end, 
        disabled = function() return not AutoLuaCleaner.settings.is_graph_enabled end 
    })
    
    table.insert(build_data, { 
        type = "button", 
        name = "|cFF0000RESET GRAPH POSITION|r", 
        func = function() 
            AutoLuaCleaner.settings.graph_x = nil
            AutoLuaCleaner.settings.graph_y = nil
            AutoLuaCleaner.settings.is_graph_detached = false
            if graph_window and AutoLuaCleaner.ui_window then 
                graph_window:ClearAnchors()
                graph_window:SetAnchor(TOPLEFT, AutoLuaCleaner.ui_window, BOTTOMLEFT, 0, 5) 
            end
            if CHAT_SYSTEM then 
                CHAT_SYSTEM:AddMessage("|c00FFFF[ALC]|r Graph Position Reset.") 
            end 
        end, 
        disabled = function() return not AutoLuaCleaner.settings.is_graph_enabled end 
    })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Show Diagnostics Text", 
        getFunc = function() return AutoLuaCleaner.settings.show_graph_diags end, 
        setFunc = function(v) 
            AutoLuaCleaner.settings.show_graph_diags = v
            AutoLuaCleaner:build_graph_ui() 
        end, 
        disabled = function() return not AutoLuaCleaner.settings.is_graph_enabled end 
    })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Enable [Lite Mode] (Diagnostics-Only)", 
        getFunc = function() return AutoLuaCleaner.settings.lite_mode end, 
        setFunc = function(v) 
            AutoLuaCleaner.settings.lite_mode = v
            AutoLuaCleaner:build_graph_ui() 
        end, 
        disabled = function() return not AutoLuaCleaner.settings.is_graph_enabled end 
    })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Show UI Percentage Bar", 
        getFunc = function() return AutoLuaCleaner.settings.show_mem_ui_bar end, 
        setFunc = function(v) 
            AutoLuaCleaner.settings.show_mem_ui_bar = v
            AutoLuaCleaner:update_ui_anchor() 
        end, 
        disabled = function() return not AutoLuaCleaner.settings.show_ui end 
    })
    
    table.insert(build_data, { type = "divider" })
    table.insert(build_data, { type = "header", name = "|c00FFFFPrevious Session Tracker|r" })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Show Session History UI", 
        getFunc = function() return AutoLuaCleaner.settings.show_session_ui end, 
        setFunc = function(v) 
            AutoLuaCleaner.settings.show_session_ui = v
            AutoLuaCleaner:build_session_ui() 
        end 
    })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Lock Session UI Position", 
        getFunc = function() return AutoLuaCleaner.settings.is_session_locked end, 
        setFunc = function(v) 
            AutoLuaCleaner.settings.is_session_locked = v
            if session_window then session_window:SetMovable(not v) end 
        end, 
        disabled = function() return not AutoLuaCleaner.settings.show_session_ui end 
    })
    
    table.insert(build_data, { 
        type = "button", 
        name = "|cFF0000RESET SESSION UI|r", 
        func = function() 
            AutoLuaCleaner.settings.session_ui_x = nil
            AutoLuaCleaner.settings.session_ui_y = nil
            AutoLuaCleaner:update_session_anchor() 
        end, 
        disabled = function() return not AutoLuaCleaner.settings.show_session_ui end 
    })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Log Session PEAK Data", 
        tooltip = "Logs the highest spike recorded during your session.", 
        getFunc = function() return AutoLuaCleaner.settings.session_track_peak end, 
        setFunc = function(v) AutoLuaCleaner.settings.session_track_peak = v end 
    })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Log Session AVERAGE Data", 
        tooltip = "Logs the math average for your session.", 
        getFunc = function() return AutoLuaCleaner.settings.session_track_avg end, 
        setFunc = function(v) AutoLuaCleaner.settings.session_track_avg = v end 
    })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Log Session FINAL Data", 
        tooltip = "Logs the exact numbers seen right before you reloaded/logged out.", 
        getFunc = function() return AutoLuaCleaner.settings.session_track_final end, 
        setFunc = function(v) AutoLuaCleaner.settings.session_track_final = v end 
    })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Track MemCleaned (Session UI Only)", 
        tooltip = "Logs how much RAM was saved by the addon during the session.", 
        getFunc = function() return AutoLuaCleaner.settings.session_track_cleaned end, 
        setFunc = function(v) AutoLuaCleaner.settings.session_track_cleaned = v end 
    })
    
    table.insert(build_data, { type = "divider" })
    table.insert(build_data, { type = "header", name = "|c00FFFFPerformance Dormancy Toggles|r" })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Track Framerate (FPS & Loss)", 
        getFunc = function() return AutoLuaCleaner.settings.track_fps end, 
        setFunc = function(v) 
            AutoLuaCleaner.settings.track_fps = v
            stat_baseline_fps, stat_fps_stable_ticks, stat_last_fps_raw = 0, 0, 0
            AutoLuaCleaner:build_graph_ui() 
        end 
    })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Track Latency (Ping, Spikes, Left-Axis ms)", 
        getFunc = function() return AutoLuaCleaner.settings.track_ping end, 
        setFunc = function(v) 
            AutoLuaCleaner.settings.track_ping = v
            stat_ticks, stat_total_ping = 0, 0
            stat_baseline_ping, stat_ping_stable_ticks, stat_last_ping_raw = 0, 0, 0
            graph_latency_pool = {}
            AutoLuaCleaner:build_graph_ui() 
        end 
    })
    
    table.insert(build_data, { 
        type = "checkbox", 
        name = "Track Memory Gains (Avg KB/MB)", 
        getFunc = function() return AutoLuaCleaner.settings.track_memory_gains end, 
        setFunc = function(v) 
            AutoLuaCleaner.settings.track_memory_gains = v
            AutoLuaCleaner:build_graph_ui() 
        end 
    })
    
    table.insert(build_data, { type = "divider" })
    
    table.insert(build_data, { 
        type = "button", 
        name = "|c00FFFFFORCE MANUAL CLEANUP|r", 
        func = function() AutoLuaCleaner:run_manual_cleanup() end, 
        width = "full" 
    })
    
    if not is_pad then
        local live_stats = { 
            type = "submenu", 
            name = "ALC Live Statistics", 
            controls = { 
                { 
                    type = "description", 
                    title = "|c00FFFFLive Statistics|r", 
                    text = "Statistics Tracking is Disabled...", 
                    reference = "ALC_StatsText" 
                } 
            } 
        }
        table.insert(build_data, live_stats)
        table.insert(build_data, { 
            type = "description", 
            title = "Commands Info", 
            text = table.concat(pc_cmds) 
        })
    end
    
    table.insert(build_data, { type = "divider" })
    
    if is_pad then
        table.insert(build_data, { 
            type = "button", 
            name = "|cFFD700Buy Me A Coffee|r", 
            tooltip = "Link: https://buymeacoffee.com/aph0nlc", 
            func = function() end, 
            width = "full" 
        })
        table.insert(build_data, { 
            type = "button", 
            name = "|cFF0000BUG REPORT|r", 
            tooltip = "Link: https://www.esoui.com/portal.php?id=360&a=listbugs", 
            func = function() end, 
            width = "full" 
        })
    else
        table.insert(build_data, { 
            type = "button", 
            name = "|cFFD700Buy Me A Coffee|r", 
            func = function() RequestOpenUnsafeURL("https://buymeacoffee.com/aph0nlc") end, 
            width = "full" 
        })
        table.insert(build_data, { 
            type = "button", 
            name = "|cFF0000BUG REPORT|r", 
            func = function() RequestOpenUnsafeURL("https://www.esoui.com/portal.php?id=360&a=listbugs") end, 
            width = "full" 
        })
    end

    lib_lam:RegisterAddonPanel("AutoLuaCleanerOptions", menu_header)
    lib_lam:RegisterOptionControls("AutoLuaCleanerOptions", build_data)
end

function AutoLuaCleaner:integrate_with_perm_memento()
    local pm_core = _G["PermMementoCore"]
    if pm_core and type(pm_core) == "table" and pm_core.settings then
        pm_core.settings.is_auto_cleanup = false
        pm_core.settings.is_csa_cleanup_enabled = false
        EVENT_MANAGER:UnregisterForUpdate(pm_core.name .. "_MemFallback")
    end
end

function AutoLuaCleaner:init(event_code, addon_name)
    if addon_name ~= self.name then return end
    EVENT_MANAGER:UnregisterForEvent(self.name, EVENT_ADD_ON_LOADED)
    
    local active_world = GetWorldName() or "Default"
    self.settings = ZO_SavedVars:NewAccountWide(
        "AutoLuaCleaner", 1, "AccountWide", self.defaults, active_world
    )
    self:migrate_data()

    local found_lib, found_ver = self:get_settings_library()
    if found_lib == "NONE" and not self.settings.has_shown_lib_warning_007 then 
        self:show_missing_library_warning() 
    end
    if found_lib == "NONE" or (found_lib == "LAM2" and found_ver < REQUIRED_LAM_VERSION) then 
        self.settings.track_stats = false 
    end

    self.settings.prev_session_cleanups = self.settings.last_session_cleanups or 0
    self.settings.prev_session_mb_freed = self.settings.last_session_mb_freed or 0
    self.settings.last_session_cleanups = 0
    self.settings.last_session_mb_freed = 0
    
    if not self.settings.install_date then
        local raw_d = GetDate()
        if raw_d and type(raw_d) == "number" then raw_d = tostring(raw_d) end
        if raw_d and string.len(raw_d) == 8 then 
            self.settings.install_date = string.sub(raw_d, 1, 4) .. "/" .. 
                string.sub(raw_d, 5, 6) .. "/" .. string.sub(raw_d, 7, 8)
        else 
            self.settings.install_date = GetDateStringFromTimestamp(GetTimeStamp()) 
        end
    end
    
    if not self.settings.version_history then self.settings.version_history = {} end
    local hist_len = #self.settings.version_history
    if hist_len == 0 or self.settings.version_history[hist_len] ~= self.version then 
        table.insert(self.settings.version_history, self.version)
        if #self.settings.version_history > 3 then 
            table.remove(self.settings.version_history, 1) 
        end 
    end
    
    self:create_ui()
    self:build_lam2_menu()
    
    if not IsConsoleUI() then self:refresh_stats_tracker() end
    self:toggle_core_events()
    self:toggle_ui_update()
    self:build_session_ui()
    
    EVENT_MANAGER:RegisterForEvent(self.name, EVENT_PLAYER_ACTIVATED, function() 
        self:integrate_with_perm_memento()
        self:trigger_memory_check("ZoneLoad", 5000) 
    end)

    SLASH_COMMANDS["/alc"] = function(raw_arg)
        local parsed_cmd = raw_arg:lower()
        if parsed_cmd == "" then
            local sl_cmds = {
                "|c00FF00Available ALC Commands:|r\n", 
                "|c00FFFF/alcon|r |cFFD700- Toggle Auto Cleanup|r\n", 
                "|c00FFFF/alcui|r |cFFD700- Toggle Memory UI|r\n",
                "|c00FFFF/alclock|r |cFFD700- Lock/Unlock UI|r\n", 
                "|c00FFFF/alcreset|r |cFFD700- Reset UI position|r\n", 
                "|c00FFFF/alcgraph|r |cFFD700- Toggle Memory Graph|r\n",
                "|c00FFFF/alcgraphlock|r |cFFD700- Lock/Unlock Graph|r\n", 
                "|c00FFFF/alclite|r |cFFD700- Toggle Lite Mode|r\n", 
                "|c00FFFF/alcdiags|r |cFFD700- Toggle Graph Diagnostics|r\n",
                "|c00FFFF/alcbar|r |cFFD700- Toggle Memory UI Bar|r\n", 
                "|c00FFFF/alcfps|r |cFFD700- Toggle FPS Tracking|r\n", 
                "|c00FFFF/alcping|r |cFFD700- Toggle Latency Tracking|r\n",
                "|c00FFFF/alcgains|r |cFFD700- Toggle KB/MB Tracking|r\n", 
                "|c00FFFF/alcsession|r |cFFD700- Toggle Session UI|r\n", 
                "|c00FFFF/alcsessionlock|r |cFFD700- Lock Session UI|r\n",
                "|c00FFFF/alcsessionreset|r |cFFD700- Reset Session UI|r\n", 
                "|c00FFFF/alccsa|r |cFFD700- Toggle Announcements|r\n", 
                "|c00FFFF/alcstats|r |cFFD700- Toggle Saving Statistics|r\n",
                "|c00FFFF/alcstatpeak|r |cFFD700- Toggle Session Peak Logs|r\n", 
                "|c00FFFF/alcstatavg|r |cFFD700- Toggle Session Avg Logs|r\n",
                "|c00FFFF/alcstatfinal|r |cFFD700- Toggle Session Final Logs|r\n", 
                "|c00FFFF/alcstatclean|r |cFFD700- Toggle Session Clean Logs|r\n"
            }
            if not IsConsoleUI() then 
                table.insert(sl_cmds, "|c00FFFF/alclogs|r |cFFD700- Toggle Chat Logs|r\n") 
            end
            table.insert(sl_cmds, "|c00FFFF/alcclean|r |cFFD700- Force manual Lua memory cleanup|r")
            
            if CHAT_SYSTEM then 
                CHAT_SYSTEM:AddMessage("|c00FFFF[ALC]|r\n" .. table.concat(sl_cmds)) 
            end
            return
        end
    end
    SLASH_COMMANDS["/autoluaclean"] = SLASH_COMMANDS["/alc"]

    SLASH_COMMANDS["/alcon"] = function() 
        self.settings.is_enabled = not self.settings.is_enabled
        self:toggle_core_events() 
    end
    SLASH_COMMANDS["/alcenable"] = SLASH_COMMANDS["/alcon"]
    
    SLASH_COMMANDS["/alcui"] = function() 
        self.settings.show_ui = not self.settings.show_ui
        self:toggle_ui_update() 
    end
    SLASH_COMMANDS["/alctoggleui"] = SLASH_COMMANDS["/alcui"]
    
    SLASH_COMMANDS["/alclock"] = function() 
        self.settings.is_ui_locked = not self.settings.is_ui_locked
        if self.ui_window then self.ui_window:SetMovable(not self.settings.is_ui_locked) end 
    end
    SLASH_COMMANDS["/alcuilock"] = SLASH_COMMANDS["/alclock"]
    
    SLASH_COMMANDS["/alcreset"] = function() 
        self.settings.ui_x = nil
        self.settings.ui_y = nil
        self:update_ui_anchor() 
    end
    SLASH_COMMANDS["/alcuireset"] = SLASH_COMMANDS["/alcreset"]
    
    SLASH_COMMANDS["/alccsa"] = function() 
        self.settings.is_csa_enabled = not self.settings.is_csa_enabled 
    end
    SLASH_COMMANDS["/alctogglecsa"] = SLASH_COMMANDS["/alccsa"]
    
    SLASH_COMMANDS["/alcstats"] = function() 
        self.settings.track_stats = not self.settings.track_stats
        AutoLuaCleaner:refresh_stats_tracker() 
    end
    SLASH_COMMANDS["/alctogglestats"] = SLASH_COMMANDS["/alcstats"]

    if not IsConsoleUI() then 
        SLASH_COMMANDS["/alclogs"] = function() 
            self.settings.is_log_enabled = not self.settings.is_log_enabled 
        end
        SLASH_COMMANDS["/alcchatlogs"] = SLASH_COMMANDS["/alclogs"] 
    end

    SLASH_COMMANDS["/alcclean"] = function() self:run_manual_cleanup() end
    SLASH_COMMANDS["/alccleanup"] = SLASH_COMMANDS["/alcclean"]

    if self.settings.is_stats_log_enabled then 
        EVENT_MANAGER:RegisterForUpdate("ALC_StatsTick", 60000, function() 
            AutoLuaCleaner:check_session_peak() 
        end) 
    end
    
    EVENT_MANAGER:RegisterForEvent("ALC_LogOut", EVENT_PLAYER_DEACTIVATED, function() 
        AutoLuaCleaner:save_session_history() 
    end)

    SLASH_COMMANDS["/alcgraph"] = function() 
        self.settings.is_graph_enabled = not self.settings.is_graph_enabled
        self:toggle_ui_update() 
    end
    
    SLASH_COMMANDS["/alcgraphreset"] = function() 
        self.settings.graph_x = nil
        self.settings.graph_y = nil
        self.settings.is_graph_detached = false
        if graph_window and self.ui_window then 
            graph_window:ClearAnchors()
            graph_window:SetAnchor(TOPLEFT, self.ui_window, BOTTOMLEFT, 0, 5) 
        end 
    end
    
    SLASH_COMMANDS["/alcgraphlock"] = function() 
        self.settings.is_graph_locked = not self.settings.is_graph_locked
        if graph_window then graph_window:SetMovable(not self.settings.is_graph_locked) end 
    end
    
    SLASH_COMMANDS["/alclite"] = function() 
        self.settings.lite_mode = not self.settings.lite_mode
        self:build_graph_ui() 
    end
    
    SLASH_COMMANDS["/alcdiags"] = function() 
        self.settings.show_graph_diags = not self.settings.show_graph_diags
        self:build_graph_ui() 
    end
    
    SLASH_COMMANDS["/alcbar"] = function() 
        self.settings.show_mem_ui_bar = not self.settings.show_mem_ui_bar
        self:update_ui_anchor() 
    end
    
    SLASH_COMMANDS["/alcfps"] = function() 
        self.settings.track_fps = not self.settings.track_fps
        stat_baseline_fps = 0
        stat_fps_stable_ticks = 0
        stat_last_fps_raw = 0
        self:build_graph_ui() 
    end
    
    SLASH_COMMANDS["/alcping"] = function() 
        self.settings.track_ping = not self.settings.track_ping
        stat_ticks = 0
        stat_total_ping = 0
        stat_baseline_ping = 0
        stat_ping_stable_ticks = 0
        stat_last_ping_raw = 0
        graph_latency_pool = {}
        self:build_graph_ui() 
    end
    
    SLASH_COMMANDS["/alcgains"] = function() 
        self.settings.track_memory_gains = not self.settings.track_memory_gains
        self:build_graph_ui() 
    end
    
    SLASH_COMMANDS["/alcsession"] = function() 
        self.settings.show_session_ui = not self.settings.show_session_ui
        self:build_session_ui() 
    end
    
    SLASH_COMMANDS["/alcsessionlock"] = function() 
        self.settings.is_session_locked = not self.settings.is_session_locked
        if session_window then session_window:SetMovable(not self.settings.is_session_locked) end 
    end
    
    SLASH_COMMANDS["/alcsessionreset"] = function() 
        self.settings.session_ui_x = nil
        self.settings.session_ui_y = nil
        self:update_session_anchor() 
    end
    
    SLASH_COMMANDS["/alcstatpeak"] = function() 
        self.settings.session_track_peak = not self.settings.session_track_peak 
    end
    
    SLASH_COMMANDS["/alcstatavg"] = function() 
        self.settings.session_track_avg = not self.settings.session_track_avg 
    end
    
    SLASH_COMMANDS["/alcstatfinal"] = function() 
        self.settings.session_track_final = not self.settings.session_track_final 
    end
    
    SLASH_COMMANDS["/alcstatclean"] = function() 
        self.settings.session_track_cleaned = not self.settings.session_track_cleaned 
    end
end

EVENT_MANAGER:RegisterForEvent(
    AutoLuaCleaner.name, 
    EVENT_ADD_ON_LOADED, 
    function(...) AutoLuaCleaner:init(...) end
)
