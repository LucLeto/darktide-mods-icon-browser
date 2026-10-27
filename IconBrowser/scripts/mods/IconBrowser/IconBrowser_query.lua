--- Search, filter and sort of Icon Browser.
-- Sort orders are built lazily once per sort and cached; descending orders are the reversed ascending
-- ones, and orders that depend on names are rebuilt after the asset model resolved localized names.
-- A query run walks the active order once and writes the matching assets into a caller-owned array, so
-- the view only runs it when the search text, a filter or the sort changed, never per frame.
--
-- Search is case-insensitive substring matching of every whitespace-separated term (all terms must
-- match) against the asset's search text; a term with underscores or hyphens also matches with them
-- read as spaces.
--
-- Loaded through `mod:io_dofile` by `IconBrowser.lua` and stored as `mod._query_module`.
-- module: IconBrowser_query
-- author: LucLeto
local find = string.find
local gmatch = string.gmatch
local gsub = string.gsub
local lower = string.lower
local sort = table.sort

local Query = {}

Query.CATEGORY_ALL = "all"
Query.DEFAULT_SORT = "index_asc"

--- Sort options in menu order; `key` names the comparator, `ascending` the matching ascending order.
Query.SORTS = {
    { id = "name_asc", key = "name" },
    { id = "name_desc", key = "name", ascending = "name_asc" },
    { id = "path_asc", key = "path" },
    { id = "path_desc", key = "path", ascending = "path_asc" },
    { id = "category_asc", key = "category" },
    { id = "category_desc", key = "category", ascending = "category_asc" },
    { id = "index_asc", key = "index" },
    { id = "index_desc", key = "index", ascending = "index_asc" },
}

local SORT_BY_ID = {}

for i = 1, #Query.SORTS do
    local sort_option = Query.SORTS[i]

    SORT_BY_ID[sort_option.id] = sort_option
end

--- Sorts whose order depends on (localized) names, rebuilt when the names change.
local NAME_DEPENDENT_SORTS = { "name_asc", "name_desc", "category_asc", "category_desc" }

local COMPARATORS = {
    name = function(a, b)
        local a_name, b_name = a.sort_name, b.sort_name

        if a_name ~= b_name then
            return a_name < b_name
        end

        return a.id < b.id
    end,
    path = function(a, b)
        return a.path < b.path
    end,
    category = function(a, b)
        local a_label, b_label = a.category_label, b.category_label

        if a_label ~= b_label then
            return a_label < b_label
        end

        local a_name, b_name = a.sort_name, b.sort_name

        if a_name ~= b_name then
            return a_name < b_name
        end

        return a.id < b.id
    end,
    index = function(a, b)
        return a.id < b.id
    end,
}

function Query.is_valid_sort(sort_id)
    return SORT_BY_ID[sort_id] ~= nil
end

--- Sort id for a list column header: ascending first, a second click on the same column descends.
function Query.toggle_sort(current_sort_id, key)
    local ascending_id = key .. "_asc"

    if current_sort_id == ascending_id then
        return key .. "_desc"
    end

    return ascending_id
end

function Query.sort_key(sort_id)
    local sort_option = SORT_BY_ID[sort_id]

    return sort_option and sort_option.key
end

function Query.is_descending(sort_id)
    local sort_option = SORT_BY_ID[sort_id]

    return sort_option ~= nil and sort_option.ascending ~= nil
end

function Query.new_cache()
    return {
        orders = {},
        names_revision = -1,
    }
end

--- Returns the cached asset order for a sort id, building it on first use.
function Query.order(cache, assets, sort_id)
    local orders = cache.orders

    if cache.names_revision ~= assets.names_revision then
        for i = 1, #NAME_DEPENDENT_SORTS do
            orders[NAME_DEPENDENT_SORTS[i]] = nil
        end

        cache.names_revision = assets.names_revision
    end

    local sort_option = SORT_BY_ID[sort_id] or SORT_BY_ID[Query.DEFAULT_SORT]
    local order = orders[sort_option.id]

    if order then
        return order
    end

    local count = assets.count

    order = {}

    if sort_option.ascending then
        local ascending_order = Query.order(cache, assets, sort_option.ascending)

        for i = 1, count do
            order[i] = ascending_order[count - i + 1]
        end
    else
        local list = assets.list

        for i = 1, count do
            order[i] = list[i]
        end

        if sort_option.key ~= "index" then
            sort(order, COMPARATORS[sort_option.key])
        end
    end

    orders[sort_option.id] = order

    return order
end

function Query.new_state()
    return {
        text = "",
        terms = {},
        normalized_terms = {},
        term_count = 0,
        category = Query.CATEGORY_ALL,
        favorites_only = false,
        recent_only = false,
        sort = Query.DEFAULT_SORT,
    }
end

--- Parses the search text into terms; returns false when the text did not change.
function Query.set_text(state, text)
    text = text or ""

    if text == state.text then
        return false
    end

    state.text = text

    local terms = state.terms
    local normalized_terms = state.normalized_terms
    local previous_count = state.term_count
    local count = 0

    for term in gmatch(lower(text), "%S+") do
        local normalized = gsub(term, "[_%-]+", " ")

        count = count + 1
        terms[count] = term
        normalized_terms[count] = normalized ~= term and normalized or false
    end

    for i = count + 1, previous_count do
        terms[i] = nil
        normalized_terms[i] = nil
    end

    state.term_count = count

    return true
end

--- Writes the assets matching `state` into `results` in sort order; returns the match count.
-- `favorites` and `recent` are path lookups; `previous_count` is the count of the last run, so stale
-- entries past the new count are cleared without measuring the array.
function Query.run(state, assets, cache, favorites, recent, results, previous_count)
    local order = Query.order(cache, assets, state.sort)
    local category = state.category
    local filter_category = category ~= Query.CATEGORY_ALL
    local favorites_only = state.favorites_only
    local recent_only = state.recent_only
    local terms = state.terms
    local normalized_terms = state.normalized_terms
    local term_count = state.term_count
    local count = 0

    for i = 1, assets.count do
        local asset = order[i]
        local keep = (not filter_category or asset.category == category)
            and (not favorites_only or favorites[asset.path] == true)
            and (not recent_only or recent[asset.path] ~= nil)

        if keep and term_count > 0 then
            local blob = asset.search_blob

            for t = 1, term_count do
                if not find(blob, terms[t], 1, true) then
                    local normalized = normalized_terms[t]

                    if not normalized or not find(blob, normalized, 1, true) then
                        keep = false

                        break
                    end
                end
            end
        end

        if keep then
            count = count + 1
            results[count] = asset
        end
    end

    for i = count + 1, previous_count or 0 do
        results[i] = nil
    end

    return count
end

return Query
