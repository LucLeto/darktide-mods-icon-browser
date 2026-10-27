local mod = get_mod("IconBrowser")
local Views = require("scripts/ui/views/views")

local floor = math.floor
local sort = table.sort
local format = string.format
local table_insert = table.insert
local table_remove = table.remove

local VIEW_NAME = "icon_browser_view"
local VIEW_PACKAGE = "packages/ui/views/system_view/system_view"
local PACKAGE_REF = "IconBrowser"
local VIEW_MODULE = "IconBrowser/scripts/mods/IconBrowser/icon_browser_view"
local ALT_VIEW_MODULE = "scripts/mods/IconBrowser/icon_browser_view"
local ICON_INDEX_MODULE = "IconBrowser/scripts/mods/IconBrowser/IconIndex"
local ASSETS_MODULE = "IconBrowser/scripts/mods/IconBrowser/IconBrowser_assets"
local QUERY_MODULE = "IconBrowser/scripts/mods/IconBrowser/IconBrowser_query"
local LOCALIZATION_MODULE = "IconBrowser/scripts/mods/IconBrowser/IconBrowser_localization"
local _requested_icon_packages = {}

local DEFAULT_WINDOW_SCALE = 100
local DEFAULT_WINDOW_OFFSET_X = 0
local DEFAULT_WINDOW_OFFSET_Y = 0
local DEFAULT_MOVE_STEP = 10

-- 100 % is the near-full-screen frame; larger saved values from the fixed-size window clamp to it.
local MIN_WINDOW_SCALE = 50
local MAX_WINDOW_SCALE = 100
local MIN_WINDOW_POSITION = -12000
local MAX_WINDOW_POSITION = 12000
local MIN_MOVE_STEP = 1
local MAX_MOVE_STEP = 200

local DEFAULT_INSPECTOR_WIDTH = 28
local MIN_INSPECTOR_WIDTH = 25
local MAX_INSPECTOR_WIDTH = 40

local FAVORITES_SETTING = "icon_browser_favorites"
local RECENT_SETTING = "icon_browser_recent"
local MAX_RECENT_ICONS = 30

local DENSITIES = { compact = true, normal = true, large = true }
local DEFAULT_DENSITY = "normal"
local VIEW_MODES = { grid = true, list = true }
local DEFAULT_VIEW_MODE = "grid"
local PREVIEW_BACKGROUNDS = { dark = true, light = true, checker = true }
local DEFAULT_PREVIEW_BACKGROUND = "dark"
local DEFAULT_CATEGORY = "all"
local DEFAULT_SORT = "index_asc"

