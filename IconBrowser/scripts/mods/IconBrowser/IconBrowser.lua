local mod = get_mod("IconBrowser")
local Views = require("scripts/ui/views/views")

local floor = math.floor
local sort = table.sort

local VIEW_NAME = "icon_browser_view"
local VIEW_PACKAGE = "packages/ui/views/system_view/system_view"
local PACKAGE_REF = "IconBrowser"
local VIEW_MODULE = "IconBrowser/scripts/mods/IconBrowser/icon_browser_view"
local ALT_VIEW_MODULE = "scripts/mods/IconBrowser/icon_browser_view"
local ICON_INDEX_MODULE = "IconBrowser/scripts/mods/IconBrowser/IconIndex"
local _icon_packages_loaded = false

local DEFAULT_WINDOW_SCALE = 100
local DEFAULT_WINDOW_OFFSET_X = 0
local DEFAULT_WINDOW_OFFSET_Y = 0
local DEFAULT_MOVE_STEP = 10

local MIN_WINDOW_SCALE = 50
local MAX_WINDOW_SCALE = 200
local MIN_WINDOW_POSITION = -12000
local MAX_WINDOW_POSITION = 12000
local MIN_MOVE_STEP = 1
local MAX_MOVE_STEP = 200

local ICON_BROWSER_PACKAGES = {
    -- General UI, class, emote, profile-ish icons
    "packages/ui/views/main_menu_view/main_menu_view",
    "packages/ui/views/main_menu_background_view/main_menu_background_view",
    "packages/ui/views/character_appearance_view/character_appearance_view",
    "packages/ui/views/class_selection_view/class_selection_view",
    "packages/ui/views/options_view/options_view",
    "packages/ui/views/news_view/news_view",
    "packages/ui/views/system_view/system_view",

    -- Core inventory and inspection coverage, weapons, throwables, pocketables, many icon materials
    "packages/ui/views/inventory_view/inventory_view",
    "packages/ui/views/inventory_background_view/inventory_background_view",
    "packages/ui/views/inventory_weapons_view/inventory_weapons_view",
    "packages/ui/views/inventory_weapon_details_view/inventory_weapon_details_view",
    "packages/ui/views/inventory_weapon_marks_view/inventory_weapon_marks_view",
    "packages/ui/views/inventory_weapon_cosmetics_view/inventory_weapon_cosmetics_view",
    "packages/ui/views/cosmetics_inspect_view/cosmetics_inspect_view",
    "packages/ui/hud/player_weapon/player_weapon",

    -- Nameplates, portrait frames, and extra social/profile related icon textures
    "packages/ui/views/loading_view/loading_screen_background",
    "packages/ui/views/player_character_options_view/player_character_options_view",
    "packages/ui/views/social_menu_view/social_menu_view",
    "packages/ui/views/social_menu_roster_view/social_menu_roster_view",
    "packages/ui/views/end_player_view/end_player_view",
    "packages/ui/views/group_finder_view/group_finder_view",
    "packages/ui/ui_signin_assets",

    -- Talents, traits, perks, mastery, and other progression related icon sources
    "packages/ui/views/masteries_overview_view/masteries_overview_view",
    "packages/ui/views/mastery_view/mastery_view",
    "packages/ui/views/talent_builder_view/talent_builder_view",
    "packages/ui/views/penance_overview_view/penance_overview_view",

    -- Crafting, vendors, and generic item / slot / placeholder icon coverage
    "packages/ui/views/crafting_view/crafting_view",
    "packages/ui/views/crafting_mechanicus_upgrade_expertise_view/crafting_mechanicus_upgrade_expertise_view",
    "packages/ui/views/crafting_mechanicus_replace_trait_view/crafting_mechanicus_replace_trait_view",
    "packages/ui/views/crafting_mechanicus_replace_perk_view/crafting_mechanicus_replace_perk_view",
    "packages/ui/views/crafting_mechanicus_upgrade_item_view/crafting_mechanicus_upgrade_item_view",
    "packages/ui/views/crafting_mechanicus_barter_items_view/crafting_mechanicus_barter_items_view",
    "packages/ui/views/crafting_mechanicus_modify_view/crafting_mechanicus_modify_view",
    "packages/ui/views/store_item_detail_view/store_item_detail_view",
    "packages/ui/views/credits_goods_vendor_view/credits_goods_vendor_view",
    "packages/ui/views/credits_vendor_view/credits_vendor_view",
    "packages/ui/views/marks_goods_vendor_view/marks_goods_vendor_view",
    "packages/ui/views/marks_vendor_view/marks_vendor_view",
    "packages/ui/views/store_view/store_view",

    -- Appearance, cosmetics, barber, and customization category icons
    "packages/ui/views/inventory_cosmetics_view/inventory_cosmetics_view",
    "packages/ui/views/cosmetics_vendor_view/cosmetics_vendor_view",
    "packages/ui/views/barber_vendor_background_view/barber_vendor_background_view",

    -- Missions, events, contracts, and other world/board/currency related icon coverage
    "packages/ui/views/mission_intro_view/mission_intro_view",
    "packages/ui/views/mission_board_view/mission_board_view",
    "packages/ui/views/mission_voting_view/mission_voting_view",
    "packages/ui/views/scanner_display_view/scanner_display_view",
    "packages/ui/views/live_events_view/live_events_view",
    "packages/ui/views/contracts_view/contracts_view",
    "packages/ui/views/contracts_background_view/contracts_background_view",
    "packages/ui/views/havoc_play_view/havoc_play_view",
    "packages/ui/views/havoc_background_view/havoc_background_view",
    "packages/ui/views/broker_stimm_builder_view/broker_stimm_builder_view",
    "packages/ui/material_sets/circumstances",

    -- HUD packages for ability frames, buff frames, weapon flats, and other runtime icon materials
    "packages/ui/hud/team_player_panel/team_player_panel",
    "packages/ui/hud/tactical_overlay/tactical_overlay",
    "packages/ui/hud/world_markers/world_markers",
    "packages/ui/hud/emote_wheel/emote_wheel",
    "packages/ui/hud/wield_info/wield_info",
    "packages/ui/hud/boss_health/boss_health",
    "packages/ui/hud/player_ability/player_ability",
    "packages/ui/hud/overcharge/overcharge",
    "packages/ui/hud/weapon_counter/weapon_counter",
    "packages/ui/hud/smart_tagging/smart_tagging",
    "packages/ui/hud/player_buffs/player_buffs",
}

