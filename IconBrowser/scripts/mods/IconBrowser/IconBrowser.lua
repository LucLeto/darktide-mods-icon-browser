local mod = get_mod("IconBrowser")

local VIEW_NAME = "icon_browser_view"

local function _load_icon_index()
  local ok, icons = pcall(function()
    if mod and mod.io_dofile then
      -- DMF resource path style (matches your IconBrowser.mod style)
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

mod._icon_paths = mod._icon_paths or _load_icon_index()

function mod:get_icon_paths()
  return self._icon_paths or {}
end

function mod:open_icon_browser()
  if Managers and Managers.ui then
    Managers.ui:open_view(VIEW_NAME)
    self._icon_browser_view_open = true
  end
end

function mod:close_icon_browser()
  if Managers and Managers.ui then
    Managers.ui:close_view(VIEW_NAME)
    self._icon_browser_view_open = false
  end
end

function mod:toggle_icon_browser()
  if self._icon_browser_view_open then
    self:close_icon_browser()
  else
    self:open_icon_browser()
  end
end

-- (Optional) DMF calls this for some widgets; keep it harmless
function mod:on_setting_changed(_setting_id)
end

return mod
