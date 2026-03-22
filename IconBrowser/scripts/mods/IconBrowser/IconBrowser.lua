local mod = get_mod("IconBrowser")
local Views = require("scripts/ui/views/views")

local VIEW_NAME = "icon_browser_view"
local VIEW_PACKAGE = "packages/ui/views/system_view/system_view"
local PACKAGE_REF = "IconBrowser"
local VIEW_MODULE = "IconBrowser/scripts/mods/IconBrowser/icon_browser_view"
local ALT_VIEW_MODULE = "scripts/mods/IconBrowser/icon_browser_view"
local _icon_packages_loaded = false

local ICON_BROWSER_PACKAGES = {
    -- General UI, class, emote, profile-ish icons
    "packages/ui/views/main_menu_view/main_menu_view",
    "packages/ui/views/main_menu_background_view/main_menu_background_view",
    "packages/ui/views/character_appearance_view/character_appearance_view",
    "packages/ui/views/class_selection_view/class_selection_view",
    "packages/ui/views/options_view/options_view",
    "packages/ui/views/news_view/news_view",
    "packages/ui/views/system_view/system_view",

    -- The most important block, weapons, throwables, pocketables, many icon materials
    "packages/ui/views/inventory_view/inventory_view",
    "packages/ui/views/inventory_background_view/inventory_background_view",
    "packages/ui/views/inventory_weapons_view/inventory_weapons_view",
    "packages/ui/views/inventory_weapon_details_view/inventory_weapon_details_view",
    "packages/ui/views/inventory_weapon_marks_view/inventory_weapon_marks_view",
    "packages/ui/views/inventory_weapon_cosmetics_view/inventory_weapon_cosmetics_view",
    "packages/ui/views/cosmetics_inspect_view/cosmetics_inspect_view",
    "packages/ui/hud/player_weapon/player_weapon",

    -- Nameplates, portrait frames, some extra icon textures
    "packages/ui/views/loading_view/loading_screen_background",
    "packages/ui/views/player_character_options_view/player_character_options_view",
    "packages/ui/views/social_menu_view/social_menu_view",
    "packages/ui/views/social_menu_roster_view/social_menu_roster_view",

    -- Recommended spillover for trait, perk, mastery, crafting related icons
    "packages/ui/views/masteries_overview_view/masteries_overview_view",
    "packages/ui/views/mastery_view/mastery_view",
    "packages/ui/views/crafting_view/crafting_view",
    "packages/ui/views/crafting_mechanicus_upgrade_expertise_view/crafting_mechanicus_upgrade_expertise_view",
    "packages/ui/views/crafting_mechanicus_replace_trait_view/crafting_mechanicus_replace_trait_view",
    "packages/ui/views/crafting_mechanicus_replace_perk_view/crafting_mechanicus_replace_perk_view",

    -- Helps with some additional throwable and mission related icon assets
    "packages/ui/views/mission_intro_view/mission_intro_view",
}

local function _register_view_module_preload()
    if not package or not package.preload then
        return
    end

    local loader = function()
        if mod and mod.io_dofile then
            return mod:io_dofile(VIEW_MODULE)
        end

        return dofile("./../mods/" .. VIEW_MODULE .. ".lua")
    end

    if not package.preload[VIEW_MODULE] then
        package.preload[VIEW_MODULE] = loader
    end

    if not package.preload[ALT_VIEW_MODULE] then
        package.preload[ALT_VIEW_MODULE] = loader
    end
end

local function _register_view()
    _register_view_module_preload()

    if Views[VIEW_NAME] then
        return
    end

    Views[VIEW_NAME] = {
        name = VIEW_NAME,
        class = "IconBrowserView",
        display_name = "mod_name",
        path = VIEW_MODULE,
        package = VIEW_PACKAGE,
        state_bound = true,
        allow_hud = false,
        disable_game_world = false,
        game_world_blur = 0.8,
        use_transition_ui = false,
        close_on_hotkey_pressed = true,
    }
end

local function _load_icon_index()
    local ok, icons = pcall(function()
        if mod and mod.io_dofile then
            return mod:io_dofile("IconBrowser/scripts/mods/IconBrowser/IconIndex")
        end

        return require("IconBrowser/scripts/mods/IconBrowser/IconIndex")
    end)

    if ok and type(icons) == "table" then
        table.sort(icons)
        return icons
    end

    return {}
end

local function _ensure_icon_packages_loaded()
    if _icon_packages_loaded then
        return
    end

    if not Managers or not Managers.package then
        return
    end

    for _, pkg in ipairs(ICON_BROWSER_PACKAGES) do
        Managers.package:load(pkg, PACKAGE_REF, nil, true)
    end

    _icon_packages_loaded = true
end

local function _view_is_active()
    return Managers and Managers.ui and Managers.ui:view_active(VIEW_NAME)
end

_register_view()
mod._icon_paths = mod._icon_paths or _load_icon_index()
mod._icon_browser_view_open = mod._icon_browser_view_open or false

function mod.get_icon_paths()
    return mod._icon_paths or {}
end

function mod.open_icon_browser(...)
    _register_view()
    _ensure_icon_packages_loaded()

    if not Managers or not Managers.ui then
        return
    end

    if _view_is_active() then
        mod._icon_browser_view_open = true
        return
    end

    local ok = pcall(function()
        Managers.ui:open_view(VIEW_NAME)
    end)

    if ok then
        mod._icon_browser_view_open = true
    else
        mod._icon_browser_view_open = false
    end
end

function mod.close_icon_browser(...)
    if not Managers or not Managers.ui then
        return
    end

    if _view_is_active() then
        Managers.ui:close_view(VIEW_NAME)
    end

    mod._icon_browser_view_open = false
end

function mod.toggle_icon_browser(...)
    if _view_is_active() or mod._icon_browser_view_open then
        mod.close_icon_browser()
    else
        mod.open_icon_browser()
    end
end

function mod.on_setting_changed(_setting_id)
end

return mod
