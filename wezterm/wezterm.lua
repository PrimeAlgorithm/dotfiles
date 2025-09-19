local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Font
config.font = wezterm.font("FiraCode Nerd Font Mono")
config.font_size = 12.5

-- Colors
config.color_scheme = "Tokyo Night"

-- Window
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
config.window_decorations = "TITLE | RESIZE"
config.hide_tab_bar_if_only_one_tab = true

-- Misc
config.default_prog = { 'powershell' }

return config
