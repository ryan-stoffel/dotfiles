-- Change the default Omarchy look'n'feel.

-- Opt another application in to Omarchy's standard transparency.
-- Find its class with: hyprctl clients
-- o.transparent_window("my-app")
-- o.transparent_window("my-app", "0.9 0.85") -- Custom active/inactive opacity.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

-- Ghostty blur (replaces macOS background-blur). Omarchy's glass blur shows
-- through any see-through window; opaque windows are unaffected.
require("default.hypr.glass")()

-- Ghostty sets its own background-opacity (0.78) and keeps text solid, so skip
-- Omarchy's extra whole-window transparency for it.
o.window("com.mitchellh.ghostty", { opacity = "1.0 override 1.0 override" })

-- Half of Omarchy's default gaps (5/10), equal on all sides. Corners stay
-- Omarchy's default square; the shell mirrors that for its panels.
hl.config({
  general = {
    gaps_in = 2,
    gaps_out = 5,
  },
})

-- Subtle focus border instead of the theme's teal: Everforest's soft gray
-- (#9da9a0) at ~55% opacity, a step above the inactive border.
local subtle_active_border = "rgba(9da9a08c)"
hl.config({
  general = { col = { active_border = subtle_active_border } },
  group = { col = { border_active = subtle_active_border } },
})

-- Touch ID for sudo card (ryan-stoffel.sudo-touchid plugin): frosted glass
-- behind it like the macOS sheet; the card animates itself in QML.
hl.layer_rule({
  match = { namespace = "^ryan-stoffel-sudo-touchid$" },
  blur = true,
  ignore_alpha = 0.3,
  no_anim = true,
  animation = "none",
})

-- Workspaces glide instead of snapping, so a released trackpad swipe settles
-- smoothly (Omarchy turns this animation off by default).
-- A gentle ease-out (the iOS/macOS page curve) over ~500 ms.
hl.curve("swipeSettle", { type = "bezier", points = { { 0.32, 0.72 }, { 0, 1 } } })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "swipeSettle", style = "slide" })
