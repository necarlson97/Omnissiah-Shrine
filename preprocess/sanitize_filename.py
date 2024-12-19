import unicodedata
from typing import Dict

# Map of special espeak phonetic characters to sanitized versions
# This ensures uniqueness and compatibility with Windows filenames

# Note:
# we use parenthesis () as escaping our mapped characters here
# we use carat ^ to encode uppercase text
# I believe these are not in espeak phonemes (?) but I could be wrong

# Included the definitions here just for fun
PHONETIC_MAP: Dict[str, str] = {
    "#": "(hsh)",  # a phoneme, 'h' sounding
    "'": "(pri)",  # primary stress
    ",": "(sec)",  # secondary stress
    "%": "(uns)",  # unstressed syllable
    "=": "(pre)",  # put primary stress on preceding
    "||": "(bou)",  # word boundary
    "|": "(sep)",  # separator
    ':': '(pau)',  # pause
    "_": "(ssp)",  # Short pause (? is this right?)

    # These are not expected, but we might as well include them:
    "<": "(lst)",
    ">": "(grt)",
    '"': "(dbq)",
    "/": "(fws)",
    "/": "(bks)",
    "?": "(qsm)",
    "*": "(ast)",
}

def espeak_to_filename(phonetic: str) -> str:
    """
    Convert eSpeak phonetic format into a deterministic,
    Windows-compatible filename.
    """
    # Normalize to NFD (decompose combined characters)
    phonetic = unicodedata.normalize("NFD", phonetic)

    # Replace mapped characters explicitly
    for char, replacement in PHONETIC_MAP.items():
        phonetic = phonetic.replace(char, replacement)

    # Ensure case insensitivity uniqueness
    # (encode as lowercase with markers)
    sanitized = "".join(
        f"^{c.lower()}" if c.isupper() else c for c in phonetic
    )
    return sanitized

def filename_to_espeak(sanitized: str) -> str:
    """
    Convert a sanitized filename back into the original eSpeak phonetic format.
    """
    # Reverse case encoding
    restored = ""
    skip_next = False
    for i, char in enumerate(sanitized):
        if skip_next:
            skip_next = False
            continue
        if char == "^" and i + 1 < len(sanitized):
            restored += sanitized[i + 1].upper()
            skip_next = True
        else:
            restored += char

    # Replace mapped characters back to original phonetic characters
    reversed_map = {v: k for k, v in PHONETIC_MAP.items()}
    for replacement, char in reversed_map.items():
        restored = restored.replace(replacement, char)

    # Normalize back to NFC (combine characters)
    restored = unicodedata.normalize("NFC", restored)

    return restored

# Example usage
if __name__ == "__main__":
    expected_sanitizations = {
        "d^i2": "dI2",
        "v(pri)a^in": "v'aIn",
        "s(pri)3(pau)": "s'3:",
        "k^its": "kIts",
        "s(pri)e^i": "s'eI",
        "kr^i2d": "krI2d",
        "^tru(pau)": "Tru:",
        "br(pri)i(pau)^dz": "br'i:Dz",
    }

    for k, v in expected_sanitizations.items():
        got_filename = espeak_to_filename(v)
        got_restored = filename_to_espeak(k)
        assert k == got_filename, f"{k} != {got_filename} (for {v})"
        assert v == got_restored, f"{v} != {got_restored} (for {k})"
        assert filename_to_espeak(got_filename) == v
        assert espeak_to_filename(got_restored) == k
    print("Done! All tests passed")
