import QtQuick
import qs.Ui

// Same as the built-in omarchy.menu bar button, with the Nerd Font Apple glyph.
BarWidget {
  id: root
  moduleName: "ryan-stoffel.apple-menu"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    fontFamily: "JetBrainsMono Nerd Font"
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("omarchy-shell shell toggle omarchy.menu '{\"menu\":\"root\"}'")
    }
  }
}
