# ConfigManager

Copy your key bindings, action bar contents, macros, game settings and chat setup between World of Warcraft versions – Classic Era, TBC Anniversary, MoP Classic, WoW Forever and Midnight – with one export string. Includes per-spec profiles, class and spec presets for every class, and a keyboard view that matches your physical keyboard.

Gamepad bindings are not supported yet.

- Download: [CurseForge](https://www.curseforge.com/wow/addons/configmanager)
- Slash command: `/cfgm`
- Full description: [docs/curseforge-description.md](docs/curseforge-description.md)
- Changes: [CHANGELOG.md](CHANGELOG.md)
- License: [MIT](LICENSE)

## Preset sources

The class and spec presets in `Presets.lua` are based on the TBC spell summaries and rotation guides on [Icy Veins](https://www.icy-veins.com/tbc-classic/), cross-checked with [Wowhead](https://www.wowhead.com/tbc).

## Releasing

Releases are built by the [BigWigs packager](https://github.com/BigWigsMods/packager) GitHub Action and uploaded to CurseForge automatically:

1. Set the repository secret `CF_API_KEY` (CurseForge → Account → API Tokens).
2. Make sure `ConfigManager.toc` contains `## X-Curse-Project-ID: <your project id>`.
3. Tag a version and push it: `git tag v0.9.0 && git push origin v0.9.0`

Tags containing `alpha` or `beta` (e.g. `v0.4.0-beta`) are uploaded with that release type.
