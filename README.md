# Icon Browser

Developer utility mod for **Warhammer 40,000: Darktide**.

> [!IMPORTANT]
> **This is not a gameplay mod.**
> Icon Browser is a development and modding tool meant to help mod authors inspect UI icon materials and asset paths inside Darktide. It does not add combat features, progression changes, quality-of-life gameplay advantages, or balance changes.

## What it does

Icon Browser opens an in-game browser window that lets you inspect a large indexed set of Darktide UI icon materials. Each row shows:

- the icon preview
- its numeric ID inside the browser
- the full material path

When you click an entry, the mod copies that icon path to your clipboard, shows an in-game confirmation, and echoes the selection in a developer-friendly format, for example:

```text
[IconBrowser] #110 content/ui/materials/icons/abilities/frames/background
```

That makes it easier to find a usable icon path and copy it into your own mod.

## Features

- In-game icon browser window for Darktide UI materials
- Preview, ID, and full asset path shown in a single list
- Click any row to copy the icon path to your clipboard
- In-game confirmation when a path is copied
- Chat/log output for copied icon IDs and paths
- Default hotkey to open and close the browser: **F8**
- Adjustable window size
- Adjustable window X and Y position
- Configurable movement step size
- Optional keybinds to move the window up, down, left, and right
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

1. Open the browser in-game.
2. Scroll through the indexed icons.
3. Click an icon that looks suitable for your mod.
4. Paste the copied asset path into your own Lua/UI code.
5. Use the echoed ID and path if you also want a quick log reference.

## Configuration

The mod includes configurable options for:

- **Open Icon Browser** keybind
- **Window Size (%)**
- **Window X Position**
- **Window Y Position**
- **Window Move Step**
- **Move Window Left** keybind
- **Move Window Right** keybind
- **Move Window Up** keybind
- **Move Window Down** keybind

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
- Icon Browser is focused on **UI icon materials and related UI assets**.
- The browser works from an included index and loaded UI packages, so it is a targeted developer tool, not a full raw asset explorer for every game resource.
- Some assets may depend on package availability or game-side loading behavior.

## Why this exists

Finding a suitable icon for a Darktide mod can be slow when you do not know the exact material path. Icon Browser shortens that workflow by giving modders an in-game reference tool, so you can discover icons faster and prototype UI work with less guesswork.

## Summary

**Icon Browser is a non-gameplay Darktide modding utility for browsing, previewing, copying, and logging UI icon asset paths for use in other mods.**
