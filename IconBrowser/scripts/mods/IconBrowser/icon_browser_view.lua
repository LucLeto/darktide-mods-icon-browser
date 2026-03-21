local mod = get_mod("IconBrowser")

local UIFontSettings = require("scripts/managers/ui/ui_font_settings")
local UIWidget = require("scripts/managers/ui/ui_widget")
local UIWidgetGrid = require("scripts/ui/widget_logic/ui_widget_grid")
local UIRenderer = require("scripts/managers/ui/ui_renderer")
local ScrollbarPassTemplates = require("scripts/ui/pass_templates/scrollbar_pass_templates")
local ViewElementInputLegend = require("scripts/ui/view_elements/view_element_input_legend/view_element_input_legend")
local UIWorkspaceSettings = require("scripts/settings/ui/ui_workspace_settings")

local function _clone(style) return table.clone(style) end

local VIEW_NAME = "icon_browser_view"

local IconBrowserView = class("IconBrowserView", "BaseView")

IconBrowserView.init = function(self, settings)
  local scenegraph_definition = {
    screen = UIWorkspaceSettings.screen,

    background = {
      parent = "screen",
      horizontal_alignment = "center",
      vertical_alignment = "center",
      size = { 1500, 920 },
      position = { 0, 0, 1 },
    },

    title_text = {
      parent = "background",
      horizontal_alignment = "left",
      vertical_alignment = "top",
      size = { 1420, 50 },
      position = { 40, 10, 2 },
    },

    table_header = {
      parent = "background",
      horizontal_alignment = "left",
      vertical_alignment = "top",
      size = { 1410, 40 },
      position = { 40, 70, 2 },
    },

    grid_area = {
      parent = "background",
      horizontal_alignment = "left",
      vertical_alignment = "top",
      size = { 1410, 780 },
      position = { 40, 118, 1 },
    },

    grid_content_pivot = {
      parent = "grid_area",
      horizontal_alignment = "left",
      vertical_alignment = "top",
      size = { 0, 0 },
      position = { 0, 0, 1 },
    },

    scrollbar = {
      parent = "grid_area",
      horizontal_alignment = "right",
      vertical_alignment = "top",
      size = { 10, 780 },
      position = { 22, 0, 2 },
    },
  }

  local header_style = _clone(UIFontSettings.header_2)
  header_style.text_horizontal_alignment = "left"
  header_style.horizontal_alignment = "left"
  header_style.vertical_alignment = "center"
  header_style.text_vertical_alignment = "center"

  local title_style = _clone(UIFontSettings.header_1)
  title_style.text_horizontal_alignment = "left"
  title_style.horizontal_alignment = "left"

  local widget_definitions = {
    background = UIWidget.create_definition({
      { pass_type = "rect", style = { color = { 185, 0, 0, 0 } } },
    }, "background"),

    title_text = UIWidget.create_definition({
      { value_id = "text", pass_type = "text", value = mod:localize("loc_icon_browser_title"), style = title_style },
    }, "title_text"),

    table_header = UIWidget.create_definition({
      { pass_type = "rect", style = { color = { 180, 25, 25, 25 } } },
      { value_id = "icon_header", pass_type = "text", value = mod:localize("loc_icon_browser_column_icon"),
        style = (function() local s=_clone(header_style); s.offset={12,0,3}; return s end)() },
      { value_id = "path_header", pass_type = "text", value = mod:localize("loc_icon_browser_column_path"),
        style = (function() local s=_clone(header_style); s.offset={90,0,3}; return s end)() },
    }, "table_header"),

    scrollbar = UIWidget.create_definition(ScrollbarPassTemplates.default_scrollbar, "scrollbar", {
      scroll_speed = 10,
      scroll_amount = 0.15,
    }),
  }

  local definitions = {
    scenegraph_definition = scenegraph_definition,
    widget_definitions = widget_definitions,
    legend_inputs = {
      {
        input_action = "back",
        on_pressed_callback = "cb_on_back_pressed",
        display_name = "loc_settings_menu_close_menu",
        alignment = "left_alignment",
      },
    },
  }

  IconBrowserView.super.init(self, definitions, settings)

  self._row_height = 64
  self._icon_size = 48
end

function IconBrowserView.on_enter(self)
  IconBrowserView.super.on_enter(self)
  mod._icon_browser_view_open = true
  self:_setup_input_legend()
  self:_build_rows()
  self:_setup_grid()
end