local ICON_BROWSER_PACKAGES = {
    -- Core menu and profile surfaces, broad UI atlas coverage
    "packages/ui/views/main_menu_view/main_menu_view",
    "packages/ui/views/main_menu_background_view/main_menu_background_view",
    "packages/ui/views/character_appearance_view/character_appearance_view",
    "packages/ui/views/class_selection_view/class_selection_view",
    "packages/ui/views/options_view/options_view",
    "packages/ui/views/news_view/news_view",
    "packages/ui/views/system_view/system_view",
    "packages/ui/views/loading_view/loading_screen_background",
    "packages/ui/views/loading_view/loading_view",
    "packages/ui/views/player_character_options_view/player_character_options_view",
    "packages/ui/views/social_menu_view/social_menu_view",
    "packages/ui/views/social_menu_roster_view/social_menu_roster_view",
    "packages/ui/views/group_finder_view/group_finder_view",
    "packages/ui/views/lobby_view/lobby_view",
    "packages/ui/views/report_player_view/report_player_view",
    "packages/ui/views/video_view/video_view",
    "packages/ui/views/splash_view/splash_view",
    "packages/ui/ui_signin_assets",

    -- Inventory, weapon, and generic item icon sources
    "packages/ui/views/inventory_view/inventory_view",
    "packages/ui/views/inventory_background_view/inventory_background_view",
    "packages/ui/views/inventory_weapons_view/inventory_weapons_view",
    "packages/ui/views/inventory_weapon_details_view/inventory_weapon_details_view",
    "packages/ui/views/inventory_weapon_marks_view/inventory_weapon_marks_view",
    "packages/ui/views/inventory_weapon_cosmetics_view/inventory_weapon_cosmetics_view",
    "packages/ui/views/inventory_cosmetics_view/inventory_cosmetics_view",
    "packages/ui/views/cosmetics_inspect_view/cosmetics_inspect_view",
    "packages/ui/views/store_item_detail_view/store_item_detail_view",
    "packages/ui/hud/player_weapon/player_weapon",
    "packages/ui/hud/wield_info/wield_info",
    "packages/ui/hud/weapon_counter/weapon_counter",

    -- Mastery, talent, crafting, and generic item-type placeholders
    "packages/ui/views/masteries_overview_view/masteries_overview_view",
    "packages/ui/views/mastery_view/mastery_view",
    "packages/ui/views/talent_builder_view/talent_builder_view",
    "packages/ui/views/crafting_view/crafting_view",
    "packages/ui/views/crafting_mechanicus_upgrade_expertise_view/crafting_mechanicus_upgrade_expertise_view",
    "packages/ui/views/crafting_mechanicus_replace_trait_view/crafting_mechanicus_replace_trait_view",
    "packages/ui/views/crafting_mechanicus_replace_perk_view/crafting_mechanicus_replace_perk_view",
    "packages/ui/views/crafting_mechanicus_upgrade_item_view/crafting_mechanicus_upgrade_item_view",
    "packages/ui/views/crafting_mechanicus_barter_items_view/crafting_mechanicus_barter_items_view",
    "packages/ui/views/crafting_mechanicus_modify_view/crafting_mechanicus_modify_view",

    -- Vendors, store, currencies, cosmetics, and appearance-related icons
    "packages/ui/views/credits_goods_vendor_view/credits_goods_vendor_view",
    "packages/ui/views/credits_vendor_view/credits_vendor_view",
    "packages/ui/views/credits_vendor_background_view/credits_vendor_background_view",
    "packages/ui/views/marks_goods_vendor_view/marks_goods_vendor_view",
    "packages/ui/views/marks_vendor_view/marks_vendor_view",
    "packages/ui/views/store_view/store_view",
    "packages/ui/views/cosmetics_vendor_view/cosmetics_vendor_view",
    "packages/ui/views/cosmetics_vendor_background_view/cosmetics_vendor_background_view",
    "packages/ui/views/barber_vendor_background_view/barber_vendor_background_view",
    "packages/ui/views/broker_stimm_builder_view/broker_stimm_builder_view",
    "packages/ui/views/live_events_view/live_events_view",
    "packages/ui/views/penance_overview_view/penance_overview_view",
    "packages/ui/material_sets/circumstances",

    -- Mission, contracts, havoc, and player-journey icon families
    "packages/ui/views/mission_intro_view/mission_intro_view",
    "packages/ui/views/mission_board_view/mission_board_view",
    "packages/ui/views/mission_voting_view/mission_voting_view",
    "packages/ui/views/contracts_view/contracts_view",
    "packages/ui/views/contracts_background_view/contracts_background_view",
    "packages/ui/views/scanner_display_view/scanner_display_view",
    "packages/ui/views/havoc_reward_presentation_view/havoc_reward_presentation_view",
    "packages/ui/views/havoc_play_view/havoc_play_view",
    "packages/ui/views/havoc_background_view/havoc_background_view",
    "packages/ui/views/expedition_play_view/expedition_play_view",
    "packages/ui/views/expedition_background_view/expedition_background_view",
    "packages/ui/views/expedition_view/expedition_view",
    "packages/ui/views/horde_play_view/horde_play_view",
    "packages/ui/views/training_grounds_options_view/training_grounds_options_view",
    "packages/ui/views/training_grounds_view/training_grounds_view",
    "packages/ui/views/end_player_view/end_player_view",

    -- HUD packages that commonly carry ability, buff, frame, and flat icon materials
    "packages/ui/hud/team_player_panel/team_player_panel",
    "packages/ui/hud/crosshair/crosshair",
    "packages/ui/hud/tactical_overlay/tactical_overlay",
    "packages/ui/hud/mission_objective_feed/mission_objective_feed",
    "packages/ui/hud/mission_objective_popup/mission_objective_popup",
    "packages/ui/hud/objective_progress_bar/objective_progress_bar",
    "packages/ui/hud/onboarding_popup/onboarding_popup",
    "packages/ui/hud/area_notification_popup/area_notification_popup",
    "packages/ui/hud/mission_speaker_popup/mission_speaker_popup",
    "packages/ui/hud/world_markers/world_markers",
    "packages/ui/hud/interaction/interaction",
    "packages/ui/hud/emote_wheel/emote_wheel",
    "packages/ui/hud/boss_health/boss_health",
    "packages/ui/hud/player_ability/player_ability",
    "packages/ui/hud/damage_indicator/damage_indicator",
    "packages/ui/hud/blocking/blocking",
    "packages/ui/hud/dodge_counter/dodge_counter",
    "packages/ui/hud/overcharge/overcharge",
    "packages/ui/hud/smart_tagging/smart_tagging",
    "packages/ui/hud/prologue_tutorial_step_tracker/prologue_tutorial_step_tracker",
    "packages/ui/hud/prologue_tutorial_info_box/prologue_tutorial_info_box",
    "packages/ui/hud/player_buffs/player_buffs",
}

