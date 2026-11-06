import QtQuick
import qs.Ui
import qs.Commons
import "../io.github.thisisgm.omapods" as Pods
import "../io.github.thisisgm.omapods/Model.js" as PodsModel

// AirPods battery and listening controls inside the audio panel. Shown only
// while AirPods are connected. State and actions come from the omapods
// plugin's Service (the librepods daemon), imported from that plugin's folder,
// so `omarchy plugin update` keeps the daemon protocol in step.
Column {
  id: section

  required property color foreground
  required property string fontFamily
  required property color hoverFill

  readonly property bool active: pods.hasAirPods
  readonly property var modes: pods.availableModes()
  readonly property color dim: Qt.darker(foreground, 1.4)

  function refresh() { pods.refresh() }

  function batteryText() {
    if (pods.isHeadset) return PodsModel.levelText(pods.headsetBattery.level)
    var parts = ["L " + PodsModel.levelText(pods.leftPod.level), "R " + PodsModel.levelText(pods.rightPod.level)]
    if (pods.caseBattery.level !== PodsModel.LEVEL_UNKNOWN) parts.push("Case " + PodsModel.levelText(pods.caseBattery.level))
    return parts.join("  ")
  }

  visible: active
  spacing: Style.space(6)

  Pods.Service { id: pods }

  Item {
    width: parent.width
    implicitHeight: Math.max(header.implicitHeight, battery.implicitHeight)

    PanelSectionHeader {
      id: header
      text: (pods.modelName || pods.deviceName || "AirPods").toUpperCase()
      foreground: section.foreground
      fontFamily: section.fontFamily
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      id: battery
      textFormat: Text.PlainText
      text: section.batteryText() + ((pods.headsetBattery.charging || pods.leftPod.charging || pods.rightPod.charging) ? " ⚡" : "")
      color: section.dim
      font.family: section.fontFamily
      font.pixelSize: Style.font.caption
      font.bold: true
      anchors.right: parent.right
      anchors.rightMargin: Style.space(6)
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  Repeater {
    model: section.modes

    Row_ {
      required property var modelData
      label: PodsModel.noiseModeName(modelData)
      selected: pods.noiseMode === modelData
      onClicked: pods.setNoiseMode(modelData)
    }
  }

  Row_ {
    visible: pods.supportsConversationalAwareness
    label: "Conversation Awareness"
    value: pods.conversationalAwareness ? "On" : "Off"
    onClicked: pods.setConversationalAwareness(!pods.conversationalAwareness)
  }

  Row_ {
    visible: pods.supportsOneBudANC
    label: "One-Bud ANC"
    value: pods.oneBudANC ? "On" : "Off"
    onClicked: pods.setOneBudANC(!pods.oneBudANC)
  }

  Row_ {
    label: "Ear detection"
    value: PodsModel.earDetectionName(pods.earDetectionBehavior)
    onClicked: pods.cycleEarDetection()
  }

  Text {
    textFormat: Text.PlainText
    visible: pods.actionStatus !== "" || pods.lastError !== ""
    width: parent.width
    text: pods.actionStatus !== "" ? pods.actionStatus : pods.lastError
    color: section.dim
    font.family: section.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }

  // One clickable row: a label, then a check mark when selected or a value.
  component Row_: CursorSurface {
    id: row
    property string label: ""
    property string value: ""
    property bool selected: false
    signal clicked()

    width: section.width
    implicitHeight: rowLabel.implicitHeight + Style.spacing.xl
    hasCursor: mouse.containsMouse
    foreground: section.foreground
    fill: section.hoverFill

    Text {
      id: rowLabel
      textFormat: Text.PlainText
      text: row.label
      color: section.foreground
      opacity: row.selected || row.value !== "" ? 1.0 : 0.75
      font.family: section.fontFamily
      font.pixelSize: Style.font.body
      anchors.left: parent.left
      anchors.leftMargin: Style.space(6)
      anchors.verticalCenter: parent.verticalCenter
    }

    Text {
      textFormat: Text.PlainText
      text: row.value !== "" ? row.value : PodsModel.GLYPH_CHECK
      visible: row.value !== "" || row.selected
      color: row.value !== "" ? section.dim : section.foreground
      font.family: section.fontFamily
      font.pixelSize: row.value !== "" ? Style.font.caption : Style.font.icon
      anchors.right: parent.right
      anchors.rightMargin: Style.space(6)
      anchors.verticalCenter: parent.verticalCenter
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: row.clicked()
    }
  }
}
