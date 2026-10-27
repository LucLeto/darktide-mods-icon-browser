--- Asset model of Icon Browser; one canonical record per indexed material path.
-- Built once from the sorted icon index: the browser ID stays the index position, the full path stays
-- the canonical identifier, and every derived field (readable name, category, search text) is computed
-- here so the grid, the list and the inspector all read the same record.
--
-- Localized names are resolved later, on the first open of the view, from game definition tables that
-- pair a UI material with a localization key; only keys the localization manager reports as existing
-- are used, so no name is guessed.
--
-- Loaded through `mod:io_dofile` by `IconBrowser.lua` and stored as `mod._assets_module`.
-- module: IconBrowser_assets
-- author: LucLeto
local find = string.find
local format = string.format
local gsub = string.gsub
local lower = string.lower
local match = string.match
local sub = string.sub
local upper = string.upper
local pairs = pairs
local pcall = pcall
local sort = table.sort
local tostring = tostring
local type = type

local Assets = {}

local MATERIAL_ROOT = "content/ui/materials/"
local MATERIAL_ROOT_LENGTH = #MATERIAL_ROOT

Assets.NAME_SOURCE_LOCALIZED = "localized"
Assets.NAME_SOURCE_DEFINITION = "definition"
Assets.NAME_SOURCE_FILENAME = "filename"

--- Path categories, matched in order against the path below `content/ui/materials/`; the first match
-- wins and anything unmatched falls into `other`, so no asset is ever hidden by categorisation.
-- `all` is the pseudo category of the filter and owns no prefixes.
Assets.CATEGORIES = {
    { id = "all" },
    { id = "abilities", prefixes = { "icons/abilities/" } },
    { id = "talents", prefixes = { "icons/talents/", "icons/traits/", "icons/perks/" } },
    {
        id = "weapons",
        prefixes = { "icons/weapons/", "icons/throwables/", "icons/pocketables/", "icons/pickups/" },
    },
    { id = "hud", prefixes = { "hud/", "icons/hud/", "icons/player_states/" } },
    { id = "buffs", prefixes = { "icons/buffs/" } },
    {
        id = "classes",
        prefixes = {
            "icons/classes/", "icons/class_badges/", "icons/portraits/", "icons/npc_portraits/",
            "icons/character_creator/", "icons/appearances/",
        },
    },
    {
        id = "inventory",
        prefixes = {
            "icons/items/", "icons/item_types/", "icons/crafting/", "icons/currencies/", "icons/cosmetics/",
            "icons/engrams/", "icons/presets/", "icons/offer_cards/", "icons/categories/", "icons/list_buttons/",
        },
    },
    {
        id = "missions",
        prefixes = {
            "icons/mission_types/", "icons/mission_types_pj/", "icons/mission_type/", "icons/objectives/",
            "icons/difficulty/", "icons/mission_difficulty_complete/", "icons/circumstances/", "icons/contracts/",
        },
    },
    { id = "backgrounds", prefixes = { "backgrounds/" } },
    { id = "other" },
}

local CATEGORY_ALL = "all"
local CATEGORY_OTHER = "other"

local UI_SNIPPET_FORMAT = [[{
    pass_type = "texture",
    style_id = "icon",
    value = "%s",
    style = {
        horizontal_alignment = "center",
        vertical_alignment = "center",
        size = { 64, 64 },
        color = { 255, 255, 255, 255 },
    },
},]]

local function _capitalize(first, rest)
    return upper(first) .. rest
end

local function _humanize(text)
    text = gsub(text, "[_%-]+", " ")
    text = gsub(text, "^%s+", "")
    text = gsub(text, "%s+$", "")

    return (gsub(text, "(%a)(%w*)", _capitalize))
end

local function _relative_path(path)
    if sub(path, 1, MATERIAL_ROOT_LENGTH) == MATERIAL_ROOT then
        return sub(path, MATERIAL_ROOT_LENGTH + 1)
    end

    return path
end

local function _category_of(relative_path)
    local categories = Assets.CATEGORIES

    for i = 1, #categories do
        local prefixes = categories[i].prefixes

        if prefixes then
            for j = 1, #prefixes do
                if find(relative_path, prefixes[j], 1, true) == 1 then
                    return categories[i].id
                end
            end
        end
    end

    return CATEGORY_OTHER
end

local function _search_blob(asset, localized_name, definition_name)
    local lower_path = lower(asset.path)

    return lower_path
        .. "|" .. gsub(lower_path, "[_%-/]", " ")
        .. "|" .. lower(asset.readable_name)
        .. "|" .. lower(localized_name or "")
        .. "|" .. lower(definition_name or "")
        .. "|" .. asset.id_text
        .. "|"
