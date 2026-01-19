------------------------------------------------------------
-- StealthAlert - Center Screen Alerts (with Spell Icons)
------------------------------------------------------------

local StealthAlert = _G.StealthAlert
local Alerts = {}

local WIDTH = 420
local HEIGHT = 80
local Y_OFFSET = 220

local FADE_IN = 0.15
local HOLD_TIME = 1.4
local FADE_OUT = 0.6
local ALERT_COOLDOWN = 1.0

local frame
local text
local lastAlert = {}
local initialized = false

------------------------------------------------------------
-- Position Save/Load
------------------------------------------------------------
local function LoadPosition(f)
    if StealthAlertDB and StealthAlertDB.alertsPos then
        local pos = StealthAlertDB.alertsPos
        f:ClearAllPoints()
        f:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    end
end

local function SavePosition(f)
    local point, _, relPoint, x, y = f:GetPoint()
    StealthAlertDB.alertsPos = {
        point = point,
        relPoint = relPoint,
        x = x,
        y = y,
    }
end

------------------------------------------------------------
-- Utility
------------------------------------------------------------
local function NormalizeKey(key)
    return tostring(key or "unknown")
end

local function CanAlert(key)
    key = NormalizeKey(key)
    local now = GetTime()

    if lastAlert[key] and (now - lastAlert[key]) < ALERT_COOLDOWN then
        return false
    end

    lastAlert[key] = now
    return true
end

local function PlayAlertSound()
    if not StealthAlertDB.outputAlert then return end
    PlaySound(SOUNDKIT.RAID_WARNING, "Master")
end

local function HideAlert()
    if not frame then return end
    if StealthAlert.unlockMode then return end
    frame:Hide()
    frame:SetAlpha(0)
end

------------------------------------------------------------
-- Spell Icon Helper (Modern API)
------------------------------------------------------------

local SPELL_NAME_TO_ID = {
    ["Stealth"]              = 1784,
    ["Vanish"]               = 1856,
    ["Subterfuge"]           = 115191,
    ["Prowl"]                = 5215,
    ["Camouflage"]           = 199483,
    ["Feign Death"]          = 5384,
    ["Shadowmeld"]           = 58984,
    ["Invisibility"]         = 66,
    ["Greater Invisibility"] = 110960,
    ["Soulshape"]            = 310143,
}

local function GetSpellIcon(spellName)
    if not spellName then return nil end

    local spellID = SPELL_NAME_TO_ID[spellName]
    if not spellID then return nil end

    local info = C_Spell.GetSpellInfo(spellID)
    if not info then return nil end

    return info.iconID
end

------------------------------------------------------------
-- Message Formatting (Class Colors + Icons + Safe Separator + Distance)
------------------------------------------------------------
local function FormatAlertMessage(name, spellName, distance)
    local safeName = name or "Unknown"
    
    -- Format distance if available (round to nearest 5 yards to match slider increments)
    local distStr = ""
    if distance then
        local roundedDist = math.floor((distance + 2.5) / 5) * 5
        distStr = " (~" .. roundedDist .. "yd)"
    end

    if not spellName or spellName == "" then
        return "STEALTH >> " .. safeName .. distStr
    end

    local icon = GetSpellIcon(spellName)
    if icon then
        return "|T" .. icon .. ":20:20:0:0|t " .. spellName .. " >> " .. safeName .. distStr
    end

    return spellName .. " >> " .. safeName .. distStr
end

------------------------------------------------------------
-- Display Logic
------------------------------------------------------------
local function ShowAlert(msg, key)
    if not initialized then return end
    if not StealthAlertDB.enabled then return end
    if not StealthAlertDB.outputAlert then return end
    if not CanAlert(key) then return end

    if StealthAlert.unlockMode then
        frame:SetAlpha(1)
        frame:Show()
        frame.anchor:Show()
        text:SetText("ALERT FRAME")
        text:SetTextColor(1, 1, 1)
        return
    end

    text:SetText(msg)
    text:SetTextColor(1, 0.2, 0.2)

    frame:SetAlpha(0)
    frame:Show()

    UIFrameFadeIn(frame, FADE_IN, 0, 1)

    C_Timer.After(FADE_IN + HOLD_TIME, function()
        if StealthAlert.unlockMode then return end
        if frame and frame:IsShown() then
            UIFrameFadeOut(frame, FADE_OUT, 1, 0)
            C_Timer.After(FADE_OUT, function()
                if not StealthAlert.unlockMode and frame then
                    frame:Hide()
                end
            end)
        end
    end)

    PlayAlertSound()
end

------------------------------------------------------------
-- Output Routing (Chat / Party / Raid / RW / Say)
------------------------------------------------------------
local function RouteOutput(msg)
    if StealthAlertDB.outputChat then
        print("|cff00ff96StealthAlert:|r " .. msg)
    end

    if StealthAlertDB.outputParty and IsInGroup() then
        SendChatMessage(msg, "PARTY")
    end

    if StealthAlertDB.outputRaid and IsInRaid() then
        SendChatMessage(msg, "RAID")
    end

    if StealthAlertDB.outputRW and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        SendChatMessage(msg, "RAID_WARNING")
    end

    if StealthAlertDB.outputSay then
        SendChatMessage(msg, "SAY")
    end
end

------------------------------------------------------------
-- Event Reaction
------------------------------------------------------------
function Alerts:STEALTH_DETECTED(name, spellName, distance)
    if not initialized then return end

    local msg = FormatAlertMessage(name, spellName, distance)

    ShowAlert(msg, "stealth")
    RouteOutput(msg)
end

------------------------------------------------------------
-- Cleanup
------------------------------------------------------------
function Alerts:PLAYER_ENTERING_WORLD()
    if not initialized then return end
    if StealthAlert.unlockMode then return end
    HideAlert()
    wipe(lastAlert)
end

function Alerts:TEST_CLEANUP()
    if StealthAlert.unlockMode then return end
    HideAlert()
    wipe(lastAlert)
end

------------------------------------------------------------
-- Anchor Mode Handler
------------------------------------------------------------
function Alerts:ALERT_ANCHOR_MODE(mode)
    if not initialized then return end

    if mode then
        frame:Show()
        frame:SetAlpha(1)
        frame.anchor:Show()
        text:SetText("ALERT FRAME")
        text:SetTextColor(1, 1, 1)
    else
        frame.anchor:Hide()
        HideAlert()
    end
end

------------------------------------------------------------
-- Init
------------------------------------------------------------
function Alerts:OnInit()
    frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    frame:SetSize(WIDTH, HEIGHT)
    frame:SetPoint("CENTER", 0, Y_OFFSET)
    frame:SetFrameStrata("HIGH")
    frame:Hide()

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")

    frame:SetScript("OnDragStart", function(self)
        if StealthAlert.unlockMode then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition(self)
    end)

    local anchor = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    anchor:SetAllPoints()
    anchor:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
    })
    anchor:SetBackdropColor(1, 0.8, 0, 0.25)
    anchor:Hide()
    frame.anchor = anchor

    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.35)

    text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    text:SetAllPoints()
    text:SetJustifyH("CENTER")
    text:SetJustifyV("MIDDLE")

    frame.text = text

    LoadPosition(frame)

    self.frame = frame

    initialized = true
    StealthAlert:Debug("Alerts initialized")
end

StealthAlert:RegisterUI("Alerts", Alerts)