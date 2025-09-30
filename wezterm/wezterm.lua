local wezterm = require("wezterm")
local config = wezterm.config_builder()

local triple = wezterm.target_triple or ""
local is_macos   = triple:find("apple%-darwin") ~= nil
local is_windows = triple:find("windows") ~= nil
local is_linux   = triple:find("linux") ~= nil

-- Font
if is_windows then 
	config.font = wezterm.font("FiraCode Nerd Font Mono")
elseif is_macos then
	config.font = wezterm.font("FiraCode Nerd Font")
end
config.font_size = 12.5

-- Colors
config.color_scheme = "Tokyo Night"

-- Window
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = true
config.window_decorations = "TITLE | RESIZE"
config.hide_tab_bar_if_only_one_tab = true

-- Misc
if is_windows then
	config.default_prog = { 'powershell' }
end

return config
