------------------------------------------------------------
-- StealthAlert - Stealth Detection Engine
------------------------------------------------------------

local StealthAlert = _G.StealthAlert
local Stealth = {}

local initialized = false

------------------------------------------------------------
-- Stealth Auras (UNIT_AURA)
------------------------------------------------------------
local STEALTH_AURAS = {
    ["Stealth"]      = true,
    ["Prowl"]        = true,
    ["Camouflage"]   = true,
    ["Shadowmeld"]   = true,
}

------------------------------------------------------------
-- Stealth SpellIDs (COMBAT_LOG_EVENT_UNFILTERED)
------------------------------------------------------------
local STEALTH_SPELLIDS = {
    [1784]   = "Stealth",
    [1856]   = "Vanish",
    [115191] = "Subterfuge",
    [5215]   = "Prowl",
    [102547] = "Prowl",
    [199483] = "Camouflage",
    [5384]   = "Feign Death",
    [58984]  = "Shadowmeld",
    [66]     = "Invisibility",
    [110960] = "Greater Invisibility",
    [310143] = "Soulshape",
}

------------------------------------------------------------
-- Throttling
------------------------------------------------------------
local lastStealthGuids = {}
local lastStealthNames = {}
local lastSpellTime = {}
local lastPlateDisappear = {}

local function ShouldThrottle(name, guid, spellID)
    local now = GetTime()

    if guid then
        if lastStealthGuids[guid] and (now - lastStealthGuids[guid]) < 5 then
            return true
        end
        lastStealthGuids[guid] = now
    end

    if name then
        if lastStealthNames[name] and (now - lastStealthNames[name]) < 5 then
            return true
        end
        lastStealthNames[name] = now
    end

    if spellID then
        if lastSpellTime[spellID] and (now - lastSpellTime[spellID]) < 2 then
            return true
        end
        lastSpellTime[spellID] = now
    end

    return false
end

------------------------------------------------------------
-- Utility
------------------------------------------------------------
local function IsEnemyUnit(unit)
    return UnitExists(unit)
       and UnitCanAttack("player", unit)
       and not UnitIsFriend("player", unit)
end

local function IsPlayerGUID(guid)
    return guid and guid:sub(1, 7) == "Player-"
end

local function HasStealthAura(unit)
    local found = false

    AuraUtil.ForEachAura(unit, "HELPFUL", nil, function(aura)
        if aura and STEALTH_AURAS[aura.name] then
            found = true
            return true
        end
    end)

    return found
end

------------------------------------------------------------
-- Class Coloring
------------------------------------------------------------
local function ColorizeName(name, unit)
    if not name then return "Unknown" end

    local class
    if unit and UnitExists(unit) then
        _, class = UnitClass(unit)
    else
        _, class = UnitClass(name)
    end

    if not class then
        return name
    end

    local color = RAID_CLASS_COLORS[class]
    if not color then
        return name
    end

    return string.format("|cff%02x%02x%02x%s|r",
        color.r * 255, color.g * 255, color.b * 255,
        name
    )
end

------------------------------------------------------------
-- Distance Calculation & Filtering
------------------------------------------------------------
local function GetUnitDistance(unit)
    if not unit or not UnitExists(unit) then
        return nil
    end

    -- Try UnitDistanceSquared first (most accurate when available)
    local sq = UnitDistanceSquared(unit)
    if sq then
        return math.sqrt(sq)
    end

    -- Fallback: CheckInteractDistance for rough estimates
    -- Distance 1 = 28 yards, 2 = 11 yards, 3 = 10 yards, 4 = 30 yards
    if CheckInteractDistance(unit, 3) then
        return 10 -- Within 10 yards
    elseif CheckInteractDistance(unit, 2) then
        return 11 -- Within 11 yards
    elseif CheckInteractDistance(unit, 1) then
        return 28 -- Within 28 yards
    elseif CheckInteractDistance(unit, 4) then
        return 30 -- Within 30 yards
    end

    -- Unknown distance
    return nil
end

local function IsWithinRange(unit)
    if not unit or not UnitExists(unit) then
        return true, nil -- CLEU events have no unit reference
    end

    local maxRange = StealthAlertDB.maxRange or 60
    local distance = GetUnitDistance(unit)

    if distance then
        return distance <= maxRange, distance
    end

    -- If we can't determine distance, allow it but return nil distance
    return true, nil
end

local function FindUnitByGUID(guid)
    if not guid then return nil end

    -- direct units
    for _, unit in ipairs({"target", "focus", "mouseover"}) do
        if UnitGUID(unit) == guid then
            return unit
        end
    end

    -- nameplates
    for i = 1, 40 do
        local u = "nameplate"..i
        if UnitGUID(u) == guid then
            return u
        end
    end

    return nil
end

------------------------------------------------------------
-- Spell Tracking Toggles
------------------------------------------------------------
local function IsSpellTrackingEnabled(spellName)
    if spellName == "Stealth" and StealthAlertDB.trackStealth then return true end
    if spellName == "Vanish" and StealthAlertDB.trackVanish then return true end
    if spellName == "Subterfuge" and StealthAlertDB.trackSubterfuge then return true end
    if spellName == "Prowl" and StealthAlertDB.trackProwl then return true end
    if spellName == "Camouflage" and StealthAlertDB.trackCamo then return true end
    if spellName == "Shadowmeld" and StealthAlertDB.trackShadowmeld then return true end
    if spellName == "Invisibility" and StealthAlertDB.trackInvis then return true end
    if spellName == "Greater Invisibility" and StealthAlertDB.trackGreaterInvis then return true end
    if spellName == "Feign Death" and StealthAlertDB.trackFeignDeath then return true end
    if spellName == "Soulshape" and StealthAlertDB.trackSoulshape then return true end

    return false
