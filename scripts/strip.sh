#!/bin/bash
# Normalize unusual Unicode to plain ASCII (US QWERTY) to strip LLM-style watermarks.
# Usage: ./strip.sh <input_file> <output_file>

set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input_file> <output_file>"
  exit 1
fi

input_file="$1"
output_file="$2"

tmp_file="$(mktemp)"
tmp2_file="$(mktemp)"

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
 -e 's/™/TM/g' \
 -e 's/[              　]/ /g' \
 -e 's/[\ufeff\u200b-\u200f\u202a-\u202e\u2066-\u2069]//g' \
  "$input_file" > "$tmp_file"

sed -E \
 -e 's/[[:space:]]+/ /g' \
 -e 's/ *([,:;.!?])/\1/g' \
 -e 's/^ //g; s/ $//g' \
  "$tmp_file" > "$tmp2_file"

iconv -f UTF-8 -t ASCII//TRANSLIT//IGNORE "$tmp2_file" -o "$output_file"

rm -f "$tmp_file" "$tmp2_file"
