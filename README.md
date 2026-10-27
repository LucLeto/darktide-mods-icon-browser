# Icon Browser

Developer utility mod for **Warhammer 40,000: Darktide**.

> [!IMPORTANT]
> **This is not a gameplay mod.**
> Icon Browser is a development and modding tool meant to help mod authors inspect UI icon materials and asset paths inside Darktide. It does not add combat features, progression changes, quality-of-life gameplay advantages, or balance changes.

## What it does

Icon Browser opens a full-screen, Darktide-styled asset explorer for a large indexed set of Darktide UI icon materials. It is laid out like the game's own terminal screens:

- a header with the title, a search field, category and sort menus, favorites/recent filters, grid/list toggle, thumbnail size and the filtered/total asset count
- the asset browser, as a grid of thumbnails or a sortable list (preview, name, ID, category, resource path)
- a persistent inspector on the right with a large preview, the full material path, metadata and copy actions

The workflow is: **open the browser, search or browse, select an asset, inspect it, copy the reference you need.**

Selecting an asset never touches the clipboard. Copying is explicit: use **Copy Material Path**, double-click an asset, or press **Ctrl+C** / **C**. Every copy shows one in-game notification with a developer-friendly line, which DMF also writes to the log (or wherever your DMF logging settings send notifications), for example:

```text
[IconBrowser] Copied #110 content/ui/materials/icons/abilities/frames/background
```

## Features

- Near-full-screen layout that adapts to resolution, aspect ratio (including ultrawide) and UI scale, and stays clear of the input legend
- Terminal look taken from the game: dark green panels, olive frames, sage text and gold selection highlights
- Case-insensitive search over the material path, filename, readable name, localized name, browser ID and the game scripts and items that use an icon; multiple terms, partial matches, underscores and hyphens read as spaces
- Categories derived from the material path, from Abilities to Backgrounds; anything unmatched stays visible under Other
- Sorting by name, resource path, category or browser index, ascending or descending; list column headers sort on click
- Grid view with automatic columns and compact / normal / large thumbnails, and a compact list view; both share search, filters, sorting and selection
- Inspector with a large preview (dark, light or checkerboard background, zoom, display aspect), the full wrapped material path, filename, browser ID, category, name source and preview status
- Source references: where the game's scripts name an icon (`scripts/...lua:line`), which items use it as their HUD icon, and the size the game draws it at; the preview's Auto aspect follows that size, and **Copy Sources** copies every reference
- Copy actions: material path, filename, Lua string and a ready-to-use Lua UI snippet: a texture pass for `UIWidget.create_definition`, or a scenegraph node with a widget definition that draws the icon in it (see **UI Snippet Format**); both are sized to the size the game draws the icon at where it is known
- **Show Related** in the inspector lists an asset's family (variants such as `credits_big` / `credits_small` or `_01` to `_05`), its folder, the same filename in other folders and every game script that uses it, each with its count; picking one filters the browser to those assets
- Search filters, also written by **Show Related** and combinable with search terms: `in:icons/currencies/` (folder and subfolders), `family:icons/currencies/credits`, `filename:credits_big` and `file:wallet_settings.lua`
- Multi-selection: **Ctrl+click** adds or removes an asset, **Shift+click** selects a range (**Ctrl+Shift+click** adds one), **Ctrl+A** selects every listed asset; the inspector then lists the selection and copies all paths (one per line), all filenames, a Lua array of the paths or a Lua table keyed by filename, and adds or removes all favorites at once
- Favorites and a recent-assets history (selected or copied), both saved by full material path between sessions
- Localized names where the game's own definitions name an icon (mission types, circumstances, currencies, difficulty levels, classes, item types, crafting recipes, and the items that use an icon as their HUD icon, such as weapons); other assets get a readable name derived from the filename
- Hover tooltip with the complete material path
- Keyboard support: **Ctrl+F** search, arrow keys navigate, **Enter** selects, **Ctrl+A** selects all listed assets, **Ctrl+C** / **C** copies the path (all paths of a multi-selection), **F** toggles the favorite, **Esc** leaves the search field, reduces a multi-selection to one asset, or closes the browser
- Previews that fail to render show a fallback, are reported once, and stay searchable and copyable
- Icons whose material is not loaded (they would draw as white squares) show **NOT AVAILABLE** in red instead, and the inspector's preview status says so; `/icon_browser_unloaded` copies the full list of them
- Default hotkey to open and close the browser: **F8**
- Broad UI package preloading to surface more icon and asset references from menus, HUD, inventory, crafting, vendors, missions, and related interfaces
- Localized mod text for multiple languages

## Intended audience

This mod is aimed at:

- Darktide mod authors
- UI modders
- developers looking for icon/material references
- anyone building tools, overlays, menus, widgets, or HUD elements for Darktide mods

If you are looking for a regular player-facing gameplay mod, this is probably **not** the mod you want.

## Typical use case

1. Open the browser in-game with **F8**.
2. Type part of a name or path, or pick a category.
3. Click an asset to inspect its preview and full material path.
4. Copy the material path, filename, Lua string or UI snippet.
5. Paste it into your own Lua/UI code.

## Configuration

The Mod Options have two tabs.

**Browser**

