# ConfigManager

**Take your setup with you – to every version of World of Warcraft.**

ConfigManager copies your key bindings, action bar contents, macros, game settings and chat setup between WoW versions with a single export string. Set up your UI once, then carry it from Classic Era to TBC, from the Forever beta to the Forever launch, or from Midnight back to Classic.

---

## Why ConfigManager?

For years the usual advice was to copy your `WTF` folder. That only works **within the same game version**: Classic Era, TBC Anniversary, MoP Classic, WoW Forever and Midnight each use their own folders, their own spell IDs and their own settings.

ConfigManager reads your setup **inside the game**, stores it in a version-neutral format, and writes it back on the other side. Anything the target version doesn't have is skipped and listed for you. Nothing breaks, and nothing is changed without you knowing.

---

## What gets copied

You choose each part separately, both when you export and when you import:

| Section | What it contains |
|---|---|
| **Key bindings** | All bindings shown in the game's key binding menu, including Shift / Ctrl / Alt combinations, mouse buttons and the mouse wheel |
| **Action bar contents** | Spells, items and macros on every action bar slot |
| **Macros** | Name, icon and text of your account and character macros |
| **Controls** | Auto loot (and its modifier key), loot under mouse, click-to-move interaction, self cast, cast on key down, … |
| **Action bar options** | Which extra bars are enabled, lock action bars, always show bars, cooldown numbers |
| **Interface** | Name display, nameplates, status text, target of target, buff durations, floating combat text, quest tracking, minimap rotation, tutorials |
| **Chat** | Chat window names, font sizes and message types, the standard channels per window (General, Trade, LocalDefense, LookingForGroup, …), colours per message type, class-coloured names, timestamps, chat style, whisper mode, chat bubbles, profanity filter |

The game settings deliberately stick to options that **exist in every WoW version** (based on Classic Era), so the same string works everywhere.

### What is *not* copied

- Graphics, camera and sound settings (too different between versions)
- Positions and sizes of Blizzard frames
- Custom chat channels (only the standard channels are transferred)
- Settings of other addons (planned for a later version)

---

## Built for moving between versions

- **Keyboard layouts are converted.** A binding on the key next to *T* stays on the key next to *T*, whether that key is called *Z* (QWERTZ) or *Y* (QWERTY). You can also switch to "keep key name" if you prefer.
- **Spell ranks are handled.** If a spell ID doesn't exist in the target version, ConfigManager finds the spell by name and uses your highest known rank.
- **Missing bars are skipped safely.** Bars 6–8 from Retail-style clients are skipped and counted on Classic clients instead of causing errors.
- **Missing settings are reported.** The import preview shows exactly how many settings or chat colours don't exist in the current version.
- **Every export remembers where it came from**, e.g. *Classic Era 1.15.9* or *Forever 1.60.1*, and the import preview shows it.
- **Compact strings.** Exports are compressed (deflate). The format is the same on every client, so a string made on Midnight imports on Classic Era and vice versa. Older uncompressed strings still import.
- **Unknown macro icons become "?".** An icon that doesn't exist in the target version is replaced with the question mark instead of leaving an empty macro.

---

## Two ways to see your bindings

### Keyboard view
A full on-screen keyboard showing what is bound to every key, colour-coded by category (action bars, movement, targeting, interface, macros & other), with spell icons right on the keys.

- **Your real keyboard.** On first start you pick your keyboard layout and size, so the view matches the keys in front of you: no guessing from your game language or region (an English client on a German keyboard in Spain works just as well). Five sizes: 100 % with numpad, TKL, 75 %, 65 % and 60 %, each with or without an F-row, including the L-shaped ISO Enter key. You can change it at any time in the settings or with the keyboard button above the keyboard.
- **Click a key** to see all **8 modifier combinations** for it in the side panel, and assign, change or remove bindings directly.
- **Click or hold Shift, Ctrl or Alt** to switch the whole keyboard to that layer.
- **Search** for an action, and the matching keys light up.
- **Mouse buttons and the mouse wheel** get their own panel.

