{ laptop, ... }:
{
  programs.btop = {
    enable = true;

    settings = {
      # Draw on the terminal's translucent background instead of btop's own.
      theme_background = false;
      truecolor = true;
      vim_keys = true;
      rounded_corners = false;
      # Braille glyphs read as a finer trace than the default blocks.
      graph_symbol = "braille";
      show_battery = laptop;
      update_ms = 1000;
    };
  };
}
