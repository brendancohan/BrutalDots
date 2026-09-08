pragma Singleton

import Quickshell

/// Launch-time flags, read from the environment rather than settings.json
/// because they describe how this *run* should behave, not user preference.
Singleton {
    id: root

    /// BRUTALDOTS_PREVIEW=1 — run without reserving screen space, so the shell
    /// can be tried on top of a live session without moving any windows.
    readonly property bool preview: Quickshell.env("BRUTALDOTS_PREVIEW") === "1"
}