### List view
An improved version of the Blizzard key binding list:

- **Shows the actual spell or macro** behind every action bar slot, not just "Action Button 3"
- **Search by action or by key**, e.g. *Whirlwind* or *Shift+E*
- **Filters:** Bound, Unbound, Changed
- **Category sidebar** with counters
- **Clear key capture:** click a field, press the new key (mouse buttons and wheel work too), Esc cancels, right-click removes
- **Changes are collected** and only saved when you click *Apply*; *Discard* reverts everything
- **Scroll bar** for long lists

### Account or character bindings
A button at the bottom of the window shows where your key bindings are saved: **account-wide** or **for this character only**, the same choice as in the game's key binding menu. Click it to switch. Switching back to account-wide asks first, because the character-specific bindings are discarded.

---

## Profiles per specialization

- ConfigManager saves a **profile for each specialization** and switches it automatically when you change spec. On Classic Era, where there are no specializations, the profile follows your talent tree with the most points.
- **New spec without a profile?** A short dialog suggests what to load: the saved profile of this spec, a profile of the same class, the **Tank / Healer / DPS** preset of your class (key bindings and action bars), or nothing. Roles your class can't play are greyed out.
- The **profile manager** lets you sort profiles (manually, by name, date or class), rename them, load them, and delete several at once.
- **You choose what a profile loads.** Profiles always store everything, but you decide which sections are applied when a profile is loaded (by spec switch, from the menu or from the profile manager), e.g. only key bindings and action bars.
- **Automatic backups** are created before every import. The five most recent are kept.

---

## Class and spec presets

Starting a new character or a new spec? ConfigManager ships a preset for **every class and specialization**: 28 presets for all 27 talent trees, with Feral as cat and as bear. Each preset fills your action bars and sets matching key bindings:

| Bar | Keys | Contents |
|---|---|---|
| Action bar 1 | 1–5, Q, E, R, F, G, T, V | Rotation and core abilities |
| Bottom left bar | Shift + 1–5, Q, E, R, F, G | Cooldowns and defensives |
| Bottom right bar | Ctrl + 1–5, Q, E | Buffs, stances, utility |
| Right bar | Alt + 1–4 | Pets, conjured items, rarely used spells |
| Stance / form bars | same as bar 1 | Warrior stances, Cat / Bear / Moonkin Form, Stealth openers |

- The spell choice follows the TBC spell summaries and rotation guides on **Icy Veins**, cross-checked with **Wowhead**.
- Spells are placed **by name**, so every character gets the highest rank it knows. Spells your character hasn't learned yet are skipped and counted; load the preset again later to fill them in.
- The spec suggestion dialog offers the matching preset for each role, and the *Presets* menu lists all presets of your class.
- `/cfgm checkpresets` lists which preset spells your character doesn't know.
- Presets are written for TBC Anniversary. On Classic Era the TBC-only spells are skipped; on Forever and Midnight spells that no longer exist are skipped.
- Role presets (Tank / Healer / DPS, key bindings only) are still available for every class.

---

## Import modes

- **Merge**: only the keys and slots contained in the string are changed.
- **Replace**: resets key bindings to the game defaults first, then imports.
- **Save as profile**: keep an imported string for later without applying it.

The import preview shows the source character, class, specialization and game version, plus how many bindings will change and how many entries are unknown on this character, **before** anything is applied.

---

## Settings

- **Language:** follows your client automatically or can be chosen manually. English, German, French, Spanish (EU/LatAm), Italian, Portuguese, Russian, Korean, Simplified and Traditional Chinese.
- **Keyboard:** layout and size as described above, changeable at any time
- **Keyboard layout:** German, Austrian and Swiss QWERTZ; US and UK QWERTY; French and Belgian AZERTY; Spanish, Latin American, Italian, Portuguese (PT/BR), Swedish/Finnish, Danish, Norwegian and Russian.
- **Keyboard size:** 100 % with numpad, TKL, 75 %, 65 % or 60 %, with or without F-row
- **Extra mouse buttons:** 0 to 12
- **Window scale**, minimap button, automatic profile saving, spec suggestions

