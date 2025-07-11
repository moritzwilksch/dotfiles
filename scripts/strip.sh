#!/bin/bash

# Usage: ./strip.sh <input_file> <output_file>
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <input_file> <output_file>"
    exit 1
fi

input_file="$1"
output_file="$2"

tmp_file=$(mktemp)

sed -e 's/ä/ae/g' \
    -e 's/ö/oe/g' \
    -e 's/ü/ue/g' \
    -e 's/Ä/Ae/g' \
    -e 's/Ö/Oe/g' \
    -e 's/Ü/Ue/g' \
    -e 's/ß/ss/g' "$input_file" > "$tmp_file"

iconv -f UTF-8 -t ASCII//TRANSLIT "$tmp_file" -o "$tmp_file.iconv"

mv "$tmp_file.iconv" "$output_file"
rm -f "$tmp_file"
