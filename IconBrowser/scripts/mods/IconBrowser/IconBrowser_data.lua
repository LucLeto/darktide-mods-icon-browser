local mod = get_mod("IconBrowser")

return {
    mod_name = mod:localize("mod_name"),
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = {
            {
                setting_id = "open_icon_browser",
                type = "keybind",
                default_value = { "keyboard_f8" },
                keybind_global = true,
                keybind_trigger = "pressed",
                keybind_type = "function_call",
                function_name = "toggle_icon_browser",
                tooltip = mod:localize("open_tooltip"),
            },
        },
    },
}
