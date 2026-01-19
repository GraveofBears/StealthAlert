------------------------------------------------------------
-- StealthAlert - Core
-- Database defaults, scope logic, module initialization,
-- and central event dispatching
------------------------------------------------------------

local StealthAlert = _G.StealthAlert

------------------------------------------------------------
-- Core Object
------------------------------------------------------------
StealthAlert.Core = StealthAlert.Core or {}
local Core = StealthAlert.Core

------------------------------------------------------------
-- Database Defaults (EXPOSED)
------------------------------------------------------------
local DB_DEFAULTS = {
    enabled       = true,
    debug         = false,
    debugEvents   = false,

    --------------------------------------------------------
    -- Detection Scope
    --------------------------------------------------------
    scopeBG       = true,
    scopeArena    = true,
    scopeWorld    = true,

    --------------------------------------------------------
    -- Output Routing
    --------------------------------------------------------
    outputAlert   = true,
    outputChat    = true,
    outputParty   = false,
    outputRaid    = false,
    outputRW      = false,
    outputSay     = false,

    --------------------------------------------------------
    -- Spell Tracking
    --------------------------------------------------------
    trackStealth      = true,
    trackVanish       = true,
    trackSubterfuge   = true,
    trackProwl        = true,
    trackCamo         = true,
    trackShadowmeld   = true,
    trackInvis        = true,
    trackGreaterInvis = true,
    trackFeignDeath   = true,
    trackSoulshape    = true,

    --------------------------------------------------------
    -- Distance Filtering
    --------------------------------------------------------
    maxRange      = 60,
}

-- Expose defaults for Options UI
Core.DB_DEFAULTS = DB_DEFAULTS

------------------------------------------------------------
-- Initialize Database (Graceful Merge)
------------------------------------------------------------
local function InitializeDatabase()
    if not StealthAlertDB then
        StealthAlertDB = {}
    end

    for key, defaultValue in pairs(DB_DEFAULTS) do
        if StealthAlertDB[key] == nil then
            StealthAlertDB[key] = defaultValue
            StealthAlert:Debug("Core: Set default " .. key .. " = " .. tostring(defaultValue))
        end
    end

    StealthAlert:Debug("Core: Database initialized")
end

------------------------------------------------------------
-- IsEnabled function
------------------------------------------------------------
function StealthAlert:IsEnabled(key)
    if not StealthAlertDB then return false end
    if not StealthAlertDB.enabled then return false end

    if key and StealthAlertDB[key] ~= nil then
        return StealthAlertDB[key]
    end

    return true
end

------------------------------------------------------------
-- PvP Scope Logic
------------------------------------------------------------
local function IsScopeAllowed()
    local inInstance, instanceType = IsInInstance()

    if instanceType == "pvp" and StealthAlertDB.scopeBG then
        return true
    end

    if instanceType == "arena" and StealthAlertDB.scopeArena then
        return true
    end

    if not inInstance and StealthAlertDB.scopeWorld then
        return true
    end

    return false
end

StealthAlert.IsScopeAllowed = IsScopeAllowed

------------------------------------------------------------
-- Registries
------------------------------------------------------------
local modules  = StealthAlert.modules
local uiPanels = StealthAlert.ui

------------------------------------------------------------
-- SafeCall wrapper
------------------------------------------------------------
local function SafeCall(target, methodName, ...)
    local fn = target[methodName]
    if type(fn) ~= "function" then return end

    if StealthAlertDB.debugEvents then
        StealthAlert:Debug("Event -> " .. methodName)
    end

    local ok, err = pcall(fn, target, ...)
    if not ok then
        StealthAlert:Print("Error in " .. methodName .. ": " .. tostring(err))
    end
end

StealthAlert.SafeCall = SafeCall

------------------------------------------------------------
-- Event Fan-Out
------------------------------------------------------------
local function DispatchEvent(event, ...)
    if not StealthAlertDB then return end

    for _, module in pairs(modules) do
        SafeCall(module, event, ...)
    end

    for _, ui in pairs(uiPanels) do
        SafeCall(ui, event, ...)
    end
end

------------------------------------------------------------
-- Initialization Fan-Out
------------------------------------------------------------
local function InitAll()
    StealthAlert:Debug("Core: InitAll starting")

    for name, module in pairs(modules) do
        if type(module.OnInit) == "function" then
            local ok, err = pcall(module.OnInit, module)
            if not ok then
                StealthAlert:Print("Error initializing module " .. name .. ": " .. tostring(err))
            else
                StealthAlert:Debug("Module initialized: " .. name)
            end
        end
    end

    for name, ui in pairs(uiPanels) do
        if type(ui.OnInit) == "function" then
            local ok, err = pcall(ui.OnInit, ui)
            if not ok then
                StealthAlert:Print("Error initializing UI " .. name .. ": " .. tostring(err))
            else
                StealthAlert:Debug("UI initialized: " .. name)
            end
        end
    end

    StealthAlert:Debug("Core: InitAll complete")
end

------------------------------------------------------------
-- ADDON_LOADED Entry Point
------------------------------------------------------------
function Core:ADDON_LOADED(addonName)
    if addonName ~= StealthAlert.name then return end

    StealthAlert:Debug("Core: ADDON_LOADED fired for StealthAlert")

    InitializeDatabase()
    InitAll()
end

------------------------------------------------------------
-- Central Event Router
------------------------------------------------------------
function Core:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == StealthAlert.name then
            Core:ADDON_LOADED(addonName)
        end
        return
    end

    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        DispatchEvent(event, CombatLogGetCurrentEventInfo())
        return
    end

    DispatchEvent(event, ...)
end
