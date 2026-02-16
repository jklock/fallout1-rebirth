#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${STATE_DIR:-$ROOT_DIR/dev/state}"
LOG_DIR="${LOG_DIR:-$STATE_DIR/logs}"
TRACK="${TRACK:-both}"                     # both|input|config
MAX_ROUNDS="${MAX_ROUNDS:-0}"              # 0 = infinite until 100%
SLEEP_BETWEEN_ROUNDS="${SLEEP_BETWEEN_ROUNDS:-15}"
DRY_RUN="${DRY_RUN:-0}"                    # 1 = print only
RUN_IOS_SIM="${RUN_IOS_SIM:-0}"            # 1 = include simulator interactive run
RUN_GUI_DRIVE="${RUN_GUI_DRIVE:-0}"        # 1 = include macOS GUI drive run
RUNTIME_TIMEOUT="${RUNTIME_TIMEOUT:-60}"

GAMEFILES_ROOT="${FALLOUT_GAMEFILES_ROOT:-${GAMEFILES_ROOT:-}}"
BASE_DIR="${BASE_DIR:-${UNPATCHED_DIR:-}}"
PATCHED_DIR="${PATCHED_DIR:-${GAME_DATA:-}}"

if [[ -z "$BASE_DIR" && -n "$GAMEFILES_ROOT" ]]; then
  BASE_DIR="$GAMEFILES_ROOT/unpatchedfiles"
fi
if [[ -z "$PATCHED_DIR" && -n "$GAMEFILES_ROOT" ]]; then
  PATCHED_DIR="$GAMEFILES_ROOT/patchedfiles"
fi

mkdir -p "$STATE_DIR" "$LOG_DIR"
SUMMARY_FILE="$STATE_DIR/latest-summary.tsv"
HISTORY_FILE="$STATE_DIR/history.tsv"

usage() {
  cat <<EOF
Usage: $(basename "$0") [options]

Runs automated validation rounds for both tracks until full pass (100%).

Options:
  --track <both|input|config>   Track selection (default: ${TRACK})
  --max-rounds <N>              Stop after N rounds if not 100% (0 = infinite)
  --sleep <sec>                 Delay between rounds (default: ${SLEEP_BETWEEN_ROUNDS})
  --base <dir>                  Unpatched base dir
  --patched <dir>               Patched data dir
  --runtime-timeout <sec>       Runtime sweep timeout (default: ${RUNTIME_TIMEOUT})
  --run-ios-sim                 Include iOS simulator interactive test
  --run-gui-drive               Include macOS GUI drive test
  --dry-run                     Print commands only
  --help                        Show this help

Environment:
  FALLOUT_GAMEFILES_ROOT, BASE_DIR, PATCHED_DIR, GAME_DATA, UNPATCHED_DIR
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --track) TRACK="$2"; shift 2 ;;
    --max-rounds) MAX_ROUNDS="$2"; shift 2 ;;
    --sleep) SLEEP_BETWEEN_ROUNDS="$2"; shift 2 ;;
    --base) BASE_DIR="$2"; shift 2 ;;
    --patched) PATCHED_DIR="$2"; shift 2 ;;
    --runtime-timeout) RUNTIME_TIMEOUT="$2"; shift 2 ;;
    --run-ios-sim) RUN_IOS_SIM=1; shift ;;
    --run-gui-drive) RUN_GUI_DRIVE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) echo "[ERROR] Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

case "$TRACK" in
  both|input|config) ;;
  *) echo "[ERROR] Invalid --track: $TRACK" >&2; exit 2 ;;
esac

if [[ -z "$BASE_DIR" || -z "$PATCHED_DIR" ]]; then
  echo "[ERROR] Missing BASE_DIR/PATCHED_DIR." >&2
  echo "[ERROR] Set --base/--patched or FALLOUT_GAMEFILES_ROOT." >&2
  exit 2
fi

run_step() {
  local round="$1"
  local track_name="$2"
  local step_name="$3"
  local cmd="$4"
  local step_log="$LOG_DIR/round-${round}-${track_name}-${step_name}.log"
  local rc=0

  echo ">>> [round ${round}] [${track_name}] ${step_name}"
  echo ">>> CMD: ${cmd}"

  if [[ "$DRY_RUN" == "1" ]]; then
    echo -e "${round}\t${track_name}\t${step_name}\tPASS\tDRY_RUN" >> "$SUMMARY_FILE"
    return 0
  fi

  set +e
  BASE_DIR="$BASE_DIR" \
  UNPATCHED_DIR="$BASE_DIR" \
  PATCHED_DIR="$PATCHED_DIR" \
  GAME_DATA="$PATCHED_DIR" \
  FALLOUT_GAMEFILES_ROOT="${GAMEFILES_ROOT:-}" \
  bash -lc "$cmd" >"$step_log" 2>&1
  rc=$?
  set -e

  if [[ $rc -eq 0 ]]; then
    echo -e "${round}\t${track_name}\t${step_name}\tPASS\t${step_log}" >> "$SUMMARY_FILE"
    return 0
  fi

  echo -e "${round}\t${track_name}\t${step_name}\tFAIL(${rc})\t${step_log}" >> "$SUMMARY_FILE"
  return $rc
}

