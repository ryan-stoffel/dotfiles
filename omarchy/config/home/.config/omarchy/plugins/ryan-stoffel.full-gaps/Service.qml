import QtQuick
import Quickshell.Io
import qs.Commons

// Style.gapsOut is half of Hyprland's general:gaps_out, so panels open closer
// to the bar than windows sit. This resets it to the full top gap whenever
// Style recomputes it (startup, theme change, Hyprland config reload).
Item {
  id: root

  property int fullGap: -1

  function apply() {
    if (root.fullGap >= 0 && Style.gapsOut !== root.fullGap) Style.gapsOut = root.fullGap
  }

  Process {
    id: proc
    running: true
    command: ["hyprctl", "-j", "getoption", "general:gaps_out"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var json = JSON.parse(text || "{}")
          var parts = String(json.css || "").match(/\d+/g) || []
          var n = parts.length > 0 ? Number(parts[0]) : Number(json.int)
          if (isFinite(n) && n >= 0) root.fullGap = n
        } catch (e) {}
        root.apply()
      }
    }
  }

  Connections {
    target: Style
    function onGapsOutChanged() {
      // Style just wrote its halved value: re-read in case gaps_out changed.
      if (Style.gapsOut !== root.fullGap) proc.running = true
    }
  }
}
