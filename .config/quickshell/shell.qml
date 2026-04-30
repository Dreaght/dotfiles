import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

ShellRoot {
  id: root

  property string statePath: Quickshell.env("HOME") + "/.cache/waybar-docksync/state.json"
  property string cavaFramePath: Quickshell.env("HOME") + "/.cache/quickshell/cava-frame.txt"
  property int barCount: 64
  property var spectrum: Array.from({ length: barCount }, function() { return 0.08; })
  property bool docksyncConnected: false
  property bool liked: false
  property string coverPath: ""
  property string coverUrl: ""
  property real coverStamp: 0
  property real colorPhase: 0.0
  property real energy: 0.0
  property var activePlayer: null

  function pickPlayer() {
    const players = Mpris.players.values;
    if (!players || players.length === 0) return null;

    for (let i = 0; i < players.length; i += 1) {
      const player = players[i];
      const identity = (player.identity || "").toLowerCase();
      const entry = (player.desktopEntry || "").toLowerCase();
      const bus = (player.dbusName || "").toLowerCase();
      if (identity.includes("yandex") || entry.includes("yandex") || bus.includes("yandex")) return player;
    }

    for (let i = 0; i < players.length; i += 1) {
      if (players[i].isPlaying) return players[i];
    }

    return players[0];
  }

  function refreshPlayer() {
    activePlayer = pickPlayer();
  }

  function updateSpectrum(frame) {
    const parts = frame.trim().split(";");
    const values = [];
    let total = 0.0;

    for (let i = 0; i < barCount; i += 1) {
      const raw = i < parts.length ? parseInt(parts[i], 10) : 0;
      const safe = isNaN(raw) ? 0 : raw;
      const boosted = Math.pow(Math.min(1.0, safe / 64.0), 0.60);
      const previous = i < spectrum.length ? spectrum[i] : 0.04;
      const smoothed = Math.max(0.015, previous * 0.32 + boosted * 0.68);
      values.push(smoothed);
      total += smoothed;
    }

    spectrum = values;
    energy = Math.max(0.03, Math.min(1.0, total / barCount));
    if (panel.backingWindowVisible) {
      barsCanvas.requestPaint();
    }
  }

  function handleCavaFrame(frame) {
    updateSpectrum(frame);
  }

  function parseDockSyncState(text) {
    if (!text || text.trim() === "") return;

    try {
      const state = JSON.parse(text);
      docksyncConnected = !!state.connected;
      liked = state.liked === 1;
      coverPath = docksyncConnected && state.cover_path ? state.cover_path : "";
      coverUrl = docksyncConnected && state.cover_url ? state.cover_url : "";
      coverStamp = state.updated_at ? Number(state.updated_at) : Date.now();
    } catch (error) {
      console.log("Failed to parse DockSync state", error);
    }
  }

  function refreshDockSyncVisuals() {
    if (!docksyncConnected) return;
    Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/docksync-helper", "send", "coverImage"]);
    Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/docksync-helper", "send", "likeState"]);
  }

  function barColor(index, lightness) {
    return Qt.hsla((index / barCount + colorPhase) % 1.0, 0.88, lightness, 1.0);
  }

  function spectrumValue(index) {
    return index < spectrum.length ? spectrum[index] : 0.04;
  }

  component IconButton: Rectangle {
    id: button

    property string label: ""
    property string iconSource: ""
    property int iconVerticalOffset: 0
    property color baseColor: "white"
    property color idleBackground: "transparent"
    property color hoverBackground: "#22ffffff"
    property color pressedBackground: "#30ffffff"
    signal pressed

    width: 42
    height: 42
    radius: 21
    color: mouseArea.containsPress ? pressedBackground : (mouseArea.containsMouse ? hoverBackground : idleBackground)
    border.color: mouseArea.containsMouse ? "#55ffffff" : "transparent"
    border.width: 1

    Text {
      anchors.centerIn: parent
      visible: button.iconSource === ""
      text: button.label
      color: button.baseColor
      font.family: "Symbols Nerd Font"
      font.pixelSize: 22
    }

    Image {
      anchors.centerIn: parent
      anchors.verticalCenterOffset: button.iconVerticalOffset
      visible: button.iconSource !== ""
      width: 20
      height: 20
      source: button.iconSource
      fillMode: Image.PreserveAspectFit
      asynchronous: true
      cache: false
    }

    MouseArea {
      id: mouseArea
      anchors.fill: parent
      hoverEnabled: true
      onClicked: button.pressed()
    }
  }

  FileView {
    id: dockSyncState
    path: root.statePath
    preload: true
    watchChanges: true
    printErrors: false

    onLoaded: root.parseDockSyncState(text())
    onFileChanged: reload()
    onTextChanged: root.parseDockSyncState(text())
  }

  FileView {
    id: cavaFrame
    path: root.cavaFramePath
    preload: true
    watchChanges: true
    printErrors: false

    onLoaded: root.handleCavaFrame(text())
    onFileChanged: reload()
    onTextChanged: root.handleCavaFrame(text())
  }

  Process {
    id: cava
    running: true
    command: [
      Quickshell.shellPath("scripts/cava-feed"),
      Quickshell.shellPath("cava-panel.conf"),
      root.cavaFramePath
    ]
  }

  Timer {
    interval: 900
    repeat: true
    running: true
    onTriggered: root.refreshPlayer()
  }

  Timer {
    id: dockSyncRefreshDebounce
    interval: 250
    repeat: false
    onTriggered: root.refreshDockSyncVisuals()
  }

  Component.onCompleted: root.refreshPlayer()

  NumberAnimation on colorPhase {
    from: 0
    to: 1
    duration: 16000
    loops: Animation.Infinite
  }

  Connections {
    target: root.activePlayer
    ignoreUnknownSignals: true

    function onTrackTitleChanged() {
      dockSyncRefreshDebounce.restart();
    }

    function onTrackArtistChanged() {
      dockSyncRefreshDebounce.restart();
    }

    function onTrackAlbumChanged() {
      dockSyncRefreshDebounce.restart();
    }

    function onTrackArtUrlChanged() {
      dockSyncRefreshDebounce.restart();
    }
  }

  PanelWindow {
    id: panel
    visible: Quickshell.screens.length > 0
    screen: Quickshell.screens[0]
    anchors {
      top: true
      left: true
      right: true
    }
    margins {
      top: 8
      left: 8
      right: 8
    }
    exclusiveZone: 46
    aboveWindows: true
    focusable: false
    implicitHeight: 58
    color: "transparent"

    Rectangle {
      anchors.fill: parent
      clip: true
      radius: 26
      color: "transparent"

      Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
      }

      Item {
        id: visualizer
        width: Math.min(parent.width - 12, controlCapsule.width * 1.5)
        height: controlCapsule.height
        anchors.centerIn: controlCapsule
        property int innerPadding: 18

        Item {
          id: auraFrame
          width: Math.max(0, Math.min(parent.width, controlCapsule.width * 1.08))
          height: Math.max(0, parent.height - visualizer.innerPadding)
          anchors.centerIn: parent
        }

        Item {
          id: visualizerSource
          width: Math.max(0, auraFrame.width - visualizer.innerPadding * 2)
          height: auraFrame.height
          anchors.centerIn: auraFrame
          visible: false

          Canvas {
            anchors.fill: parent
            contextType: "2d"
            visible: false

            onPaint: {
              const ctx = getContext("2d");
              ctx.reset();
            }
          }

          Canvas {
            id: barsCanvas
            anchors.fill: parent
            contextType: "2d"
            visible: false

            onPaint: {
              const ctx = getContext("2d");
              ctx.reset();

              const gap = 1;
              const barWidth = Math.max(3, (width - (root.barCount - 1) * gap) / root.barCount);
              const midY = height * 0.5;

              for (let i = 0; i < root.barCount; i += 1) {
                const upper = root.spectrumValue(i);
                const lower = root.spectrumValue(root.barCount - 1 - i);
                const upperHeight = Math.max(3, height * (0.02 + upper * 0.56));
                const lowerHeight = Math.max(3, height * (0.02 + lower * 0.56));
                const x = i * (barWidth + gap);
                ctx.globalAlpha = 0.12 + upper * 0.58;
                ctx.fillStyle = "#ffffff";
                ctx.fillRect(x, midY - upperHeight, barWidth, upperHeight);

                ctx.globalAlpha = 0.10 + lower * 0.54;
                ctx.fillStyle = "#ffffff";
                ctx.fillRect(x, midY, barWidth, lowerHeight);

                ctx.globalAlpha = 0.05 + Math.max(upper, lower) * 0.10;
                ctx.fillStyle = "#ffffff";
                ctx.fillRect(x, midY - 1, barWidth, 2);
              }

              ctx.globalAlpha = 1.0;
            }
          }

          ShaderEffectSource {
            id: barsSource
            anchors.fill: barsCanvas
            sourceItem: barsCanvas
            hideSource: true
            live: true
            visible: false
          }

          ShaderEffect {
            id: auraShader
            anchors.fill: parent
            property variant spectrumSource: barsSource
            property real timePhase: root.colorPhase
            property real energy: root.energy
            property vector2d resolution: Qt.vector2d(width, height)
            fragmentShader: Quickshell.shellPath("shaders/audio_aura.frag.qsb")
          }
        }

        OpacityMask {
          anchors.fill: auraFrame
          source: visualizerSource
          maskSource: Rectangle {
            width: auraFrame.width
            height: auraFrame.height
            radius: controlCapsule.radius + 10
            color: "black"
          }
        }
      }

      Rectangle {
        id: controlCapsule
        width: Math.min(parent.width - 26, 840)
        height: 58
        anchors.centerIn: parent
        radius: 29
        color: "#7a0a0d14"
        border.color: "#26ffffff"
        border.width: 1
        clip: true

        Rectangle {
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.right: parent.right
          width: root.docksyncConnected && root.coverPath !== "" ? 126 : 0
          visible: root.docksyncConnected && root.coverPath !== ""
          color: "transparent"
          clip: true

          Item {
            id: coverMaskSource
            anchors.fill: parent
            visible: false

            Image {
              anchors.fill: parent
              source: root.docksyncConnected && root.coverPath !== "" ? ("file://" + root.coverPath + "?v=" + root.coverStamp) : ""
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: false
            }

            Rectangle {
              anchors.fill: parent
              gradient: Gradient {
                GradientStop { position: 0.0; color: "#2e070a10" }
                GradientStop { position: 0.45; color: "#12070a08" }
                GradientStop { position: 1.0; color: "#0c000000" }
              }
            }
          }

          OpacityMask {
            anchors.fill: parent
            source: coverMaskSource
            maskSource: Item {
              width: 126
              height: controlCapsule.height

              Rectangle {
                anchors.fill: parent
                radius: controlCapsule.radius
                color: "black"
              }

              Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width - controlCapsule.radius
                color: "black"
              }
            }
          }
        }

        Row {
          id: transportCluster
          anchors.left: parent.left
          anchors.leftMargin: 12
          anchors.verticalCenter: parent.verticalCenter
          spacing: 8

          IconButton {
            visible: root.docksyncConnected
            iconSource: root.liked ? Quickshell.shellPath("assets/heart-filled.svg") : Quickshell.shellPath("assets/heart-outline.svg")
            iconVerticalOffset: 1
            anchors.verticalCenter: parent.verticalCenter
            onPressed: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/docksync-helper", "send", "likeInteraction"])
          }

          IconButton {
            label: "󰒮"
            anchors.verticalCenter: parent.verticalCenter
            onPressed: if (root.activePlayer && root.activePlayer.canGoPrevious) root.activePlayer.previous()
          }

          IconButton {
            width: 48
            height: 48
            radius: 24
            label: root.activePlayer && root.activePlayer.isPlaying ? "󰏤" : "󰐊"
            baseColor: "#ffffff"
            anchors.verticalCenter: parent.verticalCenter
            onPressed: if (root.activePlayer && root.activePlayer.canTogglePlaying) root.activePlayer.togglePlaying()
          }

          IconButton {
            label: "󰒭"
            anchors.verticalCenter: parent.verticalCenter
            onPressed: if (root.activePlayer && root.activePlayer.canGoNext) root.activePlayer.next()
          }
        }

        Item {
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          anchors.right: parent.right
          anchors.rightMargin: root.docksyncConnected && root.coverPath !== "" ? 138 : 14
          width: 250

          Column {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            width: parent.width
            spacing: 2

            Text {
              width: parent.width
              text: root.activePlayer ? (root.activePlayer.trackTitle || "No active player") : "No active player"
              color: "#fff8f3"
              font.pixelSize: 15
              font.weight: Font.DemiBold
              elide: Text.ElideRight
              horizontalAlignment: Text.AlignRight
            }

            Text {
              width: parent.width
              text: root.activePlayer ? ((root.activePlayer.trackArtist || "") + ((root.activePlayer.trackAlbum || "") ? "  •  " + root.activePlayer.trackAlbum : "")) : ""
              color: "#d7dfef"
              opacity: 0.88
              font.pixelSize: 12
              elide: Text.ElideRight
              horizontalAlignment: Text.AlignRight
            }
          }
        }
      }
    }
  }
}
