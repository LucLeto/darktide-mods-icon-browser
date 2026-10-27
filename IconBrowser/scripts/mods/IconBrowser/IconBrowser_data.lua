--- Icon Browser's DMF mod data; the mod description and the settings menu.
-- The returned table names the mod, makes it togglable and declares its options: the Open Icon
-- Browser keybind (F8 by default, a global `function_call` keybind of `toggle_icon_browser`); the
-- frame's Window Size, X and Y position and move step with four optional move keybinds; and the
-- browser's Inspector Width, Thumbnail Density, Double-Click Copies Path and C Key Copies Path.
-- Every option has a tooltip. The settings are read through the getters in `IconBrowser.lua`, which
-- clamp or validate them and fall back to the defaults declared here. The view stores further state
-- with `mod:set` under ids that have no widget here: view mode, category, sort, preview background,
-- favorites and the recent history.
--
-- Loaded by DMF as `mod_data`, as declared in `IconBrowser.mod`.
-- module: IconBrowser_data
-- author: LucLeto
local mod = get_mod("IconBrowser")

return {
    mod_name = mod:localize("mod_name"),
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = {
            -- Opening and closing the browser
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
            -- Frame size and position; 100 % fills the screen above the input legend
            {
                setting_id = "icon_browser_scale",
                type = "numeric",
                default_value = 100,
                range = { 50, 100 },
                decimals_number = 0,
                step_size_value = 5,
                change = function(new_value)
                    mod:set_icon_browser_scale(new_value)
                end,
                get = function()
                    return mod:get_icon_browser_scale()
                end,
                tooltip = mod:localize("size_tooltip"),
            },
            {
                setting_id = "icon_browser_pos_x",
                type = "numeric",
                default_value = 0,
                range = { -12000, 12000 },
                decimals_number = 0,
                step_size_value = 5,
                change = function(new_value)
                    mod:set_icon_browser_position(new_value, nil)
                end,
                get = function()
                    return mod:get_icon_browser_offset_x()
                end,
                tooltip = mod:localize("position_x_tooltip"),
            },
            {
                setting_id = "icon_browser_pos_y",
                type = "numeric",
                default_value = 0,
                range = { -12000, 12000 },
                decimals_number = 0,
                step_size_value = 5,
                change = function(new_value)
                    mod:set_icon_browser_position(nil, new_value)
                end,
                get = function()
                    return mod:get_icon_browser_offset_y()
                end,
                tooltip = mod:localize("position_y_tooltip"),
            },
            {
                setting_id = "icon_browser_move_step",
                type = "numeric",
                default_value = 10,
                range = { 1, 200 },
                decimals_number = 0,
                step_size_value = 1,
                change = function(new_value)
                    mod:set_icon_browser_move_step(new_value)
                end,
                get = function()
                    return mod:get_icon_browser_move_step()
                end,
                tooltip = mod:localize("move_step_tooltip"),
            },
            {
                setting_id = "move_icon_browser_left_key",
                type = "keybind",
                default_value = {},
                keybind_trigger = "pressed",
                keybind_type = "function_call",
                function_name = "move_icon_browser_left",
                tooltip = mod:localize("move_left_tooltip"),
            },
            {
                setting_id = "move_icon_browser_right_key",
                type = "keybind",
                default_value = {},
                keybind_trigger = "pressed",
                keybind_type = "function_call",
                function_name = "move_icon_browser_right",
                tooltip = mod:localize("move_right_tooltip"),
            },
            {
                setting_id = "move_icon_browser_up_key",
                type = "keybind",
                default_value = {},
                keybind_trigger = "pressed",
                keybind_type = "function_call",
                function_name = "move_icon_browser_up",
                tooltip = mod:localize("move_up_tooltip"),
            },
            {
                setting_id = "move_icon_browser_down_key",
                type = "keybind",
                default_value = {},
                keybind_trigger = "pressed",
                keybind_type = "function_call",
                function_name = "move_icon_browser_down",
                tooltip = mod:localize("move_down_tooltip"),
            },
            -- Browser layout and copy shortcuts
            {
                setting_id = "icon_browser_inspector_width",
                type = "numeric",
                default_value = 28,
                range = { 25, 40 },
                decimals_number = 0,
                step_size_value = 1,
                tooltip = mod:localize("inspector_width_tooltip"),
            },
            {
                setting_id = "icon_browser_density",
                type = "dropdown",
                default_value = "normal",
                options = {
                    { text = "density_option_compact", value = "compact" },
                    { text = "density_option_normal", value = "normal" },
                    { text = "density_option_large", value = "large" },
                },
                tooltip = mod:localize("density_tooltip"),
            },
            {
                setting_id = "icon_browser_double_click_copy",
                type = "checkbox",
                default_value = true,
                tooltip = mod:localize("double_click_copy_tooltip"),
            },
            {
                setting_id = "icon_browser_copy_hotkey",
                type = "checkbox",
                default_value = true,
                tooltip = mod:localize("copy_hotkey_tooltip"),
            },
        },
    },
}
