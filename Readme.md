# StealthAlert

StealthAlert is a lightweight World of Warcraft addon that detects enemy stealth activations and displays clean, center‑screen alerts with spell icons, class‑colored names, and optional chat routing. It’s designed for PvP players who want fast, reliable awareness without clutter or noise.

## ✨ Features

- Real‑time stealth detection for:
  - Rogue: Stealth, Vanish, Subterfuge
  - Druid: Prowl
  - Hunter: Camouflage, Feign Death
  - Night Elf: Shadowmeld
  - Mage: Invisibility, Greater Invisibility
  - Soulshape
- Center‑screen alert frame with spell icons
- Class‑colored player names for instant recognition
- Distance filtering using UnitDistanceSquared
- Scope control (Battlegrounds, Arenas, World PvP)
- Output routing to Chat, Party, Raid, Raid Warning, or Say
- Movable alert frame with unlock/lock mode
- Test alert button for quick verification
- Reset to defaults button in the options panel
- Low‑overhead detection engine with throttling and vanish inference

## 📦 Installation

1. Download the addon folder.
2. Place it into:

```
World of Warcraft/_retail_/Interface/AddOns/
```

3. Restart WoW or reload your UI with `/reload`.

## ⚙️ Configuration

Open the addon options through:

```
Escape → Options → AddOns → StealthAlert
```

### Detection Scope
- Enable in Battlegrounds
- Enable in Arenas
- Enable in World PvP

### Output Routing
- Center‑screen alerts
- Chat output
- Party/Raid/Raid Warning
- Say channel

### Spell Tracking
Toggle individual stealth‑related spells.

### Detection Range
- Max detection distance slider (10–60 yards)

### Alert Frame Controls
- Toggle Alert Frame Move
- Run Test Alert
- Reset to Defaults

## 🧠 How It Works

StealthAlert listens to:

- UNIT_AURA for aura‑based stealth
- COMBAT_LOG_EVENT_UNFILTERED for spell‑based stealth
- NAME_PLATE_UNIT_REMOVED for vanish inference

It applies:

- Range filtering
- Spell toggles
- Scope restrictions
- Throttling to prevent spam

Then routes the alert to the visual frame and/or chat.

## 🧪 Slash Commands

```
/stealthalert
/sa
```

Opens the options panel.

## 📁 Project Structure

- Core.lua — initialization, DB defaults, scope logic
- Stealth.lua — detection engine
- Alerts.lua — center‑screen alert frame
- Options.lua — configuration UI