run_config_track() {
  local round="$1"
  local pass=0
  local total=0
  local rc=0
  local out_root="$LOG_DIR/round-${round}-config-out"
  mkdir -p "$out_root"

  local -a steps=(
    "rme_quick|python3 '$ROOT_DIR/scripts/test/rme/suite.py' quick --base '$BASE_DIR' --patched '$PATCHED_DIR' --out '$out_root/quick'"
    "rme_full|python3 '$ROOT_DIR/scripts/test/rme/suite.py' full --base '$BASE_DIR' --patched '$PATCHED_DIR' --out '$out_root/full' --timeout '$RUNTIME_TIMEOUT'"
  )

  local step
  for step in "${steps[@]}"; do
    local name="${step%%|*}"
    local cmd="${step#*|}"
    ((total+=1))
    if run_step "$round" "config" "$name" "$cmd"; then
      ((pass+=1))
    fi
  done

  # Optional strict compatibility test hook (if implemented later).
  if [[ -x "$ROOT_DIR/scripts/test/test-rme-config-compat.sh" ]]; then
    ((total+=1))
    if run_step "$round" "config" "config_compat_gate" "'$ROOT_DIR/scripts/test/test-rme-config-compat.sh'"; then
      ((pass+=1))
    fi
  fi

  if [[ $pass -eq $total ]]; then
    return 0
  fi
  return 1
}

run_input_track() {
  local round="$1"
  local pass=0
  local total=0

  local -a steps=(
    "macos_headless|BUILD_DIR='${BUILD_DIR:-build-macos}' BUILD_TYPE='${BUILD_TYPE:-RelWithDebInfo}' '$ROOT_DIR/scripts/test/test-macos-headless.sh'"
    "ios_headless|BUILD_DIR='${BUILD_DIR_IOS_SIM:-build-ios-sim}' BUILD_TYPE='${BUILD_TYPE_IOS_SIM:-RelWithDebInfo}' GAME_DATA='$PATCHED_DIR' '$ROOT_DIR/scripts/test/test-ios-headless.sh'"
  )

  if [[ "$RUN_IOS_SIM" == "1" ]]; then
    steps+=("ios_simulator|GAME_DATA='$PATCHED_DIR' '$ROOT_DIR/scripts/test/test-ios-simulator.sh'")
  fi
  if [[ "$RUN_GUI_DRIVE" == "1" ]]; then
    steps+=("macos_gui_drive|GAME_DATA='$PATCHED_DIR' '$ROOT_DIR/scripts/test/test-rme-gui-drive.sh'")
  fi

  local step
  for step in "${steps[@]}"; do
    local name="${step%%|*}"
    local cmd="${step#*|}"
    ((total+=1))
    if run_step "$round" "input" "$name" "$cmd"; then
      ((pass+=1))
    fi
  done

  if [[ $pass -eq $total ]]; then
    return 0
  fi
  return 1
}

if [[ ! -f "$HISTORY_FILE" ]]; then
  echo -e "round\tselected_tracks\tpassed_tracks\ttotal_tracks\tpercent\tstatus\ttimestamp" > "$HISTORY_FILE"
fi

round=0
while true; do
  ((round+=1))
  : > "$SUMMARY_FILE"

  selected_tracks=0
  passed_tracks=0

  if [[ "$TRACK" == "both" || "$TRACK" == "config" ]]; then
    ((selected_tracks+=1))
    if run_config_track "$round"; then
      ((passed_tracks+=1))
    fi
  fi

  if [[ "$TRACK" == "both" || "$TRACK" == "input" ]]; then
    ((selected_tracks+=1))
    if run_input_track "$round"; then
      ((passed_tracks+=1))
    fi
  fi

  percent=$(( (100 * passed_tracks) / selected_tracks ))
  status="FAIL"
  if [[ $passed_tracks -eq $selected_tracks ]]; then
    status="PASS"
  fi

  ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo -e "${round}\t${TRACK}\t${passed_tracks}\t${selected_tracks}\t${percent}\t${status}\t${ts}" >> "$HISTORY_FILE"

  echo
  echo "=== Round ${round} Summary ==="
  echo "Tracks passed: ${passed_tracks}/${selected_tracks}"
  echo "Percent: ${percent}%"
  echo "Status: ${status}"
  echo "Step details: ${SUMMARY_FILE}"
  echo "History: ${HISTORY_FILE}"
  echo

  if [[ "$status" == "PASS" ]]; then
    echo "All selected tracks reached 100%."
    exit 0
  fi

  if [[ "$MAX_ROUNDS" != "0" && "$round" -ge "$MAX_ROUNDS" ]]; then
    echo "[ERROR] Reached max rounds (${MAX_ROUNDS}) without 100%."
    exit 1
  fi

  echo "Sleeping ${SLEEP_BETWEEN_ROUNDS}s before next round..."
  sleep "$SLEEP_BETWEEN_ROUNDS"
done
