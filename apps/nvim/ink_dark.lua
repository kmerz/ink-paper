-- ink_dark: NvChad (base46) dark theme. Ink background, paper-colored lines, one red accent.
local M = {}

M.base_30 = {
  white = "#E9E4DA", -- text
  darker_black = "#0F0F0F",
  black = "#141414", -- background
  black2 = "#1E1E1E",
  one_bg = "#1E1E1E",
  one_bg2 = "#262523",
  one_bg3 = "#2F2D2A",
  grey = "#3D3B38",
  grey_fg = "#4C4945",
  grey_fg2 = "#5C5853",
  light_grey = "#8A8580",
  red = "#C8473A",
  baby_pink = "#D25A4D",
  pink = "#C8473A",
  line = "#2A2826",
  green = "#8E907F",
  vibrant_green = "#A3A593",
  nord_blue = "#858C96",
  blue = "#858C96",
  yellow = "#B3A283",
  sun = "#C7B697",
  purple = "#9E8A92",
  dark_purple = "#B39FA7",
  teal = "#869390",
  orange = "#B3A283",
  cyan = "#869390",
  statusline_bg = "#1E1E1E",
  lightbg = "#262523",
  pmenu_bg = "#C8473A",
  folder_bg = "#8A8580",
}

M.base_16 = {
  base00 = "#141414",
  base01 = "#1E1E1E",
  base02 = "#262523",
  base03 = "#5C5853",
  base04 = "#8A8580",
  base05 = "#E9E4DA",
  base06 = "#F2EEE6",
  base07 = "#FFFFFF",
  base08 = "#E9E4DA",
  base09 = "#B3A283",
  base0A = "#858C96",
  base0B = "#8E907F",
  base0C = "#869390",
  base0D = "#CFC9BE",
  base0E = "#E9E4DA",
  base0F = "#8A8580",
}

M.polish_hl = {
  defaults = {
    Comment = { fg = "#8A8580", italic = true },
    CursorLineNr = { fg = "#E9E4DA", bold = true },
    DiagnosticError = { fg = "#C8473A" },
  },
  treesitter = {
    ["@comment"] = { fg = "#8A8580", italic = true },
    ["@keyword"] = { fg = "#E9E4DA", bold = true },
    ["@keyword.function"] = { fg = "#E9E4DA", bold = true },
    ["@keyword.return"] = { fg = "#E9E4DA", bold = true },
  },
}

M.type = "dark"

M = require("base46").override_theme(M, "ink_dark")

return M
