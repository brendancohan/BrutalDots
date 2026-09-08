pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import qs.Config

/// Default sink/source volume, exposed as plain 0-1 reals the UI can bind to.
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property bool muted: root.sink?.audio?.muted ?? false
    readonly property real micVolume: root.source?.audio?.volume ?? 0
    readonly property bool micMuted: root.source?.audio?.muted ?? false

    /// Nerd Font glyph matching the current level.
    readonly property string icon: root.muted || root.volume <= 0.001 ? Icons.volumeMute
        : root.volume < 0.34 ? Icons.volumeLow
        : root.volume < 0.67 ? Icons.volumeMed
        : Icons.volumeHigh

    function setVolume(value: real): void {
        if (!root.sink?.audio) return;
        root.sink.audio.muted = false;
        root.sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMute(): void {
        if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted;
    }

    function toggleMicMute(): void {
        if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted;
    }

    // ── Devices ─────────────────────────────────────────────────────────────

    readonly property var allNodes: Pipewire.nodes?.values ?? []

    /// Real hardware, not application streams: a browser playing audio is a
    /// node too, and picking it as your "output device" means nothing.
    /// Active device first, then alphabetical. A machine with HDMI, USB and
    /// every headset it has ever seen can list a dozen of these, and the one
    /// you are listening through should never be the one you have to scroll to.
    function order(nodes: var, current: var): var {
        return [...nodes].sort((a, b) => {
            const ac = current && a.id === current.id;
            const bc = current && b.id === current.id;
            if (ac !== bc) return ac ? -1 : 1;
            return root.label(a).localeCompare(root.label(b));
        });
    }

    readonly property var sinks: root.order(
        root.allNodes.filter(n => n.isSink && !n.isStream && n.audio), root.sink)
    readonly property var sources: root.order(
        root.allNodes.filter(n => !n.isSink && !n.isStream && n.audio), root.source)

    /// What to call a device. `description` is the human-readable one;
    /// `nickname` is shorter but often missing, and `name` is the raw
    /// alsa_output.pci-0000_03_00.1 form nobody wants to read.
    function label(node: var): string {
        if (!node) return "";
        return node.description || node.nickname || node.name || "";
    }

    function setSink(node: var): void {
        if (node) Pipewire.preferredDefaultAudioSink = node;
    }

    function setSource(node: var): void {
        if (node) Pipewire.preferredDefaultAudioSource = node;
    }

    /// Find a device by a fragment of its name and make it the default.
    /// Returns whether anything matched.
    function selectByName(nodes: var, match: string, apply: var): bool {
        const needle = (match ?? "").trim().toLowerCase();
        if (needle === "") return false;
        const hit = nodes.find(n => root.label(n).toLowerCase().includes(needle));
        if (!hit) {
            console.warn("Audio: no device matching", JSON.stringify(match));
            return false;
        }
        apply(hit);
        return true;
    }

    function selectSink(match: string): void {
        root.selectByName(root.sinks, match, n => root.setSink(n));
    }

    function selectSource(match: string): void {
        root.selectByName(root.sources, match, n => root.setSource(n));
    }

    function setMicVolume(value: real): void {
        if (!root.source?.audio) return;
        root.source.audio.muted = false;
        root.source.audio.volume = Math.max(0, Math.min(1, value));
    }

    // Binding to `audio` sub-objects only works while they are tracked. The
    // device lists are tracked too, so the menu can show each one's own level
    // rather than only the default's.
    PwObjectTracker {
        objects: [root.sink, root.source, ...root.sinks, ...root.sources]
    }
}
