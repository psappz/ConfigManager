# ConfigManager

## 0.9.0

### New
- **Class and spec presets** for all 27 talent trees (28 presets: Feral as cat and as bear). Each fills the action bars (rotation on bar 1, cooldowns on Shift, utility on Ctrl, pets and conjured items on Alt, plus stance and form bars) and sets matching key bindings. Spell choice based on the Icy Veins TBC spell summaries, cross-checked with Wowhead. Spells are placed by name, so the highest known rank is used; unknown spells are skipped.
- Spec suggestion: the Tank / Healer / DPS buttons load the preset of your class for that role.
- `/cfgm checkpresets` lists preset spells the character doesn't know yet.
- **Compressed export strings** (deflate via LibDeflate, or the game's own codec where available). Same format on every client; old strings still import.
- **Choose what a profile loads:** section selection for loading profiles (spec switch, menu, profile manager).
- **Account / character bindings:** button in the main window to switch where key bindings are saved.
- Macro icons that don't exist on the target client are replaced with the question mark.
- Scroll bar in the list view.
- One **Import / Export** button in the header instead of two (both share one dialog).
- Profile manager explains that only the last 5 backups are kept.
- Keyboard dialog: layout and size are asked for instead of guessed from the client language; five sizes (100 %, TKL, 75 %, 65 %, 60 %), F-row as a separate option, ISO Enter key. Changeable at any time.

### Fixed
- 65 % and 75 % ISO keyboards: Page Down no longer overlaps the Enter key.
- List view: rows no longer extend below the table; the number of rows follows the window size and UI scale.
- Import dialog: the "Key bindings are saved" note is no longer hidden behind the buttons.
- Keyboard view: the layer statistics line no longer runs into the key detail panel.

### Known limitations
- Gamepad bindings are not supported yet (planned).
- Settings of other addons are not copied yet (planned).
