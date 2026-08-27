#!/usr/bin/env bash
# Hermetic test suite: mocks the herdr CLI and asserts the launcher scripts'
# behavior against canned pane-list JSON. No live herdr server required.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

MOCK="$TMP/mock-herdr"
MOCK_LOG="$TMP/mock.log"
CASE_FILE="$TMP/case.json"
: > "$MOCK_LOG"

FAILURES=0
TESTS=0

pass() { TESTS=$((TESTS+1)); printf 'ok   %s\n' "$1"; }
fail() { TESTS=$((TESTS+1)); FAILURES=$((FAILURES+1)); printf 'FAIL %s\n' "$1"; }

cat > "$MOCK" <<'EOF'
#!/usr/bin/env bash
set -uo pipefail
case "${1:-}" in
  pane)
    shift
    case "${1:-}" in
      list) cat "${HERDR_MOCK_LIST:-/dev/null}" ;;
      zoom) printf '%s\n' "zoom $*" >> "${HERDR_MOCK_LOG:-/dev/null}" ;;
      close) printf '%s\n' "close $*" >> "${HERDR_MOCK_LOG:-/dev/null}" ;;
      *) printf '%s\n' "pane $*" >> "${HERDR_MOCK_LOG:-/dev/null}" ;;
    esac
    ;;
  plugin)
    shift
    printf '%s\n' "plugin $*" >> "${HERDR_MOCK_LOG:-/dev/null}"
    ;;
  tab)
    shift
    printf '%s\n' "tab $*" >> "${HERDR_MOCK_LOG:-/dev/null}"
    ;;
esac
EOF
chmod +x "$MOCK"

run_case() {
  local name="$1" list="$2" script="$3" expect="$4"
  printf '%s' "$list" > "$CASE_FILE"
  HERDR_MOCK_LIST="$CASE_FILE" HERDR_MOCK_LOG="$MOCK_LOG" \
    HERDR_BIN_PATH="$MOCK" bash "$script" >/dev/null 2>&1
  if grep -qF -- "$expect" "$MOCK_LOG"; then
    pass "$name"
  else
    fail "$name (expected: $expect; log: $(tr '\n' ';' < "$MOCK_LOG"))"
  fi
  : > "$MOCK_LOG"
}

SPLIT="$ROOT/scripts/open-lazydocker.sh"
TAB="$ROOT/scripts/open-lazydocker-tab.sh"

# --- static checks -----------------------------------------------------------

if bash -n "$SPLIT" && bash -n "$TAB"; then
  pass "scripts pass bash -n"
else
  fail "scripts pass bash -n"
fi

if python3 -c 'import tomllib, sys; tomllib.load(open(sys.argv[1], "rb"))' \
  "$ROOT/herdr-plugin.toml" 2>/dev/null; then
  pass "herdr-plugin.toml is valid TOML"
else
  fail "herdr-plugin.toml is valid TOML"
fi

manifest_version="$(sed -n 's/^version = "\(.*\)"/\1/p' "$ROOT/herdr-plugin.toml")"
if [ -n "$manifest_version" ]; then
  pass "herdr-plugin.toml has a version ($manifest_version)"
else
  fail "herdr-plugin.toml has a version"
fi

if ! grep -q '—\|–' "$ROOT/README.md"; then
  pass "README contains no em/en dashes"
else
  fail "README contains no em/en dashes"
fi

# --- split pane scenarios ----------------------------------------------------

run_case \
  "split: opens when absent" \
  '{"id":"cli:pane:list","result":{"panes":[{"pane_id":"w1:p1","tab_id":"w1:t1","label":null,"cwd":"/tmp/work","focused":true}]}}' \
  "$SPLIT" \
  "plugin pane open --plugin herdr-lazydocker --entrypoint lazydocker --placement split"

run_case \
  "split: focuses when open but unfocused" \
  '{"id":"cli:pane:list","result":{"panes":[
    {"pane_id":"w1:p1","tab_id":"w1:t1","label":null,"cwd":"/tmp/work","focused":true},
    {"pane_id":"w1:p2","tab_id":"w1:t1","label":"lazydocker","cwd":"/tmp/work","focused":false}]}}' \
  "$SPLIT" \
  "zoom w1:p2 --on"

run_case \
  "split: closes when focused" \
  '{"id":"cli:pane:list","result":{"panes":[{"pane_id":"w1:p2","tab_id":"w1:t1","label":"lazydocker","cwd":"/tmp/work","focused":true}]}}' \
  "$SPLIT" \
  "close w1:p2"

run_case \
  "split: ignores lazydocker in another tab" \
  '{"id":"cli:pane:list","result":{"panes":[
    {"pane_id":"w1:p1","tab_id":"w1:t1","label":null,"cwd":"/tmp/work","focused":true},
    {"pane_id":"w2:p5","tab_id":"w2:t9","label":"lazydocker","cwd":"/tmp/work","focused":false}]}}' \
  "$SPLIT" \
  "plugin pane open --plugin herdr-lazydocker --entrypoint lazydocker --placement split"

# --- tab scenarios -----------------------------------------------------------

run_case \
  "tab: opens when absent" \
  '{"id":"cli:pane:list","result":{"panes":[{"pane_id":"w1:p1","tab_id":"w1:t1","label":null,"cwd":"/tmp/work","focused":true}]}}' \
  "$TAB" \
  "plugin pane open --plugin herdr-lazydocker --entrypoint lazydocker --placement tab"

run_case \
  "tab: switches to lazydocker tab in same workspace" \
  '{"id":"cli:pane:list","result":{"panes":[
    {"pane_id":"w1:p1","tab_id":"w1:t1","label":null,"cwd":"/tmp/work","focused":true},
    {"pane_id":"w1:p2","tab_id":"w1:t2","label":"lazydocker","cwd":"/tmp/work","focused":false}]}}' \
  "$TAB" \
  "tab focus w1:t2"

run_case \
  "tab: focuses when in focused tab" \
  '{"id":"cli:pane:list","result":{"panes":[
    {"pane_id":"w1:p1","tab_id":"w1:t1","label":null,"cwd":"/tmp/work","focused":true},
    {"pane_id":"w1:p2","tab_id":"w1:t1","label":"lazydocker","cwd":"/tmp/work","focused":false}]}}' \
  "$TAB" \
  "zoom w1:p2 --on"

run_case \
  "tab: closes when focused" \
  '{"id":"cli:pane:list","result":{"panes":[{"pane_id":"w1:p2","tab_id":"w1:t1","label":"lazydocker","cwd":"/tmp/work","focused":true}]}}' \
  "$TAB" \
  "close w1:p2"

run_case \
  "tab: ignores lazydocker in another workspace" \
  '{"id":"cli:pane:list","result":{"panes":[
    {"pane_id":"w1:p1","tab_id":"w1:t1","label":null,"cwd":"/tmp/work","focused":true},
    {"pane_id":"w2:p5","tab_id":"w2:t9","label":"lazydocker","cwd":"/tmp/work","focused":false}]}}' \
  "$TAB" \
  "plugin pane open --plugin herdr-lazydocker --entrypoint lazydocker --placement tab"

# --- summary -----------------------------------------------------------------

printf '\n%d tests, %d failures\n' "$TESTS" "$FAILURES"
[ "$FAILURES" -eq 0 ]