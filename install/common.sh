#!/usr/bin/env bash
# Output helpers, and the cursor the checklist hides.
#
# Sourced by ../install.sh; not run on its own.

say()  { printf '\033[1m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31mxx\033[0m %s\n' "$*" >&2; exit 1; }

# The checklist hides the terminal cursor; bring it back however we leave —
# but only if it was actually hidden, or every non-interactive run ends by
# spitting an escape sequence into whatever is capturing its output.
_cursor_hidden=0
trap '(( _cursor_hidden )) && printf "\033[?25h" || true' EXIT
