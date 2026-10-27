--- Generator of Icon Browser's icon index and source references; a LuaJIT command line tool.
-- Scans the Lua scripts of a decompiled Darktide source checkout (such as
-- https://github.com/Aussiemon/Darktide-Source-Code) for UI material string literals and, optionally,
-- a master items export for the `hud_icon` materials of the backend items. Writes two generated
-- modules next to the mod scripts:
--
-- `IconIndex.lua` every path below `content/ui/materials/icons/`, `hud/interactions/` and
-- `backgrounds/scanner/` that the scripts name or an item uses as its `hud_icon`, plus every path of
-- the previous index, which keeps paths the game builds at runtime (such as the scanner maps); the
-- index only grows, so a game update never silently removes an icon.
--
-- `IconSources.lua` for every indexed path: each script line that names it (`refs`, as
-- `scripts/...lua:line`), the sizes it is drawn at where the enclosing definition sets a numeric
-- `size` (`sizes`, most frequent first), and the items that use it as `hud_icon` (`items`, as
-- `{ item name, display name localization key }`).
--
-- Normalization: trailing .material/.png/.dds/.tga are stripped and format-template strings
-- containing % are skipped. Every list is sorted, so regenerating unchanged inputs yields identical
-- files.
--
-- Usage, from the repository root:
--   luajit tools/generate_icon_data.lua --source <Darktide-Source-Code>
--       [--master-items <master_items_export_*.lua>] [--game-version <x.y.z>] [--mod <mod scripts dir>]
-- The master items export is read line by line and never executed. Without `--game-version` the
-- version is taken from the source checkout's last commit message when it names one.
-- module: generate_icon_data
-- author: LucLeto
local concat = table.concat
local format = string.format
local sort = table.sort

-- ----------------------------------------------------------------------------
-- Constants
-- ----------------------------------------------------------------------------

--- Path families the index holds, below `content/ui/materials/`.
local INDEXED_PREFIXES = {
    "content/ui/materials/icons/",
    "content/ui/materials/hud/interactions/",
    "content/ui/materials/backgrounds/scanner/",
}

--- Largest table, in lines above and below a reference, searched for a `size` field.
local MAX_LINES_UP = 80
local MAX_LINES_DOWN = 160

--- Sizes outside this range are not drawing sizes.
local MAX_USAGE_SIZE = 4096

--- Fewest `/` in a script folder that owns a package, as in `scripts/ui/views/inventory_view/`.
local MIN_OWNER_FOLDER_DEPTH = 4

local IS_WINDOWS = package.config:sub(1, 1) == "\\"

-- ----------------------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------------------

--- Prints a message to stderr and exits with a failure code.
-- string: message error text
local function _fail(message)
    io.stderr:write("generate_icon_data: ", message, "\n")
    os.exit(1)
end

--- Parses `--name value` pairs.
-- tab: argv command line arguments
-- treturn: tab options by name
local function _parse_arguments(argv)
    local options = {}
    local i = 1

    while i <= #argv do
        local name = argv[i]:match("^%-%-(.+)$")

        if not name or argv[i + 1] == nil then
            _fail("expected --name value pairs, got " .. tostring(argv[i]))
        end

        options[name] = argv[i + 1]
        i = i + 2
    end

    return options
end

--- Normalizes path separators to `/` and drops a trailing one.
-- string: path file system path
-- treturn: string
local function _unix_path(path)
    return (path:gsub("\\", "/"):gsub("/$", ""))
end

--- Lists the `.lua` files below a directory, sorted.
-- string: directory directory to list
-- treturn: tab array of full paths with `/` separators
local function _list_lua_files(directory)
    local command

    if IS_WINDOWS then
        command = format('dir /s /b /a-d "%s\\*.lua" 2>nul', (directory:gsub("/", "\\")))
    else
        command = format("find '%s' -type f -name '*.lua' 2>/dev/null", directory)
    end

    local pipe = assert(io.popen(command))
    local files = {}

    for line in pipe:lines() do
        files[#files + 1] = _unix_path(line)
    end

    pipe:close()
    sort(files)

    return files
end

--- Strips a trailing texture or material extension.
-- string: path material path
-- treturn: string
local function _normalize(path)
    return (path:gsub("%.material$", ""):gsub("%.png$", ""):gsub("%.dds$", ""):gsub("%.tga$", ""))
end

--- Returns whether a material literal is a complete path rather than part of one: format templates
-- (containing %), directory or name prefixes (ending in / or _) and literals the code joins with
-- `..` are built into a path at runtime, so they name no material themselves.
-- string: literal material literal
-- string: rest source line after the literal's closing quote
-- treturn: bool
local function _is_complete_path(literal, rest)
    return not literal:find("%", 1, true) and not literal:find("[/_]$") and not rest:find("^%s*%.%.")
end

--- Returns whether a path belongs to one of the indexed families.
-- string: path material path
-- treturn: bool
local function _is_indexed_family(path)
    for i = 1, #INDEXED_PREFIXES do
        local prefix = INDEXED_PREFIXES[i]

        if path:sub(1, #prefix) == prefix then
            return true
        end
    end

    return false
end

--- Returns the entry of a path in the material table, creating it on first use.
-- tab: materials entries by path
-- string: path material path
-- treturn: tab
local function _entry(materials, path)
    local entry = materials[path]

    if not entry then
        entry = { refs = {}, size_counts = {}, items = {}, packages = {} }
        materials[path] = entry
    end

    return entry
end

--- Writes a file with `\n` line endings.
-- string: path file to write
-- tab: lines array of lines
local function _write_lines(path, lines)
    local file = assert(io.open(path, "wb"))

    file:write(concat(lines, "\n"), "\n")
    file:close()
end

--- Quotes a string as a Lua literal.
-- string: text text to quote
-- treturn: string
local function _quote(text)
    return format("%q", text)
end

-- ----------------------------------------------------------------------------
-- Usage sizes
-- ----------------------------------------------------------------------------

--- Counts the braces of a line outside string literals and comments.
-- string: line source line
-- treturn: int opening braces
-- treturn: int closing braces
local function _braces(line)
    local code = line:gsub('"[^"]*"', ""):gsub("%-%-.*$", "")
    local _, opens = code:gsub("{", "")
    local _, closes = code:gsub("}", "")

    return opens, closes
end

--- Reads a two-number `size` field starting at a line, in one line or over the next two.
-- tab: lines source lines
-- int: index line of the `size =` key
-- treturn: ?number width
-- treturn: ?number height
local function _read_size(lines, index)
    local line = lines[index]
    local width, height = line:match("%f[%w_]size = {%s*(%-?[%d%.]+),%s*(%-?[%d%.]+),?%s*}")

    if width then
        return tonumber(width), tonumber(height)
    end

    if not line:match("%f[%w_]size = {%s*$") then
        return nil
    end

    width = lines[index + 1] and lines[index + 1]:match("^%s*(%-?[%d%.]+),?%s*$")
    height = lines[index + 2] and lines[index + 2]:match("^%s*(%-?[%d%.]+),?%s*$")

    return tonumber(width), tonumber(height)
end

--- Returns the line range of the table that encloses a line: the line that opens it, found by
-- walking up, and the line that closes it, found by walking down.
-- tab: lines source lines
-- int: index line inside the table
-- treturn: ?int first line, nil when no table opens within `MAX_LINES_UP`
-- treturn: ?int last line, capped at `MAX_LINES_DOWN` below the first
local function _enclosing_table(lines, index)
    local depth = 0
    local start

    for i = index - 1, math.max(1, index - MAX_LINES_UP), -1 do
        local opens, closes = _braces(lines[i])

        depth = depth + closes - opens

        if depth < 0 then
            start = i
            break
        end
    end

    if not start then
        return nil
    end

    local last = math.min(#lines, start + MAX_LINES_DOWN)

    depth = 0

    for i = start, last do
        local opens, closes = _braces(lines[i])

        depth = depth + opens - closes

        if depth <= 0 and i > start then
            return start, i
        end
    end

    return start, last
end

--- Returns the drawing size set by the table that encloses a reference, as `WxH`.
-- Takes the first numeric `size = { w, h }` inside the enclosing table, nested tables included;
-- this finds the `style.size` of a texture pass whose `value` is the material.
-- tab: lines source lines
-- int: reference line index
-- treturn: ?string
local function _usage_size(lines, reference)
    local start, last = _enclosing_table(lines, reference)

    if not start then
        return nil
    end

    for i = start, last do
        local width, height = _read_size(lines, i)

        if width and height and width > 0 and height > 0 and width <= MAX_USAGE_SIZE and height <= MAX_USAGE_SIZE then
            return format("%dx%d", math.floor(width + 0.5), math.floor(height + 0.5))
        end
    end

    return nil
end

--- Records the package a view or HUD element declares for the folder of its script.
-- Called for a `package = "packages/..."` line; the enclosing table's `path` or `filename` names the
-- element's script, and every script in that folder and below is taken to draw from the package.
-- tab: lines source lines
-- int: index line of the `package` field
-- string: package_name declared package
-- tab: owner_packages sets of package names by folder (`scripts/.../`)
local function _record_owner_package(lines, index, package_name, owner_packages)
    local start, last = _enclosing_table(lines, index)

    if not start then
        return
    end

    for i = start, last do
        local script = lines[i]:match('^%s*path = "(scripts/[^"]+)"') or lines[i]:match('^%s*filename = "(scripts/[^"]+)"')
        local folder = script and script:match("^(.*/)[^/]+$")

        -- a folder like `scripts/ui/views/` would claim every view; owners sit at least one level deeper
        if folder and select(2, folder:gsub("/", "")) >= MIN_OWNER_FOLDER_DEPTH then
            local packages = owner_packages[folder]

            if not packages then
                packages = {}
                owner_packages[folder] = packages
            end

            packages[package_name] = true
        end
    end
end

--- Returns the packages declared for the folder of a script or the nearest folder above it.
-- string: file script path relative to the source root
-- tab: owner_packages sets of package names by folder
-- treturn: ?tab set of package names
local function _owner_packages_of(file, owner_packages)
    local folder = file:match("^(.*/)[^/]+$")

    while folder and select(2, folder:gsub("/", "")) >= MIN_OWNER_FOLDER_DEPTH do
        local packages = owner_packages[folder]

        if packages then
            return packages
        end

        folder = folder:match("^(.*/)[^/]+/$")
    end

    return nil
end

-- ----------------------------------------------------------------------------
-- Inputs
-- ----------------------------------------------------------------------------

--- Scans every script for material literals and package declarations; records references, usage
-- sizes, the packages views and HUD elements declare for their script folders, and every UI asset
-- package (`packages/..._ui_assets`, such as the live event artwork) the scripts name.
-- string: source_root Darktide source checkout
-- tab: materials entries by path
-- tab: index_candidates set of paths to add to the index
-- tab: owner_packages sets of package names by script folder, filled here
-- tab: ui_asset_packages set of UI asset package names, filled here
-- treturn: int number of scanned files
local function _scan_scripts(source_root, materials, index_candidates, owner_packages, ui_asset_packages)
    local files = _list_lua_files(source_root .. "/scripts")

    if #files == 0 then
        _fail("no Lua files below " .. source_root .. "/scripts")
    end

    for f = 1, #files do
        local file_path = files[f]
        -- `dir` lists absolute paths, so the root may be spelled differently from `--source`
        local relative_path = file_path:match("^.-/(scripts/.+)$") or file_path
        local lines = {}

        for line in io.lines(file_path) do
            lines[#lines + 1] = (line:gsub("\r$", ""))
        end

        for index = 1, #lines do
            local line = lines[index]
            local package_name = line:match('^%s*package = "(packages/[^"]+)"')

            if package_name then
                _record_owner_package(lines, index, package_name, owner_packages)
            end

            for ui_assets_package in line:gmatch('"(packages/[^"]-_ui_assets)"') do
                ui_asset_packages[ui_assets_package] = true
            end

            if line:find("content/ui/materials/", 1, true) then
                for literal, after in line:gmatch('"(content/ui/materials/[^"]+)"()') do
                    if _is_complete_path(literal, line:sub(after)) then
                        local path = _normalize(literal)
                        local entry = _entry(materials, path)

                        entry.refs[#entry.refs + 1] = format("%s:%d", relative_path, index)

                        local size = _usage_size(lines, index)

                        if size then
                            entry.size_counts[size] = (entry.size_counts[size] or 0) + 1
                        end

                        if _is_indexed_family(path) then
                            index_candidates[path] = true
                        end
                    end
                end
            end
        end
    end

    return #files
end

--- Reads the `hud_icon` and `display_name` of every item in a master items export, line by line.
-- tab: export_path export file
-- tab: materials entries by path
-- tab: index_candidates set of paths to add to the index
-- treturn: ?string the export's items version
-- treturn: int number of items with a UI material `hud_icon`
local function _scan_master_items(export_path, materials, index_candidates)
    local current
    local version
    local count = 0

    local function flush()
        local hud_icon = current and current.hud_icon

        if hud_icon and hud_icon:sub(1, 21) == "content/ui/materials/" then
            local path = _normalize(hud_icon)
            local entry = _entry(materials, path)

            entry.items[#entry.items + 1] = { current.name, current.display_name or "" }
            count = count + 1

            if _is_indexed_family(path) then
                index_candidates[path] = true
            end
        end

        current = nil
    end

    for line in io.lines(export_path) do
        local item_name = line:match('^        %["(content/items/[^"]+)"%] = {')

        if item_name then
            flush()
            current = { name = item_name }
        elseif current then
            local key, value = line:match('^            ([%w_]+) = "(.-) %(string%)",?%s*$')

            if key == "hud_icon" or key == "display_name" then
                current[key] = value
            end
        end

        version = version or line:match('^%s*cached_version = "(%d+) %(string%)"')
    end

    flush()

    return version, count
end

--- Reads the paths of an existing index module, without running it.
-- string: index_path existing `IconIndex.lua`
-- treturn: tab array of paths
local function _read_previous_index(index_path)
    local file = io.open(index_path, "rb")
    local paths = {}

    if not file then
        return paths
    end

    for path in file:read("*a"):gmatch('\n%s*"(content/ui/materials/[^"]+)",') do
        paths[#paths + 1] = path
    end

    file:close()

    return paths
end

--- Takes the game version from the source checkout's last commit message, if it names one.
-- string: source_root Darktide source checkout
-- treturn: string
local function _detect_game_version(source_root)
    local pipe = io.popen(format('git -C "%s" log -1 --format=%%s 2>%s', source_root, IS_WINDOWS and "nul" or
        "/dev/null"))
    local subject = pipe and pipe:read("*l") or ""

    if pipe then
        pipe:close()
    end

    return subject and subject:match("(%d+%.%d+%.%d+)") or "unknown"
end

-- ----------------------------------------------------------------------------
-- Output
-- ----------------------------------------------------------------------------

--- Writes the generated `IconIndex.lua`.
-- string: path output file
-- tab: paths sorted array of paths
-- tab: info `game_version` and `items_version`
local function _write_index(path, paths, info)
    local lines = {
        "--- Generated index of the UI material paths Icon Browser can show.",
        "-- Generated by `tools/generate_icon_data.lua` from the Darktide " .. info.game_version .. " source scripts",
        "-- and master items version " .. info.items_version .. "; do not edit by hand.",
        "-- Normalization: stripped trailing .material/.png/.dds/.tga and skipped format-template strings",
        "-- containing %. Holds every path below `content/ui/materials/icons/`, `hud/interactions/` and",
        "-- `backgrounds/scanner/` that the scripts name or an item uses as its `hud_icon`, and every path of",
        "-- the previous index, which keeps paths the game builds at runtime (such as the scanner maps).",
        "--",
        "-- Returns an array of full material paths. `IconBrowser.lua` loads it through `mod:io_dofile`,",
        "-- sorts it and stores it as `mod._icon_paths`; a path's browser ID is its position in the sorted",
        "-- array, and the asset model in `IconBrowser_assets.lua` is built from it.",
        "-- module: IconIndex",
        "-- author: LucLeto",
        "return {",
    }

    for i = 1, #paths do
        lines[#lines + 1] = "    " .. _quote(paths[i]) .. ","
    end

    lines[#lines + 1] = "}"
    _write_lines(path, lines)
end

--- Returns the keys of a set, sorted.
-- tab: set table whose keys are strings
-- treturn: tab
local function _sorted_keys(set)
    local keys = {}

    for key in pairs(set) do
        keys[#keys + 1] = key
    end

    sort(keys)

    return keys
end

--- Sorts the usage sizes of an entry by frequency, then by text.
-- tab: size_counts counts by `WxH`
-- treturn: tab array of `WxH`
local function _sorted_sizes(size_counts)
    local sizes = {}

    for size in pairs(size_counts) do
        sizes[#sizes + 1] = size
    end

    sort(sizes, function(a, b)
        if size_counts[a] ~= size_counts[b] then
            return size_counts[a] > size_counts[b]
        end

        return a < b
    end)

    return sizes
end

--- Writes the generated `IconSources.lua` for the indexed paths.
-- string: path output file
-- tab: paths sorted array of indexed paths
-- tab: materials entries by path
-- tab: info `game_version` and `items_version`
-- tab: extra_packages set of further packages for the top-level list (the UI asset packages)
local function _write_sources(path, paths, materials, info, extra_packages)
    local all_packages = {}

    for package_name in pairs(extra_packages) do
        all_packages[package_name] = true
    end

    for i = 1, #paths do
        local entry = materials[paths[i]]

        if entry then
            for package_name in pairs(entry.packages) do
                all_packages[package_name] = true
            end
        end
    end

    local lines = {
        "--- Generated source references of the UI materials in `IconIndex.lua`.",
        "-- Generated by `tools/generate_icon_data.lua` from the Darktide " .. info.game_version .. " source scripts",
        "-- and master items version " .. info.items_version .. "; do not edit by hand.",
        "-- For every indexed path that the scripts name or an item uses: `refs`, each script line naming",
        "-- it as `scripts/...lua:line`; `sizes`, the numeric `size` the enclosing definition draws it at,",
        "-- as `WxH`, most frequent first; `items`, each item using it as `hud_icon` as",
        "-- `{ item name, display name localization key }`; `packages`, the packages of the views and HUD",
        "-- elements whose scripts name it, which likely contain it. Paths without any are left out. The",
        "-- top-level `packages` lists every package of the indexed paths once, plus every UI asset package",
        "-- (`packages/..._ui_assets`, such as the live event artwork) the scripts name.",
        "--",
        "-- Loaded through `mod:io_dofile` by `IconBrowser.lua`, which loads the `packages` so the materials",
        "-- draw, and attached to the asset model by `IconBrowser_assets.lua`.",
        "-- module: IconSources",
        "-- author: LucLeto",
        "return {",
        "    game_version = " .. _quote(info.game_version) .. ",",
        "    items_version = " .. _quote(info.items_version) .. ",",
        "    packages = {",
    }
    local package_names = _sorted_keys(all_packages)

    for i = 1, #package_names do
        lines[#lines + 1] = "        " .. _quote(package_names[i]) .. ","
    end

    lines[#lines + 1] = "    },"
    lines[#lines + 1] = "    materials = {"

    for i = 1, #paths do
        local entry = materials[paths[i]]

        if entry and (#entry.refs > 0 or #entry.items > 0) then
            lines[#lines + 1] = "        [" .. _quote(paths[i]) .. "] = {"

            if #entry.refs > 0 then
                lines[#lines + 1] = "            refs = {"

                for r = 1, #entry.refs do
                    lines[#lines + 1] = "                " .. _quote(entry.refs[r]) .. ","
                end

                lines[#lines + 1] = "            },"
            end

            local sizes = _sorted_sizes(entry.size_counts)

            if #sizes > 0 then
                local quoted = {}

                for s = 1, #sizes do
                    quoted[s] = _quote(sizes[s])
                end

                lines[#lines + 1] = "            sizes = { " .. concat(quoted, ", ") .. " },"
            end

            local packages = _sorted_keys(entry.packages)

            if #packages > 0 then
                local quoted = {}

                for p = 1, #packages do
                    quoted[p] = _quote(packages[p])
                end

                lines[#lines + 1] = "            packages = { " .. concat(quoted, ", ") .. " },"
            end

            if #entry.items > 0 then
                sort(entry.items, function(a, b)
                    return a[1] < b[1]
                end)
                lines[#lines + 1] = "            items = {"

                for t = 1, #entry.items do
                    local item = entry.items[t]

                    lines[#lines + 1] = "                { " .. _quote(item[1]) .. ", " .. _quote(item[2]) .. " },"
                end

                lines[#lines + 1] = "            },"
            end

            lines[#lines + 1] = "        },"
        end
    end

    lines[#lines + 1] = "    },"
    lines[#lines + 1] = "}"
    _write_lines(path, lines)
end

-- ----------------------------------------------------------------------------
-- Main
-- ----------------------------------------------------------------------------

local options = _parse_arguments(arg)
local source_root = options.source and _unix_path(options.source) or _fail("--source is required")
local script_dir = (arg[0]:gsub("\\", "/"):match("^(.*)/[^/]+$")) or "."
local mod_dir = _unix_path(options.mod or (script_dir .. "/../IconBrowser/scripts/mods/IconBrowser"))
local index_path = mod_dir .. "/IconIndex.lua"
local sources_path = mod_dir .. "/IconSources.lua"
local materials = {}
local index_candidates = {}
local previous = _read_previous_index(index_path)

for i = 1, #previous do
    index_candidates[previous[i]] = true
end

local owner_packages = {}
local ui_asset_packages = {}
local file_count = _scan_scripts(source_root, materials, index_candidates, owner_packages, ui_asset_packages)

-- A material a view or HUD element names in its own scripts is taken to ship in that element's package.
for _, entry in pairs(materials) do
    for r = 1, #entry.refs do
        local file = entry.refs[r]:match("^(.-):%d+$")
        local packages = file and _owner_packages_of(file, owner_packages)

        if packages then
            for package_name in pairs(packages) do
                entry.packages[package_name] = true
            end
        end
    end
end
local items_version, item_count = "none", 0

if options["master-items"] then
    local version

    version, item_count = _scan_master_items(options["master-items"], materials, index_candidates)
    items_version = version or "unknown"
end

local paths = {}

for path in pairs(index_candidates) do
    paths[#paths + 1] = path
end

sort(paths)

local info = {
    game_version = options["game-version"] or _detect_game_version(source_root),
    items_version = items_version,
}

_write_index(index_path, paths, info)
_write_sources(sources_path, paths, materials, info, ui_asset_packages)

local referenced, sized, from_items, packaged = 0, 0, 0, 0
local package_set = {}

for i = 1, #paths do
    local entry = materials[paths[i]]

    if entry and #entry.refs > 0 then
        referenced = referenced + 1
    end

    if entry and next(entry.size_counts) then
        sized = sized + 1
    end

    if entry and #entry.items > 0 then
        from_items = from_items + 1
    end

    if entry and next(entry.packages) then
        packaged = packaged + 1

        for package_name in pairs(entry.packages) do
            package_set[package_name] = true
        end
    end
end

print(format("Scanned %d scripts and %d items with a UI hud_icon (game %s, items %s).", file_count, item_count,
    info.game_version, info.items_version))
print(format("Index: %d paths (%d before, %d new).", #paths, #previous, #paths - #previous))
print(format("Sources: %d paths named by scripts, %d with a usage size, %d used by items.", referenced, sized,
    from_items))
print(format("Packages: %d paths in %d view and HUD element packages, plus %d UI asset packages.", packaged,
    #_sorted_keys(package_set), #_sorted_keys(ui_asset_packages)))
