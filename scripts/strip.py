#!/usr/bin/env python3
"""
Normalize unusual Unicode to plain ASCII (US QWERTY) to strip LLM-style watermarks.

Usage:
    ./strip.py [<input_file> [<output_file>]]
    echo "text" | ./strip.py
    ./strip.py input.txt
    ./strip.py input.txt output.txt

Passing "-" (or omitting arguments) makes the script use stdin/stdout.
"""

import re
import sys
from pathlib import Path
from typing import TextIO

# Constants
MAX_ARGS = 3
STDIN_MARKER = "-"
MIN_ARGS_FOR_OUTPUT = 2

# Character mappings for normalization
CHAR_REPLACEMENTS = {
    # German umlauts
    "ä": "ae",
    "ö": "oe",
    "ü": "ue",
    "Ä": "Ae",
    "Ö": "Oe",
    "Ü": "Ue",
    "ß": "ss",
    # Quotes
    """: "'", '‚': "'", '‛': "'", """: "'",
    '"': '"',
    '"': '"',
    "„": '"',
    "‟": '"',
    # Angle brackets
    "‹": "<",
    "«": "<",
    "›": ">",
    "»": ">",
    # Ellipsis
    "…": "...",
    "‥": "..",
    # Dashes and hyphens
    "‐": "-",
    "‑": "-",
    "‒": "-",
    "–": "-",
    "—": "-",
    "―": "-",
    "-": "-",
    "−": "-",
    # Bullets
    "•": "-",
    "◦": "-",
    "‣": "-",
    "·": "-",
    # Arrows
    "→": "->",
    "←": "<-",
    "↔": "<->",
    "⇒": "=>",
    "⇐": "<=",
    "⇔": "<=>",
    # Fractions
    "¼": "1/4",
    "½": "1/2",
    "¾": "3/4",
    "⅓": "1/3",
    "⅔": "2/3",
    "⅛": "1/8",
    "⅜": "3/8",
    "⅝": "5/8",
    "⅞": "7/8",
    # Math operators
    "×": "x",
    "÷": "/",
    "±": "+/-",
    "∓": "-/+",
    "≤": "<=",
    "≥": ">=",
    "≠": "!=",
    "≈": "~=",
    "√": "sqrt",
    "∞": "infinity",
    # Other symbols
    "°": " deg",
    "©": "(c)",
    "®": "(R)",
    "™": "TM",
}

# Unicode whitespace characters (normalized to space)
WHITESPACE_CHARS = [
    "\u00a0",  # NO-BREAK SPACE
    "\u2000",
    "\u2001",
    "\u2002",
    "\u2003",
    "\u2004",  # EN QUAD through THREE-PER-EM SPACE
    "\u2005",
    "\u2006",
    "\u2007",
    "\u2008",
    "\u2009",  # FOUR-PER-EM through THIN SPACE
    "\u200a",  # HAIR SPACE
    "\u202f",  # NARROW NO-BREAK SPACE
    "\u205f",  # MEDIUM MATHEMATICAL SPACE
    "\u3000",  # IDEOGRAPHIC SPACE
]

# Zero-width characters (removed)
ZERO_WIDTH_CHARS = [
    "\ufeff",  # ZERO WIDTH NO-BREAK SPACE (BOM)
    "\u200b",  # ZERO WIDTH SPACE
    "\u200c",  # ZERO WIDTH NON-JOINER
    "\u200d",  # ZERO WIDTH JOINER
    "\u200e",  # LEFT-TO-RIGHT MARK
    "\u200f",  # RIGHT-TO-LEFT MARK
    "\u202a",  # LEFT-TO-RIGHT EMBEDDING
    "\u202b",  # RIGHT-TO-LEFT EMBEDDING
    "\u202c",  # POP DIRECTIONAL FORMATTING
    "\u202d",  # LEFT-TO-RIGHT OVERRIDE
    "\u202e",  # RIGHT-TO-LEFT OVERRIDE
    "\u2066",  # LEFT-TO-RIGHT ISOLATE
    "\u2067",  # RIGHT-TO-LEFT ISOLATE
    "\u2068",  # FIRST STRONG ISOLATE
    "\u2069",  # POP DIRECTIONAL ISOLATE
]


def normalize_text(text: str) -> str:
    """Normalize Unicode text to plain ASCII."""
    # Stage 1: Character replacements
    for old_char, new_char in CHAR_REPLACEMENTS.items():
        text = text.replace(old_char, new_char)

    # Replace unusual whitespace with regular space
    for ws_char in WHITESPACE_CHARS:
        text = text.replace(ws_char, " ")

    # Remove zero-width characters
    for zw_char in ZERO_WIDTH_CHARS:
        text = text.replace(zw_char, "")

    # Stage 2: Whitespace normalization (preserve newlines and normal indentation)
    # Process line by line to preserve newlines
    lines = text.splitlines(keepends=True)
    normalized_lines = []

    for line in lines:
        # Preserve leading indentation (spaces and tabs)
        leading_whitespace = re.match(r"^[ \t]*", line).group()
        rest_of_line = line[len(leading_whitespace) :]

        # Collapse multiple spaces in the rest of the line (but keep single spaces)
        rest_of_line = re.sub(r"[ \t]{2,}", " ", rest_of_line)

        # Remove spaces before punctuation
        rest_of_line = re.sub(r" +([,:;.!?])", r"\1", rest_of_line)

        # Remove trailing spaces but keep the newline
        rest_of_line = rest_of_line.rstrip(" \t")

        normalized_lines.append(leading_whitespace + rest_of_line)

    text = "".join(normalized_lines)

    # Stage 3: Remove any remaining non-ASCII characters
    # Only strip characters we haven't explicitly mapped
    # return text.encode("ascii", "ignore").decode("ascii")
    return text


def process_stream(input_stream: TextIO, output_stream: TextIO) -> None:
    """Process input stream and write normalized text to output stream."""
    output_stream.write(normalize_text(input_stream.read()))


def main() -> int:
    """Process Unicode text and normalize it to plain ASCII."""
    # Parse arguments
    if len(sys.argv) > MAX_ARGS:
        print(f"Usage: {sys.argv[0]} [<input_file> [<output_file>]]", file=sys.stderr)
        return 1

    input_path = sys.argv[1] if len(sys.argv) > 1 else STDIN_MARKER
    output_path = sys.argv[2] if len(sys.argv) > 2 else STDIN_MARKER

    # Validate input file exists (if not stdin)
    if input_path != STDIN_MARKER:
        input_file = Path(input_path)
        if not input_file.exists():
            print(f"strip.py: input file not found: {input_path}", file=sys.stderr)
            return 1

    try:
        # Handle input with context manager
        if input_path == STDIN_MARKER:
            input_stream = sys.stdin
            process_stream(input_stream, sys.stdout)
        else:
            with Path(input_path).open(encoding="utf-8") as input_stream:
                if output_path == STDIN_MARKER:
                    process_stream(input_stream, sys.stdout)
                else:
                    # Create output directory if needed
                    output_file = Path(output_path)
                    output_file.parent.mkdir(parents=True, exist_ok=True)
                    with output_file.open("w", encoding="utf-8") as output_stream:
                        process_stream(input_stream, output_stream)

    except (OSError, UnicodeDecodeError) as e:
        print(f"strip.py: error: {e}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
