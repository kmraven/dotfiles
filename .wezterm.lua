local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- カラースキームの設定
-- config.color_scheme = 'Tokyo Night'

-- 背景透過
config.window_background_opacity = 0.85

-- ショートカットキー設定
local act = wezterm.action
config.keys = {
  -- Alt(Opt)+Shift+Fでフルスクリーン切り替え
  {
    key = 'f',
    mods = 'CTRL|CMD',
    action = wezterm.action.ToggleFullScreen,
  },
}
config.native_macos_fullscreen_mode = true

-- フォントの設定
config.font = wezterm.font("MesloLGS Nerd Font Mono")
-- フォントサイズの設定
config.font_size = 18

use_fancy_tab_bar = true

return config