function IconBrowserView.on_exit(self)
  mod._icon_browser_view_open = false
  if self._input_legend_element then
    self:_remove_element("input_legend")
    self._input_legend_element = nil
  end
  IconBrowserView.super.on_exit(self)
end

function IconBrowserView.cb_on_back_pressed(self)
  Managers.ui:close_view(VIEW_NAME)
end

function IconBrowserView._setup_input_legend(self)
  self._input_legend_element = self:_add_element(ViewElementInputLegend, "input_legend", 10)
  self._input_legend_element:set_display_name(mod:localize("loc_icon_browser_view_display_name"))

  for _, e in ipairs(self._definitions.legend_inputs) do
    self._input_legend_element:add_entry(
      e.display_name,
      e.input_action,
      e.visibility_function,
      e.on_pressed_callback and callback(self, e.on_pressed_callback),
      e.alignment
    )
  end
end

local function _row_definition(row_height, icon_size)
  local path_style = _clone(UIFontSettings.list_button)
  path_style.text_horizontal_alignment = "left"
  path_style.horizontal_alignment = "left"
  path_style.vertical_alignment = "center"
  path_style.text_vertical_alignment = "center"
  path_style.offset = { 90, 0, 3 }

  local icon_style = {
    vertical_alignment = "center",
    horizontal_alignment = "left",
    size = { icon_size, icon_size },
    offset = { 12, 0, 2 },
    color = { 255, 255, 255, 255 },
  }

  return UIWidget.create_definition({
    { pass_type = "hotspot", content_id = "hotspot" },
    { pass_type = "rect", style_id = "bg", style = { color = { 120, 0, 0, 0 } } },
    { value_id = "icon", pass_type = "texture", style_id = "icon", value = "", style = icon_style },
    { value_id = "path", pass_type = "text", style_id = "path", value = "", style = path_style },
    {
      pass_type = "rect",
      style_id = "hover",
      style = { color = { 0, 255, 255, 255 }, offset = { 0, 0, 10 } },
      change_function = function(content, style)
        local hs = content.hotspot
        style.color[1] = (hs and (hs.is_hover or hs.is_focused)) and 35 or 0
      end,
    },
  }, "grid_content_pivot", nil, { 1410, row_height })
end

function IconBrowserView._build_rows(self)
  local icons = mod:get_icon_paths()
  local widgets, align = {}, {}
  local row_def = _row_definition(self._row_height, self._icon_size)

  for i, p in ipairs(icons) do
    local w = self:_create_widget("icon_row_" .. i, row_def)
    w.content.icon = p
    w.content.path = p

    if w.style and w.style.bg and w.style.bg.color then
      w.style.bg.color[1] = (i % 2 == 1) and 105 or 125
    end

    w.content.hotspot.pressed_callback = function()
      if mod:get("copy_path_on_click") then
        if Application and Application.set_clipboard then
          pcall(Application.set_clipboard, Application, p)
        end
        if Mods and Mods.message and Mods.message.echo then
          Mods.message.echo(string.format("[IconBrowser] %s", p))
        else
          print("[IconBrowser] " .. p)
        end
      end
    end

    widgets[#widgets + 1] = w
    align[#align + 1] = w
  end

  self._rows = widgets
  self._row_align = align
end

function IconBrowserView._setup_grid(self)
  local grid = UIWidgetGrid:new(self._rows, self._row_align, self._ui_scenegraph, "grid_area", "down", { 0, 2 }, nil, true)
  local scrollbar = self._widgets_by_name.scrollbar
  grid:assign_scrollbar(scrollbar, "grid_content_pivot", "grid_area", true)
  grid:set_scrollbar_progress(0)
  self._grid = grid
end

function IconBrowserView.update(self, dt, t, input_service)
  IconBrowserView.super.update(self, dt, t, input_service)
  if self._grid then
    self._grid:update(dt, t, input_service)
  end
end

function IconBrowserView.draw(self, dt, t, input_service, layer)
  IconBrowserView.super.draw(self, dt, t, input_service, layer)

  if self._grid then
    local ui_renderer = self._ui_renderer
    UIRenderer.begin_pass(ui_renderer, self._ui_scenegraph, input_service, dt, self._render_settings)

    for _, w in ipairs(self._rows) do
      if self._grid:is_widget_visible(w) then
        UIWidget.draw(w, ui_renderer)
      end
    end

    UIRenderer.end_pass(ui_renderer)
  end
end

return IconBrowserView
