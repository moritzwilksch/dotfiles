local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Shell
config.default_prog = { 'C:/Users/<USERNAME>/AppData/Local/Programs/Git/bin/bash.exe', '-i', '-l' }

-- Remove Windows title bar
config.window_decorations = 'RESIZE'

-- Paste with Ctrl+V
config.keys = {
  { key = 'v', mods = 'CTRL', action = wezterm.action.PasteFrom('Clipboard') },
}

-- Blinking cursor without fade
config.default_cursor_style = 'BlinkingBlock'
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

-- Brighter foreground text
config.colors = {
  foreground = '#e0e0e0',
  ansi = {
    '#1a1a1a', -- black
    '#ff5555', -- red
    '#50fa7b', -- green
    '#f1fa8c', -- yellow
    '#6272a4', -- blue
    '#ff79c6', -- magenta
    '#8be9fd', -- cyan
    '#f8f8f2', -- white (bright)
  },
  brights = {
    '#6272a4', -- bright black
    '#ff6e6e', -- bright red
    '#69ff94', -- bright green
    '#ffffa5', -- bright yellow
    '#d6acff', -- bright blue
    '#ff92df', -- bright magenta
    '#a4ffff', -- bright cyan
    '#ffffff', -- bright white
  },
}
config.scrollback_lines = 0

return config
