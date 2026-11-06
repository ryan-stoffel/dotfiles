import QtQuick
import QtQuick.Effects
import QtMultimedia
import qs.Commons
import qs.Commons as Commons
import qs.Ui

Item {
  id: root

  property string backgroundPath: ""
  property string videoPosterPath: ""
  property int backgroundVersion: 0
  property bool fingerprintConfigured: false
  property bool fingerprintUnavailable: false
  property bool authenticatingPassword: false
  property string failureMessage: ""
  property int failedAttempts: 0
  property bool inputEnabled: true
  property bool loadBackground: true
  // Plays a video wallpaper live. The service turns it off while the display is blanked.
  property bool playVideo: false
  property string userName: ""
  // A finger is on the sensor; the fingerprint icon pulses while it reads.
  property bool fingerReading: false
  // Increments on each failed read; every change shakes the field.
  property int fingerprintMismatches: 0
  property string passwordText: ""
  property bool syncingPasswordText: false

  readonly property string placeholderText: Commons.I18n.t("lock.enterPassword")
  readonly property int fieldWidth: 300
  readonly property int fieldHeight: 46
  readonly property int outlineThickness: 2
  readonly property int fieldFontSize: Style.font.heading
  readonly property int passwordDotFontSize: Math.round(Style.font.heading * 1.33)
  readonly property int passwordDotLetterSpacing: Math.round(Style.font.heading * 0.19)
  // Space to keep clear on each side of the field for the fingerprint icon
  // (icon width plus a gap) so the centered dots never run under it.
  readonly property real fingerprintReserve: fingerprintConfigured ? Math.round(fingerprintIcon.implicitWidth + 12) : 0
  // Shrink the dots to fit once the password outgrows the field, so every
  // keystroke stays visible — otherwise long passwords clip with no feedback.
  readonly property real passwordDotScale: dotMetrics.advanceWidth > 0
    ? Math.min(1, (passwordInput.width - 4) / dotMetrics.advanceWidth)
    : 1
  readonly property bool showPasswordCursor: inputEnabled && !authenticatingPassword && failureMessage.length === 0
  readonly property bool errorState: failureMessage.length > 0
  readonly property var inputBorderSpec: errorState
    ? Border.surfaceSpec("lock", "border-error", Commons.Color.lock.borderError, root.outlineThickness, "border-alpha")
    : Border.surfaceSpec("lock", "border-active", Commons.Color.lock.borderActive, root.outlineThickness, "border-alpha")

  // A video wallpaper shows its poster until the live video has a frame.
  readonly property bool video: Util.isVideoPath(root.backgroundPath)

  signal submitPassword(string password)
  signal passwordTextEdited(string password)
  signal clearFailureRequested()
  signal wakeRequested()

  function forcePasswordFocus() {
    passwordInput.forceActiveFocus()
  }

  function clearPassword() {
    passwordTextEdited("")
  }

  // Waking a DPMS-blanked display can stall the compositor for seconds while
  // the monitor modesets, so the wake key's release arrives late and client-side
  // key repeat floods the field with that character. A held key has no business
  // typing a password; only holding Backspace/Delete to clear stays useful.
  function dropsAutoRepeat(key) {
    return key !== Qt.Key_Backspace && key !== Qt.Key_Delete
  }

  function syncPasswordText() {
    if (passwordInput.text === passwordText) return
    syncingPasswordText = true
    passwordInput.text = passwordText
    syncingPasswordText = false
  }

  // The field loses focus while a password is checked (it is disabled then),
  // and forcing focus onto it would not stick until the check ends.
  function restorePasswordFocus() {
    if (inputEnabled && passwordInput.enabled && !passwordInput.activeFocus) forcePasswordFocus()
  }

  onPasswordTextChanged: syncPasswordText()
  onFingerprintMismatchesChanged: {
    shake.restart()
    mismatchNotice.restart()
  }
  onInputEnabledChanged: {
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  // A VT switch, which the NVIDIA driver forces around every suspend, takes the
  // keyboard away and Qt drops the field's focus with it. Nothing gives it back
  // when the keyboard returns, so typing went nowhere until the field was clicked.
  Window.onActiveFocusItemChanged: Qt.callLater(restorePasswordFocus)
  Component.onCompleted: {
    syncPasswordText()
    if (inputEnabled) Qt.callLater(forcePasswordFocus)
  }

  // Measures the masked password at full size; passwordDotScale compares this
  // against the field width to decide how far the dots must shrink to fit.
  TextMetrics {
    id: dotMetrics
    font.family: Style.font.family
    font.pixelSize: root.passwordDotFontSize
    font.letterSpacing: root.passwordDotLetterSpacing
    text: "●".repeat(passwordInput.text.length)
  }

  Rectangle {
    anchors.fill: parent
    color: Commons.Color.background

    BackgroundMedia {
      id: wallpaper
      objectName: "lockWallpaper"
      anchors.fill: parent
      path: root.loadBackground ? (root.video ? root.videoPosterPath : root.backgroundPath) : ""
      version: root.backgroundVersion
      // Decode only once sized, at the lock's own size: an unsized first
      // request decoded the file at its native resolution, then again once
      // sized. That size is what the lock service keeps decoded ahead of the
      // lock, so the first frame has the wallpaper.
      cached: true
      constrainDecode: true
      decodeSize: Qt.size(width, height)
    }

    Video {
      id: liveWallpaper
      anchors.fill: parent
      visible: root.video && root.loadBackground
      source: visible ? Util.fileUrl(root.backgroundPath) : ""
      fillMode: VideoOutput.PreserveAspectCrop
      loops: MediaPlayer.Infinite
      muted: true
      // Stays transparent until it decodes, so the poster shows instead of black.
      opacity: playbackState === MediaPlayer.PlayingState ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 300 } }

      readonly property bool shouldPlay: visible && root.playVideo
      onShouldPlayChanged: shouldPlay ? play() : pause()
      onSourceChanged: if (shouldPlay) play()
    }

    // Darkens the top and bottom edges so the clock and prompt read on any wallpaper.
    Rectangle {
      anchors.fill: parent
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.35) }
        GradientStop { position: 0.35; color: "transparent" }
        GradientStop { position: 0.7; color: "transparent" }
        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.45) }
      }
    }

    Column {
      id: clock
      anchors.top: parent.top
      anchors.topMargin: Math.round(parent.height * 0.08)
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 0

      property date now: new Date()
      Timer {
        interval: 1000
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: clock.now = new Date()
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        text: Qt.formatDate(clock.now, "dddd, MMMM d")
        color: Commons.Color.lock.text
        font.family: Style.font.family
        font.pixelSize: Math.round(Style.font.display * 0.9)
        font.weight: Font.Medium
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter
        // 12-hour like the bar clock, without the AM/PM suffix.
        text: Qt.formatTime(clock.now, "h:mm AP").replace(/\s*[AP]M$/i, "")
        color: Commons.Color.lock.text
        font.family: Style.font.family
        font.pixelSize: Math.round(Style.font.display * 4.5)
        font.weight: Font.Bold
      }

      layer.enabled: true
      layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.5)
        shadowBlur: 0.6
      }
    }

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onClicked: { root.wakeRequested(); root.forcePasswordFocus() }
      onPositionChanged: root.wakeRequested()
    }

    BorderSurface {
      id: inputField
      width: root.fieldWidth
      height: root.fieldHeight
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Math.round(parent.height * 0.1)
      color: Util.alpha(Commons.Color.lock.background, 0.55)
      borderSpec: root.inputBorderSpec
      radius: height / 2
      clip: true

      SequentialAnimation {
        id: shake
        loops: 1
        NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: -14; duration: 50 }
        NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: 14; duration: 80 }
        NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: -8; duration: 70 }
        NumberAnimation { target: inputField; property: "anchors.horizontalCenterOffset"; to: 0; duration: 60 }
      }

      TextInput {
        id: passwordInput
        anchors.fill: parent
        anchors.topMargin: inputField.borderTop
        // Reserve the fingerprint icon's width on both sides so the centered
        // dots stay symmetric and never slide under the icon as they grow.
        anchors.rightMargin: inputField.borderRight + 18 + root.fingerprintReserve
        anchors.bottomMargin: inputField.borderBottom
        anchors.leftMargin: inputField.borderLeft + 18 + root.fingerprintReserve
        verticalAlignment: TextInput.AlignVCenter
        horizontalAlignment: TextInput.AlignHCenter
        activeFocusOnPress: true
        clip: true
        enabled: root.inputEnabled && !root.authenticatingPassword
        readOnly: root.authenticatingPassword
        echoMode: TextInput.Password
        passwordCharacter: "\u25CF"
        passwordMaskDelay: 0
        color: Commons.Color.lock.text
        selectionColor: Commons.Color.lock.selection
        selectedTextColor: Commons.Color.lock.text
        font.family: Style.font.family
        font.pixelSize: text.length > 0 ? Math.max(1, Math.floor(root.passwordDotFontSize * root.passwordDotScale)) : root.fieldFontSize
        font.letterSpacing: text.length > 0 ? root.passwordDotLetterSpacing * root.passwordDotScale : 0
        cursorVisible: activeFocus && root.showPasswordCursor && text.length > 0
        cursorDelegate: Rectangle {
          width: 2
          color: Commons.Color.lock.text
          visible: passwordInput.cursorVisible
        }

        onTextChanged: {
          if (!root.syncingPasswordText) root.passwordTextEdited(text)
          if (text.length > 0) {
            root.wakeRequested()
          }
          if (text.length > 0 && root.failureMessage.length > 0) root.clearFailureRequested()
        }

        onAccepted: {
          var submitted = root.passwordText
          root.passwordTextEdited("")
          if (submitted.length > 0) root.submitPassword(submitted)
        }

        Keys.onPressed: function(event) {
          root.wakeRequested()
          if (event.isAutoRepeat && root.dropsAutoRepeat(event.key)) {
            event.accepted = true
            return
          }
          if (event.key === Qt.Key_Escape || (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_U)) {
            root.passwordTextEdited("")
            event.accepted = true
          }
        }
      }

      Text {
        textFormat: Text.PlainText
        anchors.fill: passwordInput
        text: root.authenticatingPassword ? Commons.I18n.t("lock.checking") : (root.failureMessage.length > 0 ? root.failureMessage : root.placeholderText)
        visible: passwordInput.text.length === 0
        color: root.authenticatingPassword ? Commons.Color.lock.text : (root.failureMessage.length > 0 ? Commons.Color.lock.textError : Commons.Color.lock.placeholder)
        font.family: Style.font.family
        font.pixelSize: root.fieldFontSize
        font.italic: !root.authenticatingPassword && root.failureMessage.length > 0
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
      }

      // Fingerprint hint pinned inside the field's right edge when a sensor is
      // enrolled, so the user knows they can touch to unlock instead of typing.
      // Matches hyprlock, which draws its fingerprint icon in the same spot.
      // A reader the shell cannot reach crosses out rather than disappears, so
      // it stops inviting touches that can never unlock.
      Text {
        id: fingerprintIcon
        objectName: "fingerprintIndicator"
        textFormat: Text.PlainText
        anchors.right: parent.right
        anchors.rightMargin: inputField.borderRight + 18
        anchors.verticalCenter: parent.verticalCenter
        visible: root.fingerprintConfigured
        text: root.fingerprintUnavailable ? "󰺱" : "󰈷"
        color: root.fingerprintUnavailable ? Commons.Color.lock.textError
          : (root.fingerReading ? Commons.Color.lock.borderActive
          : (mismatchNotice.running ? Commons.Color.lock.textError : Commons.Color.lock.placeholder))
        Behavior on color { ColorAnimation { duration: 150 } }

        SequentialAnimation on scale {
          running: root.fingerReading
          loops: Animation.Infinite
          onStopped: fingerprintIcon.scale = 1
          NumberAnimation { to: 1.3; duration: 350; easing.type: Easing.OutQuad }
          NumberAnimation { to: 1.0; duration: 350; easing.type: Easing.InQuad }
        }
        font.family: Style.font.family
        font.pixelSize: Math.round(root.fieldFontSize * 1.1)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
      }
    }

    Text {
      objectName: "lockUserName"
      textFormat: Text.PlainText
      anchors.bottom: inputField.top
      anchors.bottomMargin: 16
      anchors.horizontalCenter: inputField.horizontalCenter
      text: root.userName
      color: Commons.Color.lock.text
      font.family: Style.font.family
      font.pixelSize: Math.round(Style.font.display * 0.9)
      font.weight: Font.DemiBold
      layer.enabled: true
      layer.effect: MultiEffect { shadowEnabled: true; shadowColor: Qt.rgba(0, 0, 0, 0.5); shadowBlur: 0.5 }
    }

    // Tells the user Touch ID works without typing; fprintd is already listening.
    Text {
      objectName: "touchIdHint"
      textFormat: Text.PlainText
      anchors.top: inputField.bottom
      anchors.topMargin: 14
      anchors.horizontalCenter: inputField.horizontalCenter
      visible: root.fingerprintConfigured && !root.fingerprintUnavailable
      text: root.fingerReading ? "Reading…" : (mismatchNotice.running ? "Not recognized, try again" : "Touch ID or Enter Password")
      color: mismatchNotice.running && !root.fingerReading ? Commons.Color.lock.textError : Commons.Color.lock.text

      // Keeps the mismatch message up briefly after a failed read.
      Timer { id: mismatchNotice; interval: 2000 }
      opacity: 0.8
      font.family: Style.font.family
      font.pixelSize: Style.font.heading
    }

    // The crossed-out icon has no meaning to a user who has never seen it — it
    // is not intuitive that it signals a broken reader — so the words carry the
    // explanation and the icon only reinforces it.
    Text {
      objectName: "fingerprintUnavailableNotice"
      textFormat: Text.PlainText
      anchors.top: inputField.bottom
      anchors.topMargin: 18
      anchors.horizontalCenter: inputField.horizontalCenter
      visible: root.fingerprintConfigured && root.fingerprintUnavailable
      text: Commons.I18n.t("lock.fingerprintUnavailable")
      color: Commons.Color.lock.textError
      font.family: Style.font.family
      font.pixelSize: Style.font.heading
      font.italic: true
      horizontalAlignment: Text.AlignHCenter
    }
  }
}
