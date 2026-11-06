-- Keep only your personal keybinding overrides here. Add new bindings with
-- o.bind or replace defaults with o.rebind.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding. o.rebind takes the same arguments as o.bind.
-- This example replaces the default file manager with Flea.
-- o.rebind("SUPER + SHIFT + F", "File manager", { launch = "flea" })

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, { panel = "omarchy.emojis" })

-- Clean-screen mode (was: Calendar webapp). Super+Shift+C enters a submap that
-- swallows every key until Super+Shift+C is pressed again.
o.rebind("SUPER + SHIFT + C", "Clean screen (lock keyboard)", function()
  hl.dispatch(hl.dsp.submap("clean"))
  hl.exec_cmd(o.notify("Keyboard locked. Super+Shift+C to unlock."))
end)

hl.define_submap("clean", function()
  hl.bind("SUPER + SHIFT + C", hl.dsp.submap("reset"))
  hl.bind("catchall", function() end)
end)

-- Apps launcher on Super+Space (was: Omarchy menu).
o.rebind("SUPER + SPACE", "Apps", { menu = "apps" })
-- Omarchy menu on Super+Alt+Space (was: Apps grid).
o.rebind("SUPER + ALT + SPACE", "Omarchy menu", { menu = "root" })
-- Screenshot (was: Google Maps webapp): copy and save with no preview or editor. Screen recording (unbound by default).
o.rebind("SUPER + SHIFT + S", "Screenshot", "omarchy-capture-screenshot copy save")
o.bind("SUPER + SHIFT + R", "Screenrecording", "omarchy-capture-screenrecording --stop-recording || omarchy-menu toggle trigger.capture.screenrecord")
