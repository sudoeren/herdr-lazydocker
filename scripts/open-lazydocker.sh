#!/usr/bin/env bash
# Toggle lazydocker in a split pane: OPEN if absent in the focused tab,
# FOCUS (zoom on/off) if present but unfocused, CLOSE if it is the focused pane.
# Mirrors herdr-file-viewer's launch_decision, reimplemented in jq.
set -uo pipefail

herdr_bin="${HERDR_BIN_PATH:-herdr}"

# Root lazydocker at the invoking pane's directory, not the plugin install dir
# (herdr starts pane commands from the plugin root). Context JSON is injected
# by herdr on action invoke; fall back to the focused pane's cwd, then HOME.
target_cwd() {
  local cwd=""
  if command -v jq >/dev/null 2>&1; then
    cwd="$(printf '%s' "${HERDR_PLUGIN_CONTEXT_JSON:-}" | jq -r '
      (.focused_pane_cwd // .workspace_cwd // .cwd // "")' 2>/dev/null)" || cwd=""
    if [ -z "$cwd" ]; then
      cwd="$("$herdr_bin" pane list 2>/dev/null | jq -r '
        [.result.panes[]? | select(.focused == true)][0].cwd // ""' 2>/dev/null)" || cwd=""
    fi
  fi
  [ -d "$cwd" ] || cwd="$HOME"
  printf '%s' "$cwd"
}

open_pane() {
  exec "$herdr_bin" plugin pane open \
    --plugin herdr-lazydocker --entrypoint lazydocker \
    --placement split --direction right --focus \
    --cwd "$(target_cwd)"
}

command -v jq >/dev/null 2>&1 || open_pane
panes="$("$herdr_bin" pane list 2>/dev/null)" || open_pane
[ -n "$panes" ] || open_pane

# Decide OPEN / "FOCUS <id>" / "CLOSE <id>". Only a lazydocker pane in the focused
# pane's tab counts; ids must be flag-safe (never start with "-") before they
# reach an argv.
decision="$(printf '%s' "$panes" | jq -r '
  def safe: type == "string" and length > 0 and (test("^[A-Za-z0-9_:.][A-Za-z0-9_:.-]*$"));
  (.result.panes // []) as $panes
  | ($panes | map(select(.focused == true)) | first) as $focused
  | if $focused == null then "OPEN"
    else
      ($panes | map(select(.label == "lazydocker" and .tab_id == $focused.tab_id)) | first) as $ld
      | if $ld == null or (($ld.pane_id // "") | safe | not) then "OPEN"
        elif $ld.pane_id == $focused.pane_id then "CLOSE \($ld.pane_id)"
        else "FOCUS \($ld.pane_id)"
        end
    end' 2>/dev/null)" || decision="OPEN"

case "$decision" in
  "FOCUS "*)
    pid="${decision#FOCUS }"
    "$herdr_bin" pane zoom "$pid" --on >/dev/null 2>&1 || true
    exec "$herdr_bin" pane zoom "$pid" --off
    ;;
  "CLOSE "*)
    pid="${decision#CLOSE }"
    exec "$herdr_bin" pane close "$pid"
    ;;
  *)
    open_pane
    ;;
esac