---

## How to open it

- **Minimap button.** Left-click opens ConfigManager, right-click opens the settings. Built on LibDBIcon, so minimap collectors such as MinimapButtonButton pick it up.
- **Addon compartment** (Forever, Midnight)
- **ConfigManager button** inside the game's key binding settings
- **Key binding** of your choice (*Key Bindings → AddOns → ConfigManager*)
- **Slash commands:**

| Command | Action |
|---|---|
| `/cfgm` or `/configmanager` | Open / close the main window |
| `/cfgm export` | Open the export dialog |
| `/cfgm import` | Open the import dialog |
| `/cfgm list` | Open the list view |
| `/cfgm profiles` | Open the profile manager |
| `/cfgm settings` | Open the settings |
| `/cfgm spec` | Show the specialization suggestion again |
| `/cfgm keyboard` | Choose your keyboard layout and size |
| `/cfgm checkpresets` | List preset spells your character doesn't know yet |
| `/cfgm minimap` | Check why the minimap button isn't visible |
| `/cfgm errors` | Show the error log (for bug reports) |

---

## Safe by design

- **Locked in combat:** nothing can be changed or imported while you are in combat.
- **Target version first:** only settings that exist in the target version are written.
- **Backup before every import**, restorable from the profile manager
- **Stays out of Blizzard's way:** no Blizzard UI functions are replaced, so ConfigManager won't block other UI actions.
- **Built-in error log:** errors are kept across logouts and can be copied straight into a bug report with `/cfgm errors`.

---

## Supported game versions

- Classic Era, including Hardcore and Season of Discovery
- TBC Anniversary
- Mists of Pandaria Classic
- WoW Forever, including the beta
- Midnight (Retail)

### Gamepads
Gamepad and controller bindings are **not supported yet**. They are planned for a later version. Keyboard and mouse bindings are not affected.

---

## Quick start: moving your setup

1. On the **source** character, type `/cfgm export`, leave all sections ticked and copy the string (Ctrl+C).
2. Save the string somewhere safe, e.g. in a text file.
3. On the **target** character (any supported version), type `/cfgm import` and paste the string.
4. Check the preview, choose *Merge* or *Replace*, and click **Import**.

> **Tip for Forever beta players:** export every character **before the beta closes**. Action bar contents are stored on the server and can only be read by an addon in-game. Once the beta is offline, they can't be recovered.

---

## FAQ

**Do I need ConfigManager on both versions?**
Yes. It has to read your setup on the source side and write it on the target side.

**Why does ConfigManager ask for my keyboard?**
Your game language says nothing about the keyboard on your desk. ConfigManager needs the physical layout to show the right keys and to keep bindings on the same physical key when you move between layouts.

**Do presets overwrite my bars?**
Presets merge: only the slots and keys they use are changed, and a backup is created first.

**My character doesn't know some of the spells yet. What happens?**
Those slots are skipped and counted in the import summary. Import again after learning them, and only the missing slots are filled.

**Will it overwrite my other addons' settings?**
No. ConfigManager only touches the game's own key bindings, action bars, macros and the listed game and chat settings.

**Does it work with action bar addons like Bartender or ElvUI?**
ConfigManager works with the game's own key bindings and action slots. Addons that use those, like EllesmereUI, pick up the imported bindings automatically. Addons that keep their own separate binding system aren't affected.

**I found a bug. What should I include?**
Type `/cfgm errors`, click *Select all*, copy the log and add it to your report together with your game version.

---

## Feedback & translations

Bug reports, ideas and translation fixes are very welcome. Please use the issue tracker or the comments section. The non-English and non-German translations would especially benefit from native speakers.
