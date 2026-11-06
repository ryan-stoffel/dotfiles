import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// A macOS-style Touch ID sheet for sudo. /usr/local/bin/sudo-touchid drives it
// from sudo's PAM stack:
//   omarchy-shell sudoTouchId show "<command>"  pam_fprintd is about to wait
//   omarchy-shell sudoTouchId done              authentication succeeded
//   omarchy-shell sudoTouchId hide              fingerprint gave up, or sudo went away
// The sheet never takes keyboard focus, so the terminal keeps Ctrl+C and the
// password fallback. Hyprland blurs what is behind it (see hypr/looknfeel.lua).
Item {
  id: root

  property bool shown: false
  property bool matched: false
  property string command: ""

  readonly property color tint: Commons.Color.polkit.background
  readonly property color textColor: Commons.Color.polkit.text
  // macOS's Touch ID pink-red and success green.
  readonly property color sensorColor: "#ff375f"
  readonly property color matchColor: "#30d158"
  readonly property int sheetWidth: Style.space(300)
  readonly property int shadowMargin: Style.space(40)
  readonly property string sansFamily: "Adwaita Sans"

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  // The command arrives from the PAM hook: keep it short and printable.
  function cleanCommand(raw) {
    var s = String(raw || "").replace(/[^\x20-\x7e]/g, "?").trim()
    return s.length > 160 ? s.slice(0, 157) + "..." : s
  }

  function present(raw) {
    doneTimer.stop()
    command = cleanCommand(raw)
    matched = false
    shown = true
    // pam_fprintd gives up after 30 s; never outlive it if hide is missed.
    safetyTimer.restart()
  }

  function finish() {
    if (!shown) return
    safetyTimer.stop()
    matched = true
    doneTimer.restart()
  }

  function dismiss() {
    safetyTimer.stop()
    doneTimer.stop()
    shown = false
  }

  ShellIpc {
    target: "sudoTouchId"

    function show(command: string): string { root.present(command); return "ok" }
    function done(): string { root.finish(); return "ok" }
    function hide(): string { root.dismiss(); return "ok" }
  }

  Timer { id: safetyTimer; interval: 35000; onTriggered: root.dismiss() }
  Timer { id: doneTimer; interval: 550; onTriggered: root.shown = false }

  PanelWindow {
    id: panel
    visible: root.shown || content.opacity > 0
    implicitWidth: root.sheetWidth + root.shadowMargin * 2
    implicitHeight: sheet.height + root.shadowMargin * 2
    color: "transparent"
    WlrLayershell.namespace: "ryan-stoffel-sudo-touchid"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    Item {
      id: content
      anchors.fill: parent
      opacity: root.shown ? 1 : 0
      scale: root.shown ? 1 : 0.96
      Behavior on opacity { NumberAnimation { duration: Style.duration(root.shown ? 180 : 120); easing.type: Easing.OutCubic } }
      Behavior on scale {
        NumberAnimation { duration: Style.duration(180); easing.type: Easing.Bezier; easing.bezierCurve: Style.easeOut }
      }

      MultiEffect {
        source: sheet
        anchors.fill: sheet
        shadowEnabled: true
        shadowColor: "#000000"
        shadowOpacity: 0.45
        shadowBlur: 1.0
        shadowVerticalOffset: Style.space(10)
        blurMax: 48
      }

      Rectangle {
        id: sheet
        width: root.sheetWidth
        height: column.implicitHeight + Style.space(52)
        anchors.centerIn: parent
        radius: Style.cornerRadius
        // See-through so the Hyprland blur shows, like macOS vibrancy.
        color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.72)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)

        Column {
          id: column
          anchors.centerIn: parent
          width: parent.width - Style.space(48)
          spacing: Style.space(6)

          // The fingerprint (nf-md-fingerprint) while waiting, a drawn green
          // check once sudo is through.
          Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Style.space(60)
            height: Style.space(66)

            Text {
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: parent.top
              textFormat: Text.PlainText
              text: "󰈷"
              color: root.sensorColor
              font.family: Style.font.menuFamily
              font.pixelSize: Style.space(56)
              opacity: root.matched ? 0 : 1
              Behavior on opacity { NumberAnimation { duration: Style.duration(140) } }
            }

            Rectangle {
              width: Style.space(56)
              height: width
              radius: width / 2
              anchors.horizontalCenter: parent.horizontalCenter
              anchors.top: parent.top
              color: root.matchColor
              opacity: root.matched ? 1 : 0
              scale: root.matched ? 1 : 0.9
              Behavior on opacity { NumberAnimation { duration: Style.duration(140) } }
              Behavior on scale { NumberAnimation { duration: Style.duration(180); easing.type: Easing.OutCubic } }

              Canvas {
                anchors.fill: parent
                onPaint: {
                  var ctx = getContext("2d")
                  var w = width
                  ctx.reset()
                  ctx.strokeStyle = "#ffffff"
                  ctx.lineWidth = w * 0.09
                  ctx.lineCap = "round"
                  ctx.lineJoin = "round"
                  ctx.beginPath()
                  ctx.moveTo(w * 0.29, w * 0.52)
                  ctx.lineTo(w * 0.44, w * 0.66)
                  ctx.lineTo(w * 0.72, w * 0.37)
                  ctx.stroke()
                }
              }
            }
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.PlainText
            text: "sudo"
            color: root.textColor
            font.family: root.sansFamily
            font.pixelSize: Style.space(15)
            font.weight: Font.Bold
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.PlainText
            text: root.command ? strings.t("message.command").arg(root.command) : strings.t("message.plain")
            color: root.textColor
            font.family: root.sansFamily
            font.pixelSize: Style.space(12)
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
          }

          Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.PlainText
            text: strings.t("hint")
            color: root.textColor
            opacity: 0.6
            font.family: root.sansFamily
            font.pixelSize: Style.space(11)
            wrapMode: Text.Wrap
            topPadding: Style.space(4)
          }
        }
      }
    }
  }
}
