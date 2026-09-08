#!/usr/bin/env bash
# Assembling the SDDM theme, and installing or removing it.
#
# Sourced by ../install.sh; not run on its own.

# ── Assemble ─────────────────────────────────────────────────────────────────
# Every rewrite below is checked, and fails loudly. See AGENTS.md "The greeter".
build_sddm() {
    local out="$1" dark="$2"

    rm -rf "$out"
    mkdir -p "$out"
    cp "$SDDM_SRC/Main.qml" "$SDDM_SRC/qmldir" "$SDDM_SRC/metadata.desktop" "$SDDM_SRC/theme.conf" "$out/"

    # theme.conf carries the palette choice, so the mode can also be flipped
    # later by editing one line in the installed copy.
    sed -i "s/^dark=.*/dark=$dark/" "$out/theme.conf"
    grep -q "^dark=$dark\$" "$out/theme.conf" || die "could not set the palette mode in theme.conf"

    # Theme and Icons: Quickshell's Singleton is a QObject with lifecycle
    # behaviour this theme has no use for, and plain QtObject is what the rest
    # of the file was already written against.
    local f
    for f in Theme Icons; do
        sed -e '/^import Quickshell$/d' \
            -e 's/^Singleton {$/QtObject {/' \
            "$SHELL_SRC/Config/$f.qml" > "$out/$f.qml"
        grep -q '^QtObject {$' "$out/$f.qml" \
            || die "$f.qml: the Singleton root did not match — has Config/$f.qml been restructured?"
    done

    # The one hand-written substitution. Theme.dark is backed by settings.json
    # in the shell, which the greeter cannot read: it runs as the sddm user and
    # your home directory is not world-readable. theme.conf takes its place.
    # SDDM hands theme.conf values to QML as strings, hence the compare.
    awk '
        /^    \/\/\/ Persisted in settings.json/ { skip = 1; hit = 1
            print "    /// The shell keeps this in settings.json and flips it live. The"
            print "    /// greeter cannot: it runs as the `sddm` user, and your home"
            print "    /// directory is not readable by it. Its mode comes from the"
            print "    /// theme.conf sitting next to this file instead. SDDM hands those"
            print "    /// values to QML as strings, which is what the compare is for."
            print "    readonly property bool dark: String(config.dark) === \"true\""
            next }
        skip && /^    function toggleDark/ { skip = 0; next }
        skip { next }
        { print }
        END { if (!hit) exit 3 }
    ' "$out/Theme.qml" > "$out/Theme.qml.new" \
        || die "Theme.qml: the settings-backed dark property did not match — has Config/Theme.qml been restructured?"
    mv "$out/Theme.qml.new" "$out/Theme.qml"

    # Components are copied whole minus their one import. Anything reaching
    # past qs.Config — BrutalCard wants Quickshell.Widgets, BrutalClockFace
    # wants the Time service — cannot come along, and is skipped by inspection
    # rather than by a hand-kept list that would quietly go stale.
    local skipped=()
    for f in "$SHELL_SRC"/Components/*.qml; do
        if grep -qE '^import (Quickshell|qs\.(Services|Modules))' "$f"; then
            skipped+=("$(basename "$f")")
            continue
        fi
        sed '/^import qs\.Config$/d' "$f" > "$out/$(basename "$f")"
    done
    [[ ${#skipped[@]} -eq 0 ]] || say "left behind (needs Quickshell): ${skipped[*]}"

    # The catch-all: anything Quickshell-shaped left here means the greeter
    # cannot load its own theme. Comments are stripped first, because they
    # discuss the very thing being searched for.
    local leaks
    leaks="$(find "$out" -name '*.qml' -print0 \
        | xargs -0 grep -nE 'Quickshell|qs\.[A-Z]|Settings\.' /dev/null \
        | sed -E 's;//.*$;;' \
        | grep -vE '^[^:]+:[0-9]+:[[:space:]]*(\*|/)' \
        | grep -E 'Quickshell|qs\.[A-Z]|Settings\.' || true)"
    if [[ -n "$leaks" ]]; then
        printf '%s\n' "$leaks" >&2
        die "the assembled theme still references Quickshell — see above"
    fi

    chmod -R a+rX "$out"
    say "assembled $(find "$out" -name '*.qml' | wc -l) QML files into $out ($([ "$dark" = true ] && echo dark || echo light))"
}

# The colour weston paints for the moment before the greeter maps. Read out of
# the palette the theme was just built with rather than written down again here,
# for the same reason the components are copied instead of duplicated.
palette_background() {
    local file="$1" mode="$2" want hex
    want="paletteLight"
    [[ "$mode" == true ]] && want="paletteDark"
    hex="$(awk -v want="$want" '
        index($0, "property QtObject " want) { inb = 1 }
        inb && /property color mantle:/ {
            if (match($0, /#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]/)) {
                print tolower(substr($0, RSTART + 1, 6)); exit
            }
        }' "$file")"
    [[ -n "$hex" ]] || die "could not read the $want mantle colour out of Theme.qml"
    printf '0xff%s' "$hex"
}

# Which palette the greeter is built with when no flag said so. A reinstall must
# not drag a dark login screen back into the light.
# What the *session* is set to, read straight out of settings.json. The
# installer runs as you, so unlike the greeter it can simply look.
session_mode() {
    local settings="${XDG_CONFIG_HOME:-$HOME/.config}/brutaldots/settings.json"
    [[ -r "$settings" ]] || return 1

    # Whitespace is stripped rather than parsed line by line, so this works
    # whether the file is pretty-printed or minified, and the theme object is
    # isolated before looking for `dark` so a same-named key anywhere else in
    # settings.json cannot answer for it.
    local compact theme
    compact="$(tr -d ' \t\n\r' < "$settings")"
    case "$compact" in
        *'"theme":{'*) ;;
        *) return 1 ;;
    esac
    theme="${compact#*\"theme\":\{}"
    theme="${theme%%\}*}"
    case "$theme" in
        *'"dark":true'*)  printf 'true';  return 0 ;;
        *'"dark":false'*) printf 'false'; return 0 ;;
    esac
    return 1
}

sddm_current_mode() {
    if [[ -n "$SDDM_MODE" ]]; then printf '%s' "$SDDM_MODE"; return; fi

    # The session is the source of truth: the login screen follows it, so
    # seeding from anything else means the first logout after installing shows
    # the wrong palette and there is nothing to trigger a correction until the
    # shell next starts. That is exactly the trap this used to set.
    local from_session
    if from_session="$(session_mode)" && [[ -n "$from_session" ]]; then
        printf '%s' "$from_session"
        return
    fi

    # No settings.json yet — first install, before the shell has ever run.
    local f
    for f in "$GREETER_STATE" "$SDDM_THEME_DIR/theme.conf"; do
        if [[ -r "$f" ]] && grep -q '^dark=true' "$f"; then printf 'true'; return; fi
    done
    printf 'false'
}


# ── The greeter ──────────────────────────────────────────────────────────────
# The only part of this installer that writes outside your home directory, and
# the only reason it ever asks for a password.
install_sddm() {
    local staging mode compositor_section previous stamp
    staging="$(mktemp -d)"
    mode="$(sddm_current_mode)"
    build_sddm "$staging/$SDDM_THEME_NAME" "$mode"

    say "the login screen installs system-wide, so this part needs sudo"
    sudo rm -rf "$SDDM_THEME_DIR"
    sudo mkdir -p "$(dirname "$SDDM_THEME_DIR")"
    sudo cp -r "$staging/$SDDM_THEME_NAME" "$SDDM_THEME_DIR"
    sudo chown -R root:root "$SDDM_THEME_DIR"
    say "installed $SDDM_THEME_DIR"

    # ── Let the login screen follow the session ──────────────────────────────
    # The real theme.conf lives here, owned by you, with a symlink from the
    # root-owned theme directory. See AGENTS.md "Dark mode follows the session".
    sudo install -d -o "$(id -un)" -g "$(id -gn)" -m 755 "$(dirname "$GREETER_STATE")"
    if [[ -f "$GREETER_STATE" ]]; then
        # Yours already, including any message= and label= you set. Only the
        # palette line is touched.
        sed -i "s/^dark=.*/dark=$mode/" "$GREETER_STATE"
        say "kept your existing $GREETER_STATE (palette set from your session)"
    else
        install -m 644 "$staging/$SDDM_THEME_NAME/theme.conf" "$GREETER_STATE"
        say "created $GREETER_STATE"
    fi
    sudo ln -sfn "$GREETER_STATE" "$SDDM_THEME_DIR/theme.conf"
    say "the login screen now follows the session's dark mode"

    # sddm.conf(5) is explicit that the plain file is read last and outranks
    # everything in sddm.conf.d, so a drop-in naming the theme would be written,
    # look right, and do nothing.
    stamp="$(date +%Y%m%d%H%M%S)"
    if [[ -f "$SDDM_CONF" ]]; then
        sudo cp "$SDDM_CONF" "$SDDM_CONF.brutaldots.$stamp"
        say "backed up $SDDM_CONF to $SDDM_CONF.brutaldots.$stamp"
        previous="$(grep -oP '^\s*Current\s*=\s*\K.*' "$SDDM_CONF" | tail -1 || true)"
        [[ -n "$previous" ]] && say "it was pointing at: $previous"

        # Rewrite only the line that names the theme. Anything else in there is
        # somebody's deliberate configuration and none of this script's business.
        awk -v theme="$SDDM_THEME_NAME" '
            /^[[:space:]]*\[/ { in_theme = ($0 ~ /^[[:space:]]*\[Theme\][[:space:]]*$/) }
            in_theme && /^[[:space:]]*Current[[:space:]]*=/ { print "Current=" theme; seen = 1; next }
            { print }
            END { if (!seen) { print ""; print "[Theme]"; print "Current=" theme } }
        ' "$SDDM_CONF" > "$staging/sddm.conf"
    else
        printf '[Theme]\nCurrent=%s\n' "$SDDM_THEME_NAME" > "$staging/sddm.conf"
    fi
    sudo install -Dm644 "$staging/sddm.conf" "$SDDM_CONF"
    say "pointed $SDDM_CONF at $SDDM_THEME_NAME"

    # The compositor is not optional. SDDM runs the greeter on
    # "weston --shell=kiosk", and kiosk-shell binds a client to one output: on
    # more than one monitor the greeter appears on the first and the rest stay
    # black. There is no reason to ship that as a choice.
    sed "s/@BACKGROUND@/$(palette_background "$staging/$SDDM_THEME_NAME/Theme.qml" "$mode")/" \
        "$REPO/sddm/weston.ini" > "$staging/weston.ini"
    grep -q '^background-color=0xff[0-9a-f]\{6\}$' "$staging/weston.ini" \
        || die "the weston background colour was not substituted"
    sudo install -Dm644 "$staging/weston.ini" "$WESTON_INI"

    # CompositorCommand lives in [Wayland], not [General], and SDDM does not
    # complain if you get it wrong. Read the section back rather than trust it.
    compositor_section="$(awk '
        /^\[/ { s = $0 }
        /^[[:space:]]*CompositorCommand[[:space:]]*=/ { print s; exit }
    ' /usr/lib/sddm/sddm.conf.d/default.conf 2>/dev/null || true)"
    if [[ -z "$compositor_section" ]]; then
        compositor_section="[Wayland]"
        warn "could not find CompositorCommand in SDDM's defaults; assuming $compositor_section"
    fi

    sudo install -Dm644 /dev/stdin "$COMPOSITOR_DROPIN" <<CONF
# Written by ./install.sh.
#
# SDDM's default greeter compositor is weston with its kiosk shell, which binds
# a client to one output: the greeter makes one window per monitor and all of
# them land on the first. desktop-shell honours the per-output fullscreen
# request instead. See $WESTON_INI.
$compositor_section
CompositorCommand=weston --shell=desktop --config=$WESTON_INI
CONF
    say "installed $WESTON_INI and pointed the greeter's compositor at it"

    rm -rf "$staging"

    say "log out to see it."
    if grep -rqiE '^[[:space:]]*InputMethod[[:space:]]*=[[:space:]]*\S' \
        "$SDDM_CONF" /etc/sddm.conf.d/ 2>/dev/null; then
        warn "Qt's on-screen keyboard is enabled (InputMethod= in your sddm config)"
        warn "and will cover the login card. Clear it unless you want it."
    fi
}

uninstall_sddm() {
    local backup
    [[ -d "$SDDM_THEME_DIR" || -e "$COMPOSITOR_DROPIN" || -e "$WESTON_INI" ]] || return 0

    say "removing the login screen needs sudo"
    backup="$(ls -d "$SDDM_CONF".brutaldots.* 2>/dev/null | sort | tail -1 || true)"
    if [[ -n "$backup" ]]; then
        sudo cp "$backup" "$SDDM_CONF"
        say "restored $SDDM_CONF from $backup"
    else
        warn "no $SDDM_CONF backup found. If it still names $SDDM_THEME_NAME,"
        warn "point it at a theme you have *before* logging out."
    fi
    sudo rm -rf "$SDDM_THEME_DIR"
    sudo rm -f "$COMPOSITOR_DROPIN" "$WESTON_INI"
    sudo rm -rf "$(dirname "$GREETER_STATE")"
    say "removed the greeter, its compositor configuration and $GREETER_STATE"
}