end

--- Builds the asset model from the sorted path list; `mod` localizes the category labels.
function Assets.build(paths, mod)
    local count = #paths
    local list = {}
    local by_path = {}
    local filename_counts = {}
    local category_counts = {}
    local category_labels = {}
    local categories = Assets.CATEGORIES

    for i = 1, #categories do
        local id = categories[i].id

        category_counts[id] = 0
        category_labels[id] = mod:localize("category_" .. id)
    end

    for i = 1, count do
        local filename = match(paths[i], "([^/]+)$") or paths[i]

        filename_counts[filename] = (filename_counts[filename] or 0) + 1
    end

    for i = 1, count do
        local path = paths[i]
        local relative_path = _relative_path(path)
        local directory = match(relative_path, "^(.*)/[^/]+$") or ""
        local filename = match(path, "([^/]+)$") or path
        local readable_name = _humanize(filename)

        if filename_counts[filename] > 1 then
            local parent = match(directory, "([^/]+)$")

            if parent then
                readable_name = _humanize(parent) .. " " .. readable_name
            end
        end

        if readable_name == "" then
            readable_name = filename
        end

        local category = _category_of(relative_path)
        local asset = {
            id = i,
            id_text = "#" .. i,
            path = path,
            filename = filename,
            directory = directory,
            readable_name = readable_name,
            display_name = readable_name,
            sort_name = lower(readable_name),
            name_source = Assets.NAME_SOURCE_FILENAME,
            name_key = false,
            name_origin = false,
            name_uses = 0,
            category = category,
            category_label = category_labels[category],
            search_blob = "",
            lua_string = false,
            ui_snippet = false,
        }

        asset.search_blob = _search_blob(asset, nil, nil)
        list[i] = asset
        by_path[path] = asset
        category_counts[category] = category_counts[category] + 1
    end

    category_counts[CATEGORY_ALL] = count

    return {
        list = list,
        count = count,
        by_path = by_path,
        category_counts = category_counts,
        category_labels = category_labels,
        names_revision = 0,
        names_resolved = false,
    }
end

-- ----------------------------------------------------------------------------
-- Localized names
-- ----------------------------------------------------------------------------

local function _collect_mission_types(data, add)
    for key, entry in pairs(data) do
        if type(entry) == "table" then
            add(entry.icon, entry.name, "mission_types", key)
            add(entry.mission_board_icon, entry.name, "mission_types", key)
        end
    end
end

local function _collect_circumstances(data, add)
    for key, entry in pairs(data) do
        local ui = type(entry) == "table" and entry.ui

        if type(ui) == "table" then
            add(ui.icon, ui.display_name, "circumstance_templates", key)
            add(ui.mission_board_icon, ui.display_name, "circumstance_templates", key)
        end
    end
end

local function _collect_wallets(data, add)
    for key, entry in pairs(data) do
        if type(entry) == "table" then
            add(entry.icon_texture_big, entry.display_name, "wallet_settings", key)
            add(entry.icon_texture_small, entry.display_name, "wallet_settings", key)
        end
    end
end

local function _collect_danger_levels(data, add)
    local danger_levels = data.danger_levels

    if type(danger_levels) ~= "table" then
        return
    end

    for i = 1, #danger_levels do
        local entry = danger_levels[i]

        if type(entry) == "table" then
            add(entry.icon, entry.display_name, "danger_settings", entry.name or tostring(i))
            add(entry.digital_icon, entry.display_name, "danger_settings", entry.name or tostring(i))
        end
    end
end

local ARCHETYPE_ICON_FIELDS = {
    "archetype_icon_large",
    "archetype_icon_selection_large",
    "archetype_icon_selection_large_unselected",
    "archetype_background_large",
    "archetype_badge",
}

local function _collect_archetypes(data, add)
    for key, entry in pairs(data) do
        if type(entry) == "table" then
            for i = 1, #ARCHETYPE_ICON_FIELDS do
                add(entry[ARCHETYPE_ICON_FIELDS[i]], entry.archetype_name, "archetypes", key)
            end
        end
    end
end

local function _collect_ui_settings(data, add)
    local materials = data.item_type_material_lookup
    local names = data.item_type_localization_lookup

    if type(materials) == "table" and type(names) == "table" then
        for key, material in pairs(materials) do
            add(material, names[key], "item_types", key)
        end
    end

    materials = data.texture_by_store_category
    names = data.display_name_by_store_category

    if type(materials) == "table" and type(names) == "table" then
        for key, material in pairs(materials) do
            add(material, names[key], "store_categories", key)
        end
    end
