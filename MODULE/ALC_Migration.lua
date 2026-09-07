-- AutoLuaMemoryCleaner - Copyright 2025-2026 @APHONlC. 
-- Licensed under the GNU General Public License v3.0 (GPLv3). 
-- See LICENSE.md and NOTICE.md.

-- This file must load after Core/ALC_Core.lua.
if not ALC then return end

function ALC.migrate_data()
    if ALC.settings then
        ALC.settings.pmOverridden = nil
    end
end

ALC._modules.migration = true