local ICON_BROWSER_LEVEL_PACKAGES = {
    -- Inventory and itemization levels, often pull extra material dependencies
    "content/levels/ui/inventory/inventory",
    "content/levels/ui/inventory_weapon_view/inventory_weapon_view",
    "content/levels/ui/crafting_view_itemization/crafting_view_itemization",
    "content/levels/ui/crafting_view_sacrifice/world",
    "content/levels/ui/store/store",
    "content/levels/ui/credits_vendor/credits_vendor",
    "content/levels/ui/vendor_cosmetics_preview_gear/vendor_cosmetics_preview_gear",
    "content/levels/ui/vendor_cosmetics_preview_weapon/vendor_cosmetics_preview_weapon",
    "content/levels/ui/credits_cosmetics_vendor/credits_cosmetics_vendor",

    -- Mission and event levels, useful for mission-type and event currency icons
    "content/levels/ui/mission_intro/mission_intro",
    "content/levels/ui/mission_board_player_journey/mission_board_player_journey",
    "content/levels/ui/contracts_view/contracts_view",
    "content/levels/ui/havoc/havoc",
    "content/levels/ui/penances/world",
    "content/levels/ui/training_grounds/training_grounds",

    -- Barber and appearance levels, useful for hair/appearance icon families
    "content/levels/ui/barber/barber",
    "content/levels/ui/barber_character_appearance/barber_character_appearance",
    "content/levels/ui/barber_character_mindwipe/barber_character_mindwipe",
    "content/levels/ui/character_create/character_create",
    "content/levels/ui/cartel_selection/cartel_selection",

    -- Expedition player-journey level, used by mission_types_pj icon families
    "content/levels/ui/expedition/world",
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

local function _bump_layout_revision()
    mod._layout_revision = (mod._layout_revision or 0) + 1
end

local function _dofile_module(module_path)
    if mod and mod.io_dofile then
        return mod:io_dofile(module_path)
    end

    return require(module_path)
end

local function _load_module(module_path)
    local ok, module = pcall(_dofile_module, module_path)

    if ok and type(module) == "table" then
        return module
    end

    mod:echo(format("[IconBrowser] Failed to load %s (%s)", module_path, tostring(module)))

    return nil
end

local function _emit_user_message(message, prefer_notification)
    mod:echo(message)

    if not Mods or not Mods.message then
        return
    end

    if prefer_notification and Mods.message.notify then
        Mods.message.notify(message)
    elseif Mods.message.echo then
        Mods.message.echo(message)
    end
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

local function _package_is_available(package_name)
    local application = Application

    if not application or not application.can_get_resource then
        return false
    end

    local ok, exists = pcall(function()
        return application.can_get_resource("package", package_name)
    end)

    return ok and exists or false
end

local function _package_is_loaded(package_name)
    local managers = Managers
    local package_manager = managers and managers.package

    if not package_manager or not package_manager.has_loaded then
        return false
    end

    local ok, is_loaded = pcall(package_manager.has_loaded, package_manager, package_name)

    return ok and is_loaded or false
end

local function _load_package_list(package_list)
    local managers = Managers
    local package_manager = managers and managers.package

    if not package_manager then
        return
    end

    for _, pkg in ipairs(package_list) do
        if _package_is_available(pkg) and not _requested_icon_packages[pkg] then
            if _package_is_loaded(pkg) then
                _requested_icon_packages[pkg] = true
            else
                local ok = pcall(function()
                    package_manager:load(pkg, PACKAGE_REF, nil, true)
                end)

                if ok then
                    _requested_icon_packages[pkg] = true
                end
            end
        end
    end
end

local function _all_packages_loaded(package_list)
    for _, pkg in ipairs(package_list) do
        if _package_is_available(pkg) and not _package_is_loaded(pkg) then
            return false
        end
    end

    return true
end

local function _ensure_icon_packages_loaded()
    local managers = Managers
    local package_manager = managers and managers.package

    if not package_manager then
        return false
    end

    _load_package_list(ICON_BROWSER_PACKAGES)
    _load_package_list(ICON_BROWSER_LEVEL_PACKAGES)

    return _all_packages_loaded(ICON_BROWSER_PACKAGES) and _all_packages_loaded(ICON_BROWSER_LEVEL_PACKAGES)
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
    _bump_layout_revision()
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

    _bump_layout_revision()
end

function mod.set_icon_browser_move_step(new_value)
    mod:set("icon_browser_move_step", _normalize_int(new_value, DEFAULT_MOVE_STEP, MIN_MOVE_STEP, MAX_MOVE_STEP))
end

function mod.get_icon_browser_inspector_width()
    return _normalize_int(mod:get("icon_browser_inspector_width"), DEFAULT_INSPECTOR_WIDTH, MIN_INSPECTOR_WIDTH,
        MAX_INSPECTOR_WIDTH)
end

function mod.get_icon_browser_density()
    local density = mod:get("icon_browser_density")

    return DENSITIES[density] and density or DEFAULT_DENSITY
end

function mod.set_icon_browser_density(density)
    if DENSITIES[density] then
        mod:set("icon_browser_density", density)
        _bump_layout_revision()
    end
end

function mod.get_icon_browser_view_mode()
    local view_mode = mod:get("icon_browser_view_mode")

    return VIEW_MODES[view_mode] and view_mode or DEFAULT_VIEW_MODE
end

function mod.set_icon_browser_view_mode(view_mode)
    if VIEW_MODES[view_mode] then
        mod:set("icon_browser_view_mode", view_mode)
        _bump_layout_revision()
    end
end

function mod.get_icon_browser_category()
    local category = mod:get("icon_browser_category")
    local assets = mod._assets

    if type(category) == "string" and assets and assets.category_counts[category] then
        return category
    end

    return DEFAULT_CATEGORY
end

function mod.set_icon_browser_category(category)
    local assets = mod._assets

    if type(category) == "string" and assets and assets.category_counts[category] then
        mod:set("icon_browser_category", category)
    end
end

function mod.get_icon_browser_sort()
    local sort_id = mod:get("icon_browser_sort")
    local query_module = mod._query_module

    if query_module and query_module.is_valid_sort(sort_id) then
        return sort_id
    end

    return DEFAULT_SORT
end

function mod.set_icon_browser_sort(sort_id)
    local query_module = mod._query_module

    if query_module and query_module.is_valid_sort(sort_id) then
        mod:set("icon_browser_sort", sort_id)
    end
end

function mod.get_icon_browser_preview_background()
    local background = mod:get("icon_browser_preview_background")

    return PREVIEW_BACKGROUNDS[background] and background or DEFAULT_PREVIEW_BACKGROUND
end

function mod.set_icon_browser_preview_background(background)
    if PREVIEW_BACKGROUNDS[background] then
        mod:set("icon_browser_preview_background", background)
    end
end

function mod.is_icon_browser_double_click_copy_enabled()
    return mod:get("icon_browser_double_click_copy") ~= false
end

function mod.is_icon_browser_copy_hotkey_enabled()
    return mod:get("icon_browser_copy_hotkey") ~= false
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

--- Reads a persisted path list into a dense array and a path lookup, dropping invalid and duplicate
-- entries so a damaged setting can never produce a mixed table on the next save.
local function _load_path_list(setting_id, limit)
    local value = mod:get(setting_id)
    local list = {}
    local lookup = {}
    local count = 0

    if type(value) == "table" then
        for i = 1, #value do
            local path = value[i]

            if type(path) == "string" and path ~= "" and not lookup[path] then
                count = count + 1
                list[count] = path
                lookup[path] = true

                if limit and count >= limit then
                    break
                end
            end
        end
    end

    return list, lookup, count
end

--- The fixed-size window allowed up to 200 %; 100 % is now the full-screen frame, so larger saved
-- values are written back as 100 and the options slider shows the value actually used.
local function _migrate_settings()
    local scale = mod:get("icon_browser_scale")

    if type(scale) == "number" and scale > MAX_WINDOW_SCALE then
        mod:set("icon_browser_scale", MAX_WINDOW_SCALE)
    end
end

local function _register_global_localization()
    if not mod.add_global_localize_strings then
        return
    end

    local ok, localization = pcall(_dofile_module, LOCALIZATION_MODULE)

    if not ok or type(localization) ~= "table" then
        return
    end

    mod:add_global_localize_strings({
        loc_icon_browser_legend_select = localization.legend_select,
        loc_icon_browser_legend_copy_path = localization.legend_copy_path,
        loc_icon_browser_legend_favorite = localization.legend_favorite,
    })
end

_register_view()
mod._icon_paths = mod._icon_paths or _load_icon_index()
mod._icon_browser_view_open = mod._icon_browser_view_open or false
mod._icon_render_failures = mod._icon_render_failures or {}
mod._layout_revision = mod._layout_revision or 0
mod._icon_lists_revision = mod._icon_lists_revision or 0
mod._icon_browser_session = mod._icon_browser_session or {
    query = "",
    selected_path = false,
    favorites_only = false,
    recent_only = false,
}

mod._assets_module = _load_module(ASSETS_MODULE)
mod._query_module = _load_module(QUERY_MODULE)
mod._assets = mod._assets_module and mod._assets_module.build(mod._icon_paths, mod)
mod._favorite_icons, mod._favorite_lookup, mod._favorite_count = _load_path_list(FAVORITES_SETTING)
mod._recent_icons, mod._recent_lookup, mod._recent_count = _load_path_list(RECENT_SETTING, MAX_RECENT_ICONS)
_migrate_settings()
_register_global_localization()

function mod.get_icon_paths()
    return mod._icon_paths or {}
end

function mod.get_icon_assets()
    return mod._assets
end

function mod.is_icon_favorite(path)
    return mod._favorite_lookup[path] == true
end

--- Adds or removes a favorite by full path; returns whether the path is a favorite afterwards.
function mod.toggle_icon_favorite(path)
    if type(path) ~= "string" or path == "" then
        return false
    end

    local list = mod._favorite_icons
    local lookup = mod._favorite_lookup
    local count = mod._favorite_count
    local is_favorite

    if lookup[path] then
        for i = 1, count do
            if list[i] == path then
                table_remove(list, i)
                break
            end
        end

        lookup[path] = nil
        mod._favorite_count = count - 1
        is_favorite = false
    else
        count = count + 1
        list[count] = path
        lookup[path] = true
        mod._favorite_count = count
        is_favorite = true
    end

    mod:set(FAVORITES_SETTING, list)
    mod._icon_lists_revision = mod._icon_lists_revision + 1
    mod._icon_lists_dirty = true

    return is_favorite
end

--- Moves a path to the front of the recent history, keeping at most `MAX_RECENT_ICONS` entries.
function mod.record_recent_icon(path)
    if type(path) ~= "string" or path == "" then
        return
    end

    local list = mod._recent_icons

    if list[1] == path then
        return
    end

    local lookup = mod._recent_lookup
    local count = mod._recent_count

    if lookup[path] then
        for i = 1, count do
            if list[i] == path then
                table_remove(list, i)
                count = count - 1
                break
            end
        end
    end

    table_insert(list, 1, path)
    lookup[path] = true
    count = count + 1

    if count > MAX_RECENT_ICONS then
        lookup[list[count]] = nil
        list[count] = nil
        count = MAX_RECENT_ICONS
    end

    mod._recent_count = count
    mod:set(RECENT_SETTING, list)
    mod._icon_lists_revision = mod._icon_lists_revision + 1
    mod._icon_lists_dirty = true
end

function mod.clear_recent_icons()
    local list = mod._recent_icons
    local lookup = mod._recent_lookup

    for i = mod._recent_count, 1, -1 do
        lookup[list[i]] = nil
        list[i] = nil
    end

    mod._recent_count = 0
    mod:set(RECENT_SETTING, list)
    mod._icon_lists_revision = mod._icon_lists_revision + 1
    mod._icon_lists_dirty = true
end

--- DMF writes settings to disk only on game state changes; favorites and history changed in the
-- browser are written when it closes, so a crash later in the session cannot lose them.
function mod.save_icon_lists_if_dirty()
    if not mod._icon_lists_dirty then
        return
    end

    mod._icon_lists_dirty = false

    local dmf = get_mod("DMF")
    local save_settings = dmf and dmf.save_unsaved_settings_to_file

    if type(save_settings) == "function" then
        pcall(save_settings)
    end
end

function mod.can_render_icon_path(path)
    return type(path) == "string" and path ~= "" and not mod._icon_render_failures[path]
end

function mod.mark_icon_render_failed(path, error_message)
    if type(path) ~= "string" or path == "" then
        return
    end

    local failures = mod._icon_render_failures

    if failures[path] then
        return
    end

    failures[path] = true

    local message = format("[IconBrowser] Failed to render icon preview: %s", path)

    if error_message and error_message ~= "" then
        message = format("%s (%s)", message, tostring(error_message))
    end

    _emit_user_message(message, false)
end

function mod.copy_icon_path_to_clipboard(icon_id, path)
    if type(path) ~= "string" or path == "" then
        local message = "[IconBrowser] Unable to copy icon path."

        _emit_user_message(message, true)

        return false, "Copy failed"
    end

    local clipboard = Clipboard
    local clipboard_put = clipboard and clipboard.put

    if type(clipboard_put) ~= "function" then
        local message = format("[IconBrowser] Clipboard unavailable for #%d %s", icon_id or 0, path)

        _emit_user_message(message, true)

        return false, "Clipboard unavailable"
    end

    local ok, copied = pcall(clipboard_put, path)

    if ok and copied ~= false then
        local message = format("[IconBrowser] Copied #%d %s", icon_id or 0, path)

        _emit_user_message(message, true)

        return true, "Copied path to clipboard"
    end

    local message = format("[IconBrowser] Failed to copy #%d %s", icon_id or 0, path)

    _emit_user_message(message, true)

    return false, "Copy failed"
end

--- Copies a value derived from an icon (filename, Lua string, UI snippet). The chat message names the
-- copied format and the icon path instead of echoing a possibly multi-line value.
function mod.copy_icon_text_to_clipboard(icon_id, text, format_label, path)
    format_label = format_label or "value"
    path = path or ""

    if type(text) ~= "string" or text == "" then
        _emit_user_message(format("[IconBrowser] Unable to copy %s.", format_label), true)

        return false
    end

    local clipboard = Clipboard
    local clipboard_put = clipboard and clipboard.put

    if type(clipboard_put) ~= "function" then
        _emit_user_message(format("[IconBrowser] Clipboard unavailable for %s of #%d %s", format_label, icon_id or 0,
            path), true)

        return false
    end

    local ok, copied = pcall(clipboard_put, text)

    if ok and copied ~= false then
        _emit_user_message(format("[IconBrowser] Copied %s of #%d %s", format_label, icon_id or 0, path), true)

        return true
    end

    _emit_user_message(format("[IconBrowser] Failed to copy %s of #%d %s", format_label, icon_id or 0, path), true)

    return false
end

local function _open_icon_browser_view()
    local managers = Managers
    local ui_manager = managers and managers.ui

    if not ui_manager then
        return false
    end

    if ui_manager:view_active(VIEW_NAME) then
        mod._icon_browser_view_open = true
        return true
    end

    ui_manager:open_view(VIEW_NAME)
    mod._icon_browser_view_open = true

    return true
end

function mod.on_all_mods_loaded()
    _ensure_icon_packages_loaded()
end

function mod.update(dt)
    if mod._pending_icon_browser_open and _ensure_icon_packages_loaded() then
        mod._pending_icon_browser_open = false
        mod._icon_browser_loading_notified = false
        _open_icon_browser_view()
    end
end

function mod.open_icon_browser(...)
    _register_view()

    if not _ensure_icon_packages_loaded() then
        mod._pending_icon_browser_open = true

        if not mod._icon_browser_loading_notified then
            local message = "[IconBrowser] Loading icon packages..."
            _emit_user_message(message, false)

            mod._icon_browser_loading_notified = true
        end

        return
    end

    mod._pending_icon_browser_open = false
    mod._icon_browser_loading_notified = false
    _open_icon_browser_view()
end

function mod.close_icon_browser(...)
    local managers = Managers
    local ui_manager = managers and managers.ui

    mod._pending_icon_browser_open = false
    mod._icon_browser_loading_notified = false

    if not ui_manager then
        return
    end

    if ui_manager:view_active(VIEW_NAME) then
        ui_manager:close_view(VIEW_NAME)
    end

    mod._icon_browser_view_open = false
end

function mod.toggle_icon_browser(...)
    if _view_is_active() or mod._icon_browser_view_open or mod._pending_icon_browser_open then
        mod.close_icon_browser()
    else
        mod.open_icon_browser()
    end
end

function mod.on_setting_changed(_setting_id)
    _bump_layout_revision()
end

return mod
