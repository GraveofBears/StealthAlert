------------------------------------------------------------
-- StealthAlert - Options UI
------------------------------------------------------------

local StealthAlert = _G.StealthAlert
local Options = {}
local panel
local category

-- Track all checkboxes and sliders so we can refresh them after reset
local allCheckboxes = {}
local allSliders = {}

------------------------------------------------------------
-- Utility
------------------------------------------------------------
local function InitDB()
    StealthAlertDB = StealthAlertDB or {}
end

local function CreateCheckbox(parent, label, key, tooltip)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb.Text:SetText(label)
    cb.tooltipText = tooltip

    cb:SetScript("OnShow", function(self)
        self:SetChecked(StealthAlertDB[key])
    end)

    cb:SetScript("OnClick", function(self)
        StealthAlertDB[key] = self:GetChecked()
        StealthAlert:Debug("Option changed: " .. key .. " = " .. tostring(StealthAlertDB[key]))
    end)

    return cb
end

local function CreateSlider(parent, label, key, minVal, maxVal, step, tooltip)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetWidth(200)

    slider.Text:SetText(label)
    slider.Low:SetText(tostring(minVal))
    slider.High:SetText(tostring(maxVal))
    slider.tooltipText = tooltip

    slider:SetScript("OnShow", function(self)
        self:SetValue(StealthAlertDB[key])
        self.Text:SetText(label .. ": " .. math.floor(StealthAlertDB[key]) .. " yd")
    end)

    slider:SetScript("OnValueChanged", function(self, value)
        StealthAlertDB[key] = value
        self.Text:SetText(label .. ": " .. math.floor(value) .. " yd")
    end)

    return slider
end

local function CreateButton(parent, label, width, callback)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, 24)
    btn:SetText(label)
    btn:SetScript("OnClick", callback)
    return btn
end

