local mod = get_mod("IconBrowser")

local widgets = {
  {
    setting_id = "open_icon_browser",
    type = "keybind",
    default_value = { "keyboard_f8" },

    -- IMPORTANT for your DMF version:
    mod_name = "IconBrowser",
    keybind_global = true,
    keybind_trigger = "pressed",
    keybind_type = "function",
    function_name = "toggle_icon_browser",

    title = mod:localize("loc_icon_browser_open_title"),
    tooltip = mod:localize("loc_icon_browser_open_tooltip"),
  },
  {
    setting_id = "copy_path_on_click",
    type = "checkbox",
    default_value = true,

    title = mod:localize("loc_icon_browser_copy_title"),
    tooltip = mod:localize("loc_icon_browser_copy_tooltip"),
  },
}

return {
  widgets = widgets,
}
