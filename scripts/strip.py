#!/usr/bin/env python3
"""
Normalize unusual Unicode to plain ASCII (US QWERTY) to strip LLM-style watermarks.

Usage:
    ./strip.py [<input_file> [<output_file>]]
    ./strip.py -i <input_file> -o <output_file>
    echo "text" | ./strip.py
    ./strip.py input.txt
    ./strip.py input.txt output.txt

Passing "-" (or omitting arguments) makes the script use stdin/stdout.
"""

import argparse
import re
import sys
import unicodedata
from pathlib import Path
from typing import TextIO

STDIN_MARKER = "-"

# Character mappings for normalization (single-char keys only)
UMLAUT_REPLACEMENTS = {
    "ä": "ae",
    "ö": "oe",
    "ü": "ue",
    "Ä": "Ae",
    "Ö": "Oe",
    "Ü": "Ue",
    "ß": "ss",
}

CHAR_REPLACEMENTS = {
    # Quotes
    "‚": "'",
    "‛": "'",
    "“": '"',
    "”": '"',
    "‘": "'",
    "’": "'",
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
    "\t",  # TAB
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
    "\u00ad",  # SOFT HYPHEN
    "\u034f",  # COMBINING GRAPHEME JOINER
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
    "\u2060",  # WORD JOINER
    "\u2062",  # INVISIBLE TIMES
    "\u2063",  # INVISIBLE SEPARATOR
    "\u2064",  # INVISIBLE PLUS
    "\u2066",  # LEFT-TO-RIGHT ISOLATE
    "\u2067",  # RIGHT-TO-LEFT ISOLATE
    "\u2068",  # FIRST STRONG ISOLATE
    "\u2069",  # POP DIRECTIONAL ISOLATE
    "\uFE00",  # VARIATION SELECTOR-1
    "\uFE01",  # VARIATION SELECTOR-2
    "\uFE02",  # VARIATION SELECTOR-3
    "\uFE03",  # VARIATION SELECTOR-4
    "\uFE04",  # VARIATION SELECTOR-5
    "\uFE05",  # VARIATION SELECTOR-6
    "\uFE06",  # VARIATION SELECTOR-7
    "\uFE07",  # VARIATION SELECTOR-8
    "\uFE08",  # VARIATION SELECTOR-9
    "\uFE09",  # VARIATION SELECTOR-10
    "\uFE0A",  # VARIATION SELECTOR-11
    "\uFE0B",  # VARIATION SELECTOR-12
    "\uFE0C",  # VARIATION SELECTOR-13
    "\uFE0D",  # VARIATION SELECTOR-14
    "\uFE0E",  # VARIATION SELECTOR-15
    "\uFE0F",  # VARIATION SELECTOR-16
]

TRANSLATION_TABLE_BASE = str.maketrans(
    {
        **CHAR_REPLACEMENTS,
        **{ws: " " for ws in WHITESPACE_CHARS},
        **{zw: "" for zw in ZERO_WIDTH_CHARS},
    }
)

TRANSLATION_TABLE_WITH_UMLAUTS = str.maketrans(
    {
        **CHAR_REPLACEMENTS,
        **UMLAUT_REPLACEMENTS,
        **{ws: " " for ws in WHITESPACE_CHARS},
        **{zw: "" for zw in ZERO_WIDTH_CHARS},
    }
)


def normalize_text(
    text: str,
    *,
    strip_non_ascii: bool,
    normalize_whitespace: bool,
    strip_combining: bool,
    use_nfkc: bool,
    replace_umlauts: bool,
) -> str:
    """Normalize Unicode text to plain ASCII-ish text."""
    # Stage 0: Unicode normalization
    if use_nfkc:
        text = unicodedata.normalize("NFKC", text)

    # Stage 1: Character replacements, whitespace normalization, zero-width removal
    translation_table = (
        TRANSLATION_TABLE_WITH_UMLAUTS if replace_umlauts else TRANSLATION_TABLE_BASE
    )
    text = text.translate(translation_table)

    # Strip combining marks (common watermark vector)
    if strip_combining:
        text = "".join(
            char for char in text if unicodedata.category(char) != "Mn"
        )

    # Stage 2: Whitespace normalization (preserve newlines)
    if normalize_whitespace:
        # Process line by line to preserve newlines
        lines = text.splitlines(keepends=True)
        normalized_lines = []

        for line in lines:
            # Preserve leading indentation (spaces only after tab conversion)
            leading_whitespace = re.match(r"^[ ]*", line).group()
            rest_of_line = line[len(leading_whitespace) :]

            # Collapse multiple spaces in the rest of the line (but keep single spaces)
            rest_of_line = re.sub(r"[ ]{2,}", " ", rest_of_line)

            # Remove spaces before punctuation
            rest_of_line = re.sub(r" +([,:;.!?])", r"\1", rest_of_line)

            # Remove trailing spaces but keep the newline
            rest_of_line = rest_of_line.rstrip(" \t")

            normalized_lines.append(leading_whitespace + rest_of_line)

        text = "".join(normalized_lines)

    # Stage 3: Optionally remove any remaining non-ASCII characters
    if strip_non_ascii:
        return text.encode("ascii", "ignore").decode("ascii")

    return text


