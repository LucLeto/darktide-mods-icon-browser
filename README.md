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

Selecting an asset never touches the clipboard. Copying is explicit: use **Copy Material Path**, double-click an asset, or press **Ctrl+C** / **C**. Every copy shows an in-game confirmation and echoes a developer-friendly line, for example:

```text
[IconBrowser] Copied #110 content/ui/materials/icons/abilities/frames/background
```

## Features

- Near-full-screen layout that adapts to resolution, aspect ratio (including ultrawide) and UI scale, and stays clear of the input legend
- Terminal look taken from the game: dark green panels, olive frames, sage text and gold selection highlights
- Case-insensitive search over the material path, filename, readable name, localized name and browser ID; multiple terms, partial matches, underscores and hyphens read as spaces
- Categories derived from the material path, from Abilities to Backgrounds; anything unmatched stays visible under Other
- Sorting by name, resource path, category or browser index, ascending or descending; list column headers sort on click
- Grid view with automatic columns and compact / normal / large thumbnails, and a compact list view; both share search, filters, sorting and selection
- Inspector with a large preview (dark, light or checkerboard background, zoom, selectable display aspect), the full wrapped material path, filename, browser ID, category, name source and preview status
- Copy actions: material path, filename, Lua string and a ready-to-use Lua UI texture pass snippet
- Favorites and a recent-assets history (selected or copied), both saved by full material path between sessions
- Localized names where the game's own definitions name an icon (mission types, circumstances, currencies, difficulty levels, classes, item types, crafting recipes); other assets get a readable name derived from the filename
- Hover tooltip with the complete material path
- Keyboard support: **Ctrl+F** search, arrow keys navigate, **Enter** selects, **Ctrl+C** / **C** copies the path, **F** toggles the favorite, **Esc** leaves the search field or closes the browser
- Previews that fail to render show a fallback, are reported once, and stay searchable and copyable
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

The mod includes configurable options for:

- **Open Icon Browser** keybind
- **Window Size (%)**: 100% fills the screen above the input legend, smaller values shrink the frame
- **Window X Position** / **Window Y Position**: offsets of the frame, always kept on screen
- **Window Move Step**
- **Move Window Left** / **Right** / **Up** / **Down** keybinds
- **Inspector Width (%)**: 25-40% of the content area
- **Thumbnail Density**: compact, normal or large (also switchable in the toolbar)
- **Double-Click Copies Path**
- **C Key Copies Path** (Ctrl+C always works)

View mode, category, sort order and preview background are remembered automatically.

## Installation

Install it like a standard **Darktide Mod Framework (DMF)** mod:

1. Place the `IconBrowser` folder in your Darktide `mods` directory.
2. Make sure DMF is installed and working.
3. Enable the mod in your mod list.
4. Launch the game and use **F8** to open the browser.

Vortex installation is also possible!

## Notes and limitations

- Icon Browser is still **under development** and should be considered a work in progress.
- Some icons and UI graphics are currently **not displayed correctly** or may fail to render as expected.
- The engine does not expose a material's native texture size, so the inspector shows no dimensions; the preview assumes a square aspect, which you can change with the Aspect control.
- Localized names exist only for icons the game's own definitions name; most assets show a name derived from their filename. The material path always stays the canonical identifier.
- Icon Browser is focused on **UI icon materials and related UI assets**.
- The browser works from an included index and loaded UI packages, so it is a targeted developer tool, not a full raw asset explorer for every game resource.
- Some assets may depend on package availability or game-side loading behavior.

## Why this exists

Finding a suitable icon for a Darktide mod can be slow when you do not know the exact material path. Icon Browser shortens that workflow by giving modders an in-game reference tool, so you can discover icons faster and prototype UI work with less guesswork.

## Summary

**Icon Browser is a non-gameplay Darktide modding utility for browsing, previewing, copying, and logging UI icon asset paths for use in other mods.**