end

------------------------------------------------------------
-- Central Handler
------------------------------------------------------------
local function HandleStealthDetected(unit, nameOverride, spellID, guidOverride)
    if not initialized then return end
    if not StealthAlertDB.enabled then return end
    if not StealthAlert.IsScopeAllowed() then return end

    local guid = guidOverride or (unit and UnitGUID(unit))
    if not IsPlayerGUID(guid) then return end

    local rawName = nameOverride or (unit and UnitName(unit)) or "Unknown"

    if unit and not IsEnemyUnit(unit) then
        return
    end

    -- Distance filtering (now returns both check and distance)
    local inRange, distance = IsWithinRange(unit)
    if not inRange then
        return
    end

    local spellName = spellID and STEALTH_SPELLIDS[spellID] or nil

    -- Spell toggle filtering
    if spellName and not IsSpellTrackingEnabled(spellName) then
        return
    end

    if ShouldThrottle(rawName, guid, spellID) then
        return
    end

    -- Class-colored name
    local coloredName = ColorizeName(rawName, unit)

    -- Send to Alerts visual with distance
    if StealthAlert.ui["Alerts"] and StealthAlert.ui["Alerts"].STEALTH_DETECTED then
        StealthAlert.ui["Alerts"]:STEALTH_DETECTED(coloredName, spellName, distance)
    end
    
    local distStr = distance and string.format(" at ~%dyd", math.floor(distance)) or ""
    StealthAlert:Debug("Stealth detected: " .. rawName .. " (" .. (spellName or "unknown spell") .. ")" .. distStr)
end

------------------------------------------------------------
-- UNIT_AURA
------------------------------------------------------------
function Stealth:UNIT_AURA(unit)
    if not initialized then return end
    if not StealthAlertDB.enabled then return end
    if not StealthAlert.IsScopeAllowed() then return end

    if not unit or not UnitExists(unit) then return end
    if not IsEnemyUnit(unit) then return end

    if HasStealthAura(unit) then
        HandleStealthDetected(unit)
    end
end

------------------------------------------------------------
-- COMBAT_LOG_EVENT_UNFILTERED
------------------------------------------------------------
function Stealth:COMBAT_LOG_EVENT_UNFILTERED(...)
    if not initialized then return end
    if not StealthAlertDB.enabled then return end
    if not StealthAlert.IsScopeAllowed() then return end

    local _, subEvent, _, srcGUID, srcName, srcFlags, _, _, _, _, _, spellID =
        CombatLogGetCurrentEventInfo()

    if not srcGUID or not srcName or not spellID then return end
    if not IsPlayerGUID(srcGUID) then return end

    local isHostile = bit.band(srcFlags, COMBATLOG_OBJECT_REACTION_HOSTILE) ~= 0
    if not isHostile then return end

    local spellName = STEALTH_SPELLIDS[spellID]
    if not spellName then return end

    if not IsSpellTrackingEnabled(spellName) then return end

	if subEvent == "SPELL_AURA_APPLIED"
	or subEvent == "SPELL_CAST_SUCCESS"
	or subEvent == "SPELL_CAST_START"
	then
		local unit = FindUnitByGUID(srcGUID)

		-- range filtering for CLEU (now returns both check and distance)
		local inRange, distance = IsWithinRange(unit)
		if not inRange then
			return
		end

		HandleStealthDetected(unit, srcName, spellID, srcGUID)
	end
end

------------------------------------------------------------
-- NAME_PLATE_UNIT_REMOVED (Vanish inference)
------------------------------------------------------------
function Stealth:NAME_PLATE_UNIT_REMOVED(unit)
    if not initialized then return end
    if not StealthAlertDB.enabled then return end
    if not StealthAlert.IsScopeAllowed() then return end

    if not IsEnemyUnit(unit) then return end

    local guid = UnitGUID(unit)
    if not IsPlayerGUID(guid) then return end

    local name = UnitName(unit)
    if not name then return end

    local now = GetTime()
    if lastPlateDisappear[name] and (now - lastPlateDisappear[name]) < 2 then
        return
    end
    lastPlateDisappear[name] = now

    local health = UnitHealth(unit)
    local maxHealth = UnitHealthMax(unit)

    if health == 0 or (maxHealth > 0 and (health / maxHealth) < 0.1) then
        return
    end

    -- Distance filtering
    local inRange, distance = IsWithinRange(unit)
    if not inRange then
        return
    end

    -- Treat as generic stealth if no spellID
    HandleStealthDetected(nil, name, nil, guid)
end

------------------------------------------------------------
-- PLAYER_ENTERING_WORLD
------------------------------------------------------------
function Stealth:PLAYER_ENTERING_WORLD()
    if not initialized then return end

    wipe(lastStealthGuids)
    wipe(lastStealthNames)
    wipe(lastSpellTime)
    wipe(lastPlateDisappear)
end

------------------------------------------------------------
-- Init
------------------------------------------------------------
function Stealth:OnInit()
    initialized = true
    StealthAlert:Debug("Stealth detection initialized")
end

StealthAlert:RegisterModule("Stealth", Stealth)