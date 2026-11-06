-- ink-paper theme (begin): pick ink_paper or ink_dark to match GNOME at startup.
-- NvChad keeps compiled colors in a cache, so it is rebuilt only when the mode changed.
do
  local ok, out = pcall(vim.fn.system, { "gsettings", "get", "org.gnome.desktop.interface", "color-scheme" })
  local want = (ok and out:match "dark") and "ink_dark" or "ink_paper"
  local stamp = vim.fn.stdpath "data" .. "/ink-paper-theme"
  local f = io.open(stamp, "r")
  local have = f and f:read "*l" or ""
  if f then f:close() end
  local cfg = require "nvconfig"
  cfg.base46.theme = want
  if have ~= want then
    require("base46").load_all_highlights()
    f = io.open(stamp, "w")
    if f then f:write(want) f:close() end
  end
end
-- ink-paper theme (end)
