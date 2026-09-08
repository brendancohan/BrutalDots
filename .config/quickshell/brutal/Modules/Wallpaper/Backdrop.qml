import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Config
import qs.Services

/**
 * The desktop background, drawn by the shell on a layer-shell surface it
 * already owns — so there is no wallpaper daemon to install, autostart or keep
 * pointed at the same file as everything else.
 *
 * With no image configured this paints a themed pattern rather than leaving a
 * black screen, which is also what a fresh install sees.
 */
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData

        readonly property var config: Settings.data.wallpaper

        screen: win.modelData
        visible: win.config.enabled
        color: Theme.color.mantle

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Never take space from tiled windows, never take a click: the desktop
        // is scenery. Without the empty mask, every click on an unoccupied part
        // of the screen would land here instead of falling through.
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "brutaldots-wallpaper"
        mask: Region {}

        // ── The image ──────────────────────────────────────────────────────
        Image {
            id: photo

            anchors.fill: parent
            visible: Wallpaper.path !== ""
            source: Wallpaper.path === "" ? "" : `file://${Wallpaper.path}`

            fillMode: {
                switch (win.config.mode) {
                case "fit":     return Image.PreserveAspectFit;
                case "stretch": return Image.Stretch;
                case "center":  return Image.Pad;
                case "tile":    return Image.Tile;
                default:        return Image.PreserveAspectCrop;
                }
            }

            // Decode at screen size rather than full resolution. A 6000px photo
            // otherwise costs ~140MB of texture per monitor for no visible gain.
            // Tiling is the exception: it needs the image at its own size.
            sourceSize.width: win.config.mode === "tile" ? 0 : win.width
            sourceSize.height: win.config.mode === "tile" ? 0 : win.height

            asynchronous: true
            cache: false
            mipmap: true

            // Only fade once the pixels are actually there, so switching
            // wallpapers does not flash the pattern underneath.
            opacity: photo.status === Image.Ready ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: Theme.anim.slow; easing.type: Theme.anim.curve }
            }
        }

        // ── The fallback pattern ───────────────────────────────────────────
        Canvas {
            id: pattern

            anchors.fill: parent
            visible: Wallpaper.path === "" || photo.status !== Image.Ready

            readonly property int spacing: Math.max(8, win.config.patternSpacing)
            readonly property string kind: win.config.pattern
            readonly property real strength: win.config.patternOpacity

            onSpacingChanged: pattern.requestPaint()
            onKindChanged: pattern.requestPaint()
            onStrengthChanged: pattern.requestPaint()

            onPaint: {
                const ctx = pattern.getContext("2d");
                const w = pattern.width;
                const h = pattern.height;

                ctx.reset();
                ctx.fillStyle = Theme.color.mantle;
                ctx.fillRect(0, 0, w, h);

                if (pattern.kind === "solid" || pattern.strength <= 0) return;

                ctx.globalAlpha = pattern.strength;
                ctx.strokeStyle = Theme.color.ink;
                ctx.fillStyle = Theme.color.ink;
                ctx.lineWidth = 2;

                const step = pattern.spacing;

                if (pattern.kind === "dots") {
                    // Offset by half a step so the grid of dots is not welded
                    // to the top-left corner of the screen.
                    for (let x = step / 2; x < w; x += step)
                        for (let y = step / 2; y < h; y += step) {
                            ctx.beginPath();
                            ctx.arc(x, y, 1.5, 0, Math.PI * 2);
                            ctx.fill();
                        }
                } else if (pattern.kind === "diagonal") {
                    // Start a full screen-height to the left so the sweep
                    // covers the top-right corner too.
                    ctx.beginPath();
                    for (let x = -h; x < w; x += step) {
                        ctx.moveTo(x, 0);
                        ctx.lineTo(x + h, h);
                    }
                    ctx.stroke();
                } else {
                    ctx.beginPath();
                    for (let x = 0; x <= w; x += step) {
                        ctx.moveTo(x, 0);
                        ctx.lineTo(x, h);
                    }
                    for (let y = 0; y <= h; y += step) {
                        ctx.moveTo(0, y);
                        ctx.lineTo(w, y);
                    }
                    ctx.stroke();
                }
            }
        }
    }
}
