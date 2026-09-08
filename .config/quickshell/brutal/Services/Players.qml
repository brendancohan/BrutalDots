pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

/**
 * Picks one "current" MPRIS player for the bar and dashboard to follow.
 *
 * Preference order: whatever is actually playing, else the first player that
 * can be controlled. Without this, a paused browser tab tends to win over the
 * music player the user is actually listening to.
 */
Singleton {
    id: root

    /// Every controllable player, minus the proxies.
    ///
    /// playerctld republishes whichever player is current under its own bus
    /// name, so it appears alongside the real one with the same identity and
    /// the same track. Left in, a switcher lists everything twice.
    readonly property list<MprisPlayer> all: Mpris.players.values.filter(
        player => !String(player.dbusName).endsWith(".playerctld"))

    property MprisPlayer active: null

    /// A player the user chose from the switcher. Kept until it goes away, so
    /// an explicit choice is not undone the moment something else starts.
    property MprisPlayer pinned: null

    readonly property bool hasPlayer: root.active !== null
    readonly property bool isPlaying: root.active?.isPlaying ?? false
    readonly property string title: root.active?.trackTitle ?? ""
    readonly property string artist: root.active?.trackArtist ?? ""
    readonly property string album: root.active?.trackAlbum ?? ""
    readonly property string artUrl: root.active?.trackArtUrl ?? ""
    readonly property real position: root.active?.position ?? 0
    readonly property real length: root.active?.length ?? 0
    readonly property real progress: root.length > 0
        ? Math.max(0, Math.min(1, root.position / root.length)) : 0

    /// Choose a player explicitly, and remember that it was chosen.
    function select(player: var): void {
        root.pinned = player;
        root.active = player;
    }

    function pick(): void {
        const players = root.all;
        if (players.length === 0) {
            root.active = null;
            root.pinned = null;
            return;
        }
        // An explicit choice outranks the heuristic, but only while it exists.
        if (root.pinned && players.indexOf(root.pinned) !== -1) {
            root.active = root.pinned;
            return;
        }
        root.pinned = null;
        root.active = players.find(p => p.isPlaying)
            ?? players.find(p => p.canControl)
            ?? players[0];
    }

    function playPause(): void { if (root.active?.canTogglePlaying) root.active.togglePlaying(); }
    function next(): void { if (root.active?.canGoNext) root.active.next(); }
    function previous(): void { if (root.active?.canGoPrevious) root.active.previous(); }

    function seek(fraction: real): void {
        if (root.active?.canSeek && root.length > 0)
            root.active.position = fraction * root.length;
    }

    /// mm:ss for a time in seconds.
    function formatTime(seconds: real): string {
        if (!isFinite(seconds) || seconds < 0) return "0:00";
        const m = Math.floor(seconds / 60);
        const s = Math.floor(seconds % 60);
        return `${m}:${s.toString().padStart(2, "0")}`;
    }

    onAllChanged: root.pick()
    Component.onCompleted: root.pick()

    // Re-evaluate when the chosen player stops, so we hand over to whatever
    // started playing instead.
    Connections {
        target: root.active
        function onIsPlayingChanged(): void {
            if (!root.active.isPlaying) Qt.callLater(root.pick);
        }
    }

    // MPRIS position is not push-based; poll it while something is playing.
    Timer {
        interval: 1000
        running: root.isPlaying
        repeat: true
        onTriggered: {
            if (root.active?.positionSupported) root.active.positionChanged();
        }
    }
}