------------------------------------------------------------
-- Build the Panel
------------------------------------------------------------
local function BuildPanel()
    if panel then return end
    InitDB()

    panel = CreateFrame("Frame")
    panel.name = "StealthAlert"

    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("StealthAlert")

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetText("Stealth detection and customizable alerts")

    ------------------------------------------------------------
    -- Scrollable content
    ------------------------------------------------------------
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 3, -60)
    scrollFrame:SetPoint("BOTTOMRIGHT", -27, 20)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(580, 1800)
    scrollFrame:SetScrollChild(content)

    local y = -10

    local function AddCheckbox(text, key, tooltip)
        local cb = CreateCheckbox(content, text, key, tooltip)
        cb:SetPoint("TOPLEFT", 16, y)
        table.insert(allCheckboxes, { cb = cb, key = key })
        y = y - 26
    end

    local function AddSlider(text, key, minVal, maxVal, step, tooltip)
        local slider = CreateSlider(content, text, key, minVal, maxVal, step, tooltip)
        slider:SetPoint("TOPLEFT", 16, y)
        table.insert(allSliders, { slider = slider, key = key })
        y = y - 50
    end

    ------------------------------------------------------------
    -- Master Enable
    ------------------------------------------------------------
    AddCheckbox("Enable StealthAlert", "enabled", "Master enable / disable")
    y = y - 10

    ------------------------------------------------------------
    -- Detection Scope
    ------------------------------------------------------------
    local scopeLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    scopeLabel:SetPoint("TOPLEFT", 16, y)
    scopeLabel:SetText("Detection Scope:")
    scopeLabel:SetTextColor(1, 0.82, 0)
    y = y - 20

    AddCheckbox("  Enable in Battlegrounds", "scopeBG", "Enable stealth detection in battlegrounds")
    AddCheckbox("  Enable in Arenas", "scopeArena", "Enable stealth detection in arenas")
    AddCheckbox("  Enable in World PvP", "scopeWorld", "Enable stealth detection in world PvP zones")
    y = y - 10

    ------------------------------------------------------------
    -- Output Routing
    ------------------------------------------------------------
    local outputLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    outputLabel:SetPoint("TOPLEFT", 16, y)
    outputLabel:SetText("Output Routing:")
    outputLabel:SetTextColor(1, 0.82, 0)
    y = y - 20

    AddCheckbox("  Alerts Frame", "outputAlert", "Show alerts in the center-screen alert frame")
    AddCheckbox("  Chat Window", "outputChat", "Print stealth alerts to your chat window")
    AddCheckbox("  Party Chat", "outputParty", "Send stealth alerts to your party")
    AddCheckbox("  Raid Chat", "outputRaid", "Send stealth alerts to your raid")
    AddCheckbox("  Raid Warning", "outputRW", "Send stealth alerts as raid warnings (requires leader/assist)")
    AddCheckbox("  Say", "outputSay", "Say stealth alerts in /say")
    y = y - 10

    ------------------------------------------------------------
    -- Spell Tracking
    ------------------------------------------------------------
    local spellLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    spellLabel:SetPoint("TOPLEFT", 16, y)
    spellLabel:SetText("Stealth Spells to Track:")
    spellLabel:SetTextColor(1, 0.82, 0)
    y = y - 20

    AddCheckbox("  Rogue: Stealth", "trackStealth", "Track Rogue Stealth")
    AddCheckbox("  Rogue: Vanish", "trackVanish", "Track Rogue Vanish")
    AddCheckbox("  Rogue: Subterfuge", "trackSubterfuge", "Track Subterfuge")
    AddCheckbox("  Druid: Prowl", "trackProwl", "Track Druid Prowl")
    AddCheckbox("  Hunter: Camouflage", "trackCamo", "Track Hunter Camouflage")
    AddCheckbox("  Night Elf: Shadowmeld", "trackShadowmeld", "Track Shadowmeld")
    AddCheckbox("  Mage: Invisibility", "trackInvis", "Track Mage Invisibility")
    AddCheckbox("  Mage: Greater Invisibility", "trackGreaterInvis", "Track Greater Invisibility")
    AddCheckbox("  Hunter: Feign Death", "trackFeignDeath", "Track Feign Death")
    AddCheckbox("  Soulshape", "trackSoulshape", "Track Soulshape")
    y = y - 10

    ------------------------------------------------------------
    -- Distance Filtering
    ------------------------------------------------------------
    local rangeLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    rangeLabel:SetPoint("TOPLEFT", 16, y)
    rangeLabel:SetText("Detection Range:")
    rangeLabel:SetTextColor(1, 0.82, 0)
    y = y - 30   -- increased spacing

    AddSlider("Max Detection Range", "maxRange", 10, 60, 5, "Only alert if the enemy is within this range (yards)")
    y = y - 10

    ------------------------------------------------------------
    -- Alert Frame Controls
    ------------------------------------------------------------
    local btnUnlock = CreateButton(content, "Toggle Alert Frame Move", 200, function()
        StealthAlert.unlockMode = not StealthAlert.unlockMode
        if StealthAlert.unlockMode then
            StealthAlert:Print("Alert frame unlocked — drag to move")
        else
            StealthAlert:Print("Alert frame locked")
        end

        if StealthAlert.ui["Alerts"] and StealthAlert.ui["Alerts"].ALERT_ANCHOR_MODE then
            StealthAlert.ui["Alerts"]:ALERT_ANCHOR_MODE(StealthAlert.unlockMode)
        end
    end)
    btnUnlock:SetPoint("TOPLEFT", 16, y)

    ------------------------------------------------------------
    -- Run Test Alert (Corrected: No duplicate chat output)
    ------------------------------------------------------------
    local btnTest = CreateButton(content, "Run Test Alert", 200, function()
        local testName = "TestRogue"
        local testSpell = "Stealth"

        -- Fire the same event Alerts.lua listens for
        if StealthAlert.ui["Alerts"] and StealthAlert.ui["Alerts"].STEALTH_DETECTED then
            StealthAlert.ui["Alerts"]:STEALTH_DETECTED(testName, testSpell)
        end
    end)
    btnTest:SetPoint("TOPLEFT", 16, y - 40)

    ------------------------------------------------------------
    -- Reset to Defaults
    ------------------------------------------------------------
    local btnReset = CreateButton(content, "Reset to Defaults", 200, function()
        local defaults = StealthAlert.Core and StealthAlert.Core.DB_DEFAULTS
        if not defaults then
            StealthAlert:Print("Defaults not found in Core")
            return
        end

        -- Apply defaults
        for key, value in pairs(defaults) do
            StealthAlertDB[key] = value
        end

        -- Refresh checkboxes
        for _, entry in ipairs(allCheckboxes) do
            entry.cb:SetChecked(StealthAlertDB[entry.key])
        end

        -- Refresh sliders
        for _, entry in ipairs(allSliders) do
            entry.slider:SetValue(StealthAlertDB[entry.key])
        end

        StealthAlert:Print("Settings reset to defaults")
    end)
    btnReset:SetPoint("TOPLEFT", 230, y - 40)

    y = y - 80
end

------------------------------------------------------------
-- Register the Panel
------------------------------------------------------------
local function RegisterPanel()
    if not panel then BuildPanel() end

    if Settings and Settings.RegisterCanvasLayoutCategory then
        category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        return
    end

    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
        return
    end

    print("|cff00ff96StealthAlert:|r Could not find Settings API")
end

------------------------------------------------------------
-- Init Hook
------------------------------------------------------------
function Options:OnInit()
    C_Timer.After(0.5, RegisterPanel)
end

StealthAlert:RegisterUI("Options", Options)