- **Open Icon Browser** keybind
- **Thumbnail Density**: compact, normal or large (also switchable in the toolbar)
- **Inspector Width (%)**: 25-40% of the content area
- **Double-Click Copies Path**
- **C Key Copies Path** (Ctrl+C always works)
- **UI Snippet Format**: what **Copy UI Snippet** copies, a texture pass or a scenegraph node with a widget definition
- **Recent History**: a button that clears the recent history
- **Favorites**: a hold-to-confirm button that removes every favorite
- **Unloaded Icons**: a button that copies the paths of every indexed icon whose material is not loaded, one per line

**Window**

- **Window Size (%)**: 100% fills the screen above the input legend, smaller values shrink the frame
- **Window X Position** / **Window Y Position**: offsets of the frame, always kept on screen
- **Window Position**: a button that centres the frame again
- **Window Move Step**
- **Move Window Left** / **Right** / **Up** / **Down** keybinds

View mode, category, sort order and preview background are remembered automatically.

## Chat command

- `/icon_browser_unloaded` copies the paths of every indexed icon whose material is not loaded, one per line, and reports how many there are. These are the icons that draw as white squares. The command waits until the icon packages have loaded; run it again if it says they are still loading.

## Requirements

- **Darktide Mod Framework (DMF) 26.10.22 or newer.** Icon Browser loads its icon packages through DMF's package manager, provides its version and author through `info.json`, and uses the settings tabs and button widgets of current DMF releases. Older DMF versions cannot load it.

## Installation

Install it like a standard **Darktide Mod Framework (DMF)** mod:

1. Place the `IconBrowser` folder in your Darktide `mods` directory.
2. Make sure DMF 26.10.22 or newer is installed and working.
3. Enable the mod in your mod list.
4. Launch the game and use **F8** to open the browser.

Vortex installation is also possible!

## Notes and limitations

- Icon Browser is still **under development** and should be considered a work in progress.
- Some icons and UI graphics are currently **not displayed correctly** or may fail to render as expected. A material that is not loaded would draw as a white square. Icon Browser loads the packages of the views and HUD elements whose scripts use an indexed icon, the UI asset packages, and every indexed material the game ships as a package of its own (such as item HUD icons). The minion portraits (`icons/portraits/minion_portraits/`) only ship in the game's global enemy assets, which the game itself loads at the first loading screen and keeps for the whole session. Opened in the main menu before that, Icon Browser loads that package the way the game does (under the game's own `global` reference, not through DMF, so it is never released while the game needs it); the portraits show **LOADING...** until it has arrived, and the first loading screen then skips it. Icons that are still not loaded, for example those the current game version no longer ships, show **NOT AVAILABLE** in red.
- The engine does not expose a material's native texture size. The inspector shows the size the game draws an icon at where its scripts set one; otherwise the Auto aspect assumes a square, which you can change with the Aspect control.
- Source references and the index are generated from a snapshot of the game scripts and the backend items (currently Darktide 1.13.4, items version 139617). Icons the game names only at runtime, such as the scanner maps, have no references.
- Localized names exist only for icons the game's own definitions name; most assets show a name derived from their filename. The material path always stays the canonical identifier.
- Icon Browser is focused on **UI icon materials and related UI assets**.
- The browser works from an included index and loaded UI packages, so it is a targeted developer tool, not a full raw asset explorer for every game resource.
- Some assets may depend on package availability or game-side loading behavior.

## Regenerating the icon data

`IconIndex.lua` and `IconSources.lua` are generated by `tools/generate_icon_data.lua` (LuaJIT). After a game update, run it from the repository root against a decompiled source checkout such as [Aussiemon/Darktide-Source-Code](https://github.com/Aussiemon/Darktide-Source-Code), optionally with a master items export (made with [Master Items Export](https://www.nexusmods.com/warhammer40kdarktide/mods/822)) for the item HUD icons:

```text
luajit tools/generate_icon_data.lua --source <Darktide-Source-Code> [--master-items <master_items_export_*.lua>]
```

The index only grows: paths of the previous index stay, so icons the game builds at runtime are never dropped. The master items export is read line by line and never executed. `IconSources.lua` also lists the packages to load: the packages of the views and HUD elements whose scripts name an indexed icon, and the game's UI asset packages.

## Credits

Icon Browser was built with the help of these mods:
- [Package Logger](https://www.nexusmods.com/warhammer40kdarktide/mods/733)
- [Master Items Export](https://www.nexusmods.com/warhammer40kdarktide/mods/822) 
- [Localization Export](https://www.nexusmods.com/warhammer40kdarktide/mods/975)

Thanks to [GideonAriphael](https://www.nexusmods.com/warhammer40kdarktide/users/1992757) for their amazing work!

Similar mods I highly recommend to check out: 
- [malevhf](https://www.nexusmods.com/warhammer40kdarktide/users/61958461)
  - [Asset Viewer](https://www.nexusmods.com/warhammer40kdarktide/mods/1132)
  - [HUD Studio](https://www.nexusmods.com/warhammer40kdarktide/mods/1263)
- [indicabunny](https://www.nexusmods.com/warhammer40kdarktide/users/209632444)
  - [Icon Viewer](https://www.nexusmods.com/warhammer40kdarktide/mods/1185)

## Why this exists

Finding a suitable icon for a Darktide mod can be slow when you do not know the exact material path. Icon Browser shortens that workflow by giving modders an in-game reference tool, so you can discover icons faster and prototype UI work with less guesswork.

## Summary

**Icon Browser is a non-gameplay Darktide modding utility for browsing, previewing, copying, and logging UI icon asset paths for use in other mods.**
