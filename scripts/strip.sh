#!/bin/bash
# Normalize unusual Unicode to plain ASCII (US QWERTY) to strip LLM-style watermarks.
# Usage: ./strip.sh [<input_file> [<output_file>]]
# Passing "-" (or omitting arguments) makes the script use stdin/stdout.

set -euo pipefail

usage() {
  echo "Usage: $0 [<input_file> [<output_file>]]" >&2
  exit 1
}

if [ "$#" -gt 2 ]; then
  usage
fi

input_path="${1:--}"
output_path="${2:--}"

if [ "$input_path" != "-" ] && [ ! -e "$input_path" ]; then
  echo "strip.sh: input file not found: $input_path" >&2
  exit 1
fi

tmp_output=""
cleanup() {
  if [ -n "$tmp_output" ] && [ -f "$tmp_output" ]; then
    rm -f "$tmp_output"
  fi
}
trap cleanup EXIT

if [ "$output_path" != "-" ]; then
  tmp_output="$(mktemp)"
  output_dir="$(dirname "$output_path")"
  if [ "$output_dir" != "." ] && [ ! -d "$output_dir" ]; then
    mkdir -p "$output_dir"
  fi
fi

read_cmd=(cat)
if [ "$input_path" != "-" ]; then
  read_cmd=(cat -- "$input_path")
fi

whitespace_chars="$(printf '\u00A0\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F\u205F\u3000')"
zero_width_chars="$(printf '\uFEFF\u200B\u200C\u200D\u200E\u200F\u202A\u202B\u202C\u202D\u202E\u2066\u2067\u2068\u2069')"

sed_stage_one() {
  sed \
    -e 's/ä/ae/g' \
    -e 's/ö/oe/g' \
    -e 's/ü/ue/g' \
    -e 's/Ä/Ae/g' \
    -e 's/Ö/Oe/g' \
    -e 's/Ü/Ue/g' \
    -e 's/ß/ss/g' \
    -e "s/[‘‚‛]/'/g" \
    -e "s/[’]/'/g" \
    -e 's/[“”„‟]/"/g' \
    -e 's/[‹«]/</g' \
    -e 's/[›»]/>/g' \
    -e 's/…/.../g' \
    -e 's/‥/../g' \
    -e 's/[‐‑‒–—―-]/-/g' \
    -e 's/−/-/g' \
    -e 's/[•◦‣·]/-/g' \
    -e 's/→/->/g' \
    -e 's/←/<-/g' \
    -e 's/↔/<->/g' \
    -e 's/⇒/=>/g' \
    -e 's/⇐/<=/g' \
    -e 's/⇔/<=>/g' \
    -e 's/¼/1\/4/g' \
    -e 's/½/1\/2/g' \
    -e 's/¾/3\/4/g' \
    -e 's/⅓/1\/3/g' \
    -e 's/⅔/2\/3/g' \
    -e 's/⅛/1\/8/g' \
    -e 's/⅜/3\/8/g' \
    -e 's/⅝/5\/8/g' \
    -e 's/⅞/7\/8/g' \
    -e 's/×/x/g' \
    -e 's/÷/\//g' \
    -e 's/±/+\/-/g' \
    -e 's/∓/-\/+/g' \
    -e 's/≤/<=/g' \
    -e 's/≥/>=/g' \
    -e 's/≠/!=/g' \
    -e 's/≈/~=/g' \
    -e 's/√/sqrt/g' \
    -e 's/∞/infinity/g' \
    -e 's/°/ deg/g' \
    -e 's/©/(c)/g' \
    -e 's/®/(R)/g' \
    -e 's/™/TM/g'
}

sed_stage_two() {
  sed -E \
    -e 's/[[:space:]]+/ /g' \
    -e 's/ *([,:;.!?])/\1/g' \
    -e 's/^ //g' \
    -e 's/ $//g'
}

python_transliterate() {
  python3 -c 'import sys, unicodedata; data = sys.stdin.read(); norm = unicodedata.normalize("NFKD", data); sys.stdout.write(norm.encode("ascii", "ignore").decode("ascii"))'
}

run_pipeline() {
  "${read_cmd[@]}" \
    | sed_stage_one \
    | tr "$whitespace_chars" ' ' \
    | tr -d "$zero_width_chars" \
    | sed_stage_two \
    | python_transliterate
}

if [ "$output_path" = "-" ]; then
  run_pipeline
else
  if ! run_pipeline > "$tmp_output"; then
    exit 1
  fi
  mv "$tmp_output" "$output_path"
fi