local function _clamp(value, min_value, max_value)
    if value < min_value then
        return min_value
    elseif value > max_value then
        return max_value
    end

    return value
end

local function _normalize_int(value, default_value, min_value, max_value)
    local numeric_value = floor(tonumber(value) or default_value)

    return _clamp(numeric_value, min_value, max_value)
end

local function _register_view_module_preload()
    local package_preload = package and package.preload

    if not package_preload then
        return
    end

    local loader = function()
        if mod and mod.io_dofile then
            return mod:io_dofile(VIEW_MODULE)
        end

        return dofile("./../mods/" .. VIEW_MODULE .. ".lua")
    end

    if not package_preload[VIEW_MODULE] then
        package_preload[VIEW_MODULE] = loader
    end

    if not package_preload[ALT_VIEW_MODULE] then
        package_preload[ALT_VIEW_MODULE] = loader
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
            return mod:io_dofile(ICON_INDEX_MODULE)
        end

        return require(ICON_INDEX_MODULE)
    end)

    if ok and type(icons) == "table" then
        sort(icons)
        return icons
    end

    return {}
end

local function _ensure_icon_packages_loaded()
    if _icon_packages_loaded then
        return
    end

    local managers = Managers
    local package_manager = managers and managers.package

    if not package_manager then
        return
    end

    for i = 1, #ICON_BROWSER_PACKAGES do
        package_manager:load(ICON_BROWSER_PACKAGES[i], PACKAGE_REF, nil, true)
    end

    _icon_packages_loaded = true
end

local function _view_is_active()
    local managers = Managers
    local ui_manager = managers and managers.ui

    return ui_manager and ui_manager:view_active(VIEW_NAME)
end

function mod.get_icon_browser_scale()
    return _normalize_int(mod:get("icon_browser_scale"), DEFAULT_WINDOW_SCALE, MIN_WINDOW_SCALE, MAX_WINDOW_SCALE)
end

function mod.get_icon_browser_offset_x()
    return _normalize_int(mod:get("icon_browser_pos_x"), DEFAULT_WINDOW_OFFSET_X, MIN_WINDOW_POSITION,
        MAX_WINDOW_POSITION)
end

function mod.get_icon_browser_offset_y()
    return _normalize_int(mod:get("icon_browser_pos_y"), DEFAULT_WINDOW_OFFSET_Y, MIN_WINDOW_POSITION,
        MAX_WINDOW_POSITION)
end

function mod.get_icon_browser_move_step()
    return _normalize_int(mod:get("icon_browser_move_step"), DEFAULT_MOVE_STEP, MIN_MOVE_STEP, MAX_MOVE_STEP)
end

function mod.set_icon_browser_scale(new_value)
    mod:set("icon_browser_scale", _normalize_int(new_value, DEFAULT_WINDOW_SCALE, MIN_WINDOW_SCALE, MAX_WINDOW_SCALE))
end

function mod.set_icon_browser_position(new_x, new_y)
    if new_x ~= nil then
        mod:set("icon_browser_pos_x",
            _normalize_int(new_x, DEFAULT_WINDOW_OFFSET_X, MIN_WINDOW_POSITION, MAX_WINDOW_POSITION))
    end

    if new_y ~= nil then
        mod:set("icon_browser_pos_y",
            _normalize_int(new_y, DEFAULT_WINDOW_OFFSET_Y, MIN_WINDOW_POSITION, MAX_WINDOW_POSITION))
    end
end

function mod.set_icon_browser_move_step(new_value)
    mod:set("icon_browser_move_step", _normalize_int(new_value, DEFAULT_MOVE_STEP, MIN_MOVE_STEP, MAX_MOVE_STEP))
end

function mod.move_icon_browser_left(...)
    local move_step = mod.get_icon_browser_move_step()
    mod.set_icon_browser_position(mod.get_icon_browser_offset_x() - move_step, nil)
end

function mod.move_icon_browser_right(...)
    local move_step = mod.get_icon_browser_move_step()
    mod.set_icon_browser_position(mod.get_icon_browser_offset_x() + move_step, nil)
end

function mod.move_icon_browser_up(...)
    local move_step = mod.get_icon_browser_move_step()
    mod.set_icon_browser_position(nil, mod.get_icon_browser_offset_y() - move_step)
end

function mod.move_icon_browser_down(...)
    local move_step = mod.get_icon_browser_move_step()
    mod.set_icon_browser_position(nil, mod.get_icon_browser_offset_y() + move_step)
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

    local managers = Managers
    local ui_manager = managers and managers.ui

    if not ui_manager then
        return
    end

    if ui_manager:view_active(VIEW_NAME) then
        mod._icon_browser_view_open = true
        return
    end

    ui_manager:open_view(VIEW_NAME)
    mod._icon_browser_view_open = true
end

function mod.close_icon_browser(...)
    local managers = Managers
    local ui_manager = managers and managers.ui

    if not ui_manager then
        return
    end

    if ui_manager:view_active(VIEW_NAME) then
        ui_manager:close_view(VIEW_NAME)
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
