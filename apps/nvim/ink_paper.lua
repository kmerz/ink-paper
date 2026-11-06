-- ink_paper: NvChad (base46) light theme. Warm paper, black ink, one red accent.
local M = {}

M.base_30 = {
  white = "#1A1A1A", -- in base46 "white" is the text color
  darker_black = "#E7E2D8",
  black = "#F2EEE6", -- background
  black2 = "#E7E2D8",
  one_bg = "#E7E2D8",
  one_bg2 = "#DDD7CC",
  one_bg3 = "#D3CDC1",
  grey = "#B8B2A8",
  grey_fg = "#A39D94",
  grey_fg2 = "#8A8580",
  light_grey = "#6E6A64",
  red = "#B23A2E",
  baby_pink = "#C8473A",
  pink = "#B23A2E",
  line = "#DDD7CC",
  green = "#5F6152",
  vibrant_green = "#717364",
  nord_blue = "#565D68",
  blue = "#565D68",
  yellow = "#7D6E52",
  sun = "#8F8064",
  purple = "#6B5A60",
  dark_purple = "#7D6C72",
  teal = "#56625F",
  orange = "#7D6E52",
  cyan = "#56625F",
  statusline_bg = "#E7E2D8",
  lightbg = "#DDD7CC",
  pmenu_bg = "#B23A2E",
  folder_bg = "#5C5853",
}

M.base_16 = {
  base00 = "#F2EEE6",
  base01 = "#E7E2D8",
  base02 = "#DDD7CC",
  base03 = "#8A8580",
  base04 = "#6E6A64",
  base05 = "#1A1A1A",
  base06 = "#141414",
  base07 = "#000000",
  base08 = "#1A1A1A",
  base09 = "#7D6E52",
  base0A = "#565D68",
  base0B = "#5F6152",
  base0C = "#56625F",
  base0D = "#3A3836",
  base0E = "#1A1A1A",
  base0F = "#8A8580",
}

M.polish_hl = {
  defaults = {
    Comment = { fg = "#8A8580", italic = true },
    CursorLineNr = { fg = "#1A1A1A", bold = true },
    DiagnosticError = { fg = "#B23A2E" },
  },
  treesitter = {
    ["@comment"] = { fg = "#8A8580", italic = true },
    ["@keyword"] = { fg = "#1A1A1A", bold = true },
    ["@keyword.function"] = { fg = "#1A1A1A", bold = true },
    ["@keyword.return"] = { fg = "#1A1A1A", bold = true },
  },
}

M.type = "light"

M = require("base46").override_theme(M, "ink_paper")

return M