end

local function _collect_recipes(data, add)
    local recipes = data.recipes

    if type(recipes) ~= "table" then
        return
    end

    for key, entry in pairs(recipes) do
        if type(entry) == "table" then
            add(entry.icon, entry.display_name, "crafting_recipes", key)
        end
    end
end

--- Game definitions that pair a UI material with a localization key. Talent, buff and weapon templates
-- are left out on purpose: their icons are textures or shared placeholders, so names would mislead.
local NAME_SOURCES = {
    { module = "scripts/settings/mission/mission_types", collect = _collect_mission_types },
    { module = "scripts/settings/circumstance/circumstance_templates", collect = _collect_circumstances },
    { module = "scripts/settings/wallet_settings", collect = _collect_wallets },
    { module = "scripts/settings/difficulty/danger_settings", collect = _collect_danger_levels },
    { module = "scripts/settings/archetype/archetypes", collect = _collect_archetypes },
    { module = "scripts/settings/ui/ui_settings", collect = _collect_ui_settings },
    { module = "scripts/settings/item/crafting_settings", collect = _collect_recipes },
    { module = "scripts/settings/item/crafting_mechanicus_settings", collect = _collect_recipes },
}

local function _localize_key(key)
    if type(key) ~= "string" or sub(key, 1, 4) ~= "loc_" then
        return nil
    end

    local managers = Managers
    local localization_manager = managers and managers.localization

    if not localization_manager or not localization_manager.exists then
        return nil
    end

    local ok, exists = pcall(localization_manager.exists, localization_manager, key)

    if not ok or not exists then
        return nil
    end

    local localized_ok, text = pcall(Localize, key)

    if localized_ok and type(text) == "string" and text ~= "" and sub(text, 1, 1) ~= "<" then
        return text
    end

    return nil
end

local function _compare_candidates(a, b)
    return a.origin < b.origin
end

--- Resolves verified names once; safe to call repeatedly. Returns the number of named assets.
function Assets.resolve_names(assets)
    if assets.names_resolved then
        return 0
    end

    assets.names_resolved = true

    local by_path = assets.by_path
    local candidates = {}
    local add = function(material, loc_key, source, key)
        if type(material) ~= "string" then
            return
        end

        local path = gsub(material, "%.material$", "")

        if not by_path[path] then
            return
        end

        local list = candidates[path]

        if not list then
            list = {}
            candidates[path] = list
        end

        list[#list + 1] = {
            loc_key = loc_key,
            key = tostring(key),
            origin = source .. "." .. tostring(key),
        }
    end

    for i = 1, #NAME_SOURCES do
        local source = NAME_SOURCES[i]
        local ok, data = pcall(require, source.module)

        if ok and type(data) == "table" then
            pcall(source.collect, data, add)
        end
    end

    local named = 0

    for path, list in pairs(candidates) do
        local asset = by_path[path]

        sort(list, _compare_candidates)

        local localized_name, definition_name
        local chosen = list[1]

        for i = 1, #list do
            localized_name = _localize_key(list[i].loc_key)

            if localized_name then
                chosen = list[i]
                break
            end
        end

        if localized_name then
            asset.display_name = localized_name
            asset.name_source = Assets.NAME_SOURCE_LOCALIZED
            asset.name_key = chosen.loc_key
        else
            definition_name = _humanize(chosen.key)

            if definition_name ~= "" then
                asset.display_name = definition_name
                asset.name_source = Assets.NAME_SOURCE_DEFINITION
            end
        end

        asset.name_origin = chosen.origin
        asset.name_uses = #list - 1
        asset.sort_name = lower(asset.display_name)
        asset.search_blob = _search_blob(asset, localized_name, definition_name or _humanize(chosen.key))
        named = named + 1
    end

    assets.names_revision = assets.names_revision + 1

    return named
end

-- ----------------------------------------------------------------------------
-- Copy formats
-- ----------------------------------------------------------------------------

function Assets.lua_string(asset)
    local text = asset.lua_string

    if not text then
        text = '"' .. asset.path .. '"'
        asset.lua_string = text
    end

    return text
end

function Assets.ui_snippet(asset)
    local text = asset.ui_snippet

    if not text then
        text = format(UI_SNIPPET_FORMAT, asset.path)
        asset.ui_snippet = text
    end

    return text
end

return Assets
