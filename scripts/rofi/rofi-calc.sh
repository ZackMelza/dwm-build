#!/usr/bin/env bash
set -euo pipefail

conf_dir="${ROFI_CONF_DIR:-$HOME/.config/rofi}"
rofi_theme="$conf_dir/config-calc.rasi"

calc_expr() {
  local expr="$1"
  if command -v qalc >/dev/null 2>&1; then
    qalc -t "$expr" 2>/dev/null | tail -n1
    return
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 - <<PY
import math
expr = ${expr@Q}
try:
    print(eval(expr, {"__builtins__": {}}, {"math": math}))
except Exception:
    print("error")
PY
    return
  fi

  echo "error"
}

result=""
while true; do
  expr="$(printf '' | rofi -dmenu -p 'Calc' -mesg "$result" -config "$rofi_theme")"
  [[ -n "$expr" ]] || exit 0
  result="$(calc_expr "$expr")"
  if command -v xclip >/dev/null 2>&1; then
    printf '%s' "$result" | xclip -selection clipboard
  fi
done