def process_stream(
    input_stream: TextIO,
    output_stream: TextIO,
    *,
    strip_non_ascii: bool,
    normalize_whitespace: bool,
    strip_combining: bool,
    use_nfkc: bool,
    replace_umlauts: bool,
) -> None:
    """Process input stream and write normalized text to output stream."""
    output_stream.write(
        normalize_text(
            input_stream.read(),
            strip_non_ascii=strip_non_ascii,
            normalize_whitespace=normalize_whitespace,
            strip_combining=strip_combining,
            use_nfkc=use_nfkc,
            replace_umlauts=replace_umlauts,
        )
    )


def main() -> int:
    """Process Unicode text and normalize it to plain ASCII."""
    parser = argparse.ArgumentParser(
        description="Normalize unusual Unicode to plain ASCII (US QWERTY)."
    )
    parser.add_argument(
        "input_file",
        nargs="?",
        default=STDIN_MARKER,
        help='Input file path or "-" for stdin (default).',
    )
    parser.add_argument(
        "output_file",
        nargs="?",
        default=STDIN_MARKER,
        help='Output file path or "-" for stdout (default).',
    )
    parser.add_argument(
        "-i",
        "--input",
        dest="input_override",
        help='Input file path or "-" for stdin (default).',
    )
    parser.add_argument(
        "-o",
        "--output",
        dest="output_override",
        help='Output file path or "-" for stdout (default).',
    )
    parser.add_argument(
        "--ascii",
        action="store_true",
        help="Strip any remaining non-ASCII characters after normalization.",
    )
    parser.add_argument(
        "--replace-umlauts",
        action="store_true",
        help="Replace German umlauts (ae/oe/ue/ss).",
    )
    whitespace_group = parser.add_mutually_exclusive_group()
    whitespace_group.add_argument(
        "--normalize-whitespace",
        action="store_true",
        dest="normalize_whitespace",
        default=False,
        help="Collapse internal whitespace and trim line-end spaces.",
    )
    whitespace_group.add_argument(
        "--no-normalize-whitespace",
        action="store_false",
        dest="normalize_whitespace",
        help="Do not collapse internal whitespace or trim line-end spaces (default).",
    )
    parser.add_argument(
        "--no-strip-combining",
        action="store_true",
        help="Do not remove combining marks.",
    )
    parser.add_argument(
        "--no-nfkc",
        action="store_true",
        help="Do not apply NFKC Unicode normalization.",
    )
    args = parser.parse_args()

    input_path = args.input_override or args.input_file
    output_path = args.output_override or args.output_file

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
            process_stream(
                input_stream,
                sys.stdout,
                strip_non_ascii=args.ascii,
                normalize_whitespace=args.normalize_whitespace,
                strip_combining=not args.no_strip_combining,
                use_nfkc=not args.no_nfkc,
                replace_umlauts=args.replace_umlauts,
            )
        else:
            with Path(input_path).open(encoding="utf-8") as input_stream:
                if output_path == STDIN_MARKER:
                    process_stream(
                        input_stream,
                        sys.stdout,
                        strip_non_ascii=args.ascii,
                        normalize_whitespace=args.normalize_whitespace,
                        strip_combining=not args.no_strip_combining,
                        use_nfkc=not args.no_nfkc,
                        replace_umlauts=args.replace_umlauts,
                    )
                else:
                    # Create output directory if needed
                    output_file = Path(output_path)
                    output_file.parent.mkdir(parents=True, exist_ok=True)
                    with output_file.open("w", encoding="utf-8") as output_stream:
                        process_stream(
                            input_stream,
                            output_stream,
                            strip_non_ascii=args.ascii,
                            normalize_whitespace=args.normalize_whitespace,
                            strip_combining=not args.no_strip_combining,
                            use_nfkc=not args.no_nfkc,
                            replace_umlauts=args.replace_umlauts,
                        )

    except (OSError, UnicodeDecodeError) as e:
        print(f"strip.py: error: {e}", file=sys.stderr)
        return 1

    return 0


if __name__ == "__main__":
    sys.exit(main())
