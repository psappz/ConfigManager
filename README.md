# ConfigManager

Copy your key bindings, action bar contents, macros, game settings and chat setup between World of Warcraft versions – Classic Era, TBC Anniversary, MoP Classic, WoW Forever and Midnight – with one export string. Includes per-spec profiles.

- Download: CurseForge (link follows)
- Slash command: `/cfgm`
- Full description: [docs/curseforge-description.md](docs/curseforge-description.md)
- License: [MIT](LICENSE)

## Releasing

Releases are built by the [BigWigs packager](https://github.com/BigWigsMods/packager) GitHub Action and uploaded to CurseForge automatically:

1. Set the repository secret `CF_API_KEY` (CurseForge → Account → API Tokens).
2. Make sure `ConfigManager.toc` contains `## X-Curse-Project-ID: <your project id>`.
3. Tag a version and push it: `git tag v0.3.5 && git push origin v0.3.5`

Tags containing `alpha` or `beta` (e.g. `v0.4.0-beta`) are uploaded with that release type.
