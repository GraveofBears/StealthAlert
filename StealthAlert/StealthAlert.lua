------------------------------------------------------------
-- StealthAlert - Bootstrap / Entry File
-- Initializes namespace, event routing, and module registry
------------------------------------------------------------

---@class StealthAlert
StealthAlert = StealthAlert or {}

StealthAlert.name    = "StealthAlert"
StealthAlert.version = "1.0.0"

------------------------------------------------------------
-- Utility: Printing
------------------------------------------------------------
local PREFIX = "|cff00ff96StealthAlert:|r "

function StealthAlert:Print(msg)
    print(PREFIX .. tostring(msg))
end

function StealthAlert:Debug(msg)
    if StealthAlertDB and StealthAlertDB.debug then
        print("|cffaaaaaa[SA DEBUG]|r " .. tostring(msg))
    end
end

function StealthAlert:DebugEvent(event)
    if StealthAlertDB and StealthAlertDB.debugEvents then
        print("|cff8888ff[SA EVENT]|r " .. tostring(event))
    end
end

------------------------------------------------------------
-- Safe Call Helper
------------------------------------------------------------
local function SafeCall(func, ...)
    local ok, err = pcall(func, ...)
    if not ok then
        print(PREFIX .. "Error: " .. tostring(err))
    end
end

StealthAlert.SafeCall = SafeCall

------------------------------------------------------------
-- Module Containers
------------------------------------------------------------
StealthAlert.modules = StealthAlert.modules or {}
StealthAlert.ui      = StealthAlert.ui or {}

------------------------------------------------------------
-- Registration API
------------------------------------------------------------
function StealthAlert:RegisterModule(name, module)
    self.modules[name] = module
    self:Debug("Module registered: " .. name)
end

function StealthAlert:RegisterUI(name, ui)
    self.ui[name] = ui
    self:Debug("UI registered: " .. name)
end

------------------------------------------------------------
-- Event Dispatcher (delegates to Core)
------------------------------------------------------------
local eventFrame = CreateFrame("Frame")

eventFrame:SetScript("OnEvent", function(_, event, ...)
    StealthAlert:DebugEvent(event)

    -- Bootstrap-only events
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == StealthAlert.name then
            StealthAlert:Debug("Bootstrap loaded")
        end

    elseif event == "PLAYER_LOGIN" then
        StealthAlert:Print("Loaded v" .. StealthAlert.version)
    end

    -- Forward ALL events to Core
    if StealthAlert.Core and StealthAlert.Core.OnEvent then
        SafeCall(StealthAlert.Core.OnEvent, StealthAlert.Core, event, ...)
    end
end)

------------------------------------------------------------
-- Register Events Needed by StealthAlert
------------------------------------------------------------

-- Addon lifecycle
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")

-- PvP / Zone changes (for scope gating)
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")

-- Combat log for stealth detection
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

-- Nameplates for vanish / stealth inference
eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

-- Auras for direct stealth auras on units
eventFrame:RegisterEvent("UNIT_AURA")

-- Target / focus (for tracking units)
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
