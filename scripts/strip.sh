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

# 1) Targeted Unicode → ASCII replacements.
#    Keep this list explicit so we control the mappings (iconv alone can be inconsistent).
sed \
  # German umlauts & ß
 -e 's/ä/ae/g' \
 -e 's/ö/oe/g' \
 -e 's/ü/ue/g' \
 -e 's/Ä/Ae/g' \
 -e 's/Ö/Oe/g' \
 -e 's/Ü/Ue/g' \
 -e 's/ß/ss/g' \
  # Quotation marks & apostrophes
 -e "s/[‘‚‛]/'/g" \
 -e "s/[’]/'/g" \
 -e 's/[“”„‟]/"/g' \
 -e 's/[‹«]/</g' \
 -e 's/[›»]/>/g' \
  # Dots / ellipses
 -e 's/…/.../g' \
 -e 's/‥/../g' \
  # Dashes / hyphens / minus variants
 -e 's/[‐‑‒–—―-]/-/g' \
 -e 's/−/-/g' \
  # Bullets / list markers
 -e 's/[•◦‣·]/-/g' \
  # Arrows
 -e 's/→/->/g' \
 -e 's/←/<-/g' \
 -e 's/↔/<->/g' \
 -e 's/⇒/=>/g' \
 -e 's/⇐/<=/g' \
 -e 's/⇔/<=>/g' \
  # Fractions
 -e 's/¼/1\/4/g' -e 's/½/1\/2/g' -e 's/¾/3\/4/g' \
 -e 's/⅓/1\/3/g' -e 's/⅔/2\/3/g' -e 's/⅛/1\/8/g' -e 's/⅜/3\/8/g' -e 's/⅝/5\/8/g' -e 's/⅞/7\/8/g' \
  # Math & symbols
 -e 's/×/x/g' \
 -e 's/÷/\//g' \
 -e 's/±/+\/-/g' -e 's/∓/-\/+/g' \
 -e 's/≤/<=/g' \
 -e 's/≥/>=/g' \
 -e 's/≠/!=/g' \
 -e 's/≈/~=/g' \
 -e 's/√/sqrt/g' -e 's/∞/infinity/g' \
 -e 's/°/ deg/g' \
  # Copyright/marks
 -e 's/©/(c)/g' \
 -e 's/®/(R)/g' \
 -e 's/™/TM/g' \
  # Odd spaces → regular space (NBSP, thin, hair, narrow no-break, figure, em/en, etc.)
 -e 's/[              　]/ /g' \
  # Zero-width / BOM / BiDi controls → remove
 -e 's/[\ufeff\u200b-\u200f\u202a-\u202e\u2066-\u2069]//g' \
  "$input_file" > "$tmp_file"

# 2) Collapse repeated spaces introduced by replacements; trim stray spaces before punctuation.
#    Keep ASCII-only operations here.
sed -E \
 -e 's/[[:space:]]+/ /g' \
 -e 's/ *([,:;.!?])/\1/g' \
 -e 's/^ //g; s/ $//g' \
  "$tmp_file" > "$tmp2_file"

# 3) Final transliteration to ASCII to catch any leftovers.
#    Use //IGNORE so odd stragglers don’t cause failures.
iconv -f UTF-8 -t ASCII//TRANSLIT//IGNORE "$tmp2_file" -o "$output_file"

rm -f "$tmp_file" "$tmp2_file"
