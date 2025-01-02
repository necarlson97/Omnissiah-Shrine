from text_to_syllables import (
    get_phoneme_symbols, get_phoneme_syllables, get_hyphenated,
    get_phonemes
)

def run_tests():
    # Some sanity check hyphenations
    expected_hyphenations = {
        "is": "is",
        "at": "at",
        "the": "the",
        "hyphenated": "hy-phen-at-ed",
        "heretic": "her-e-tic",
        "omnissiah": "om-ni-ssi-ah",
        "omnissiah's": "om-ni-ssi-ah's",
    }
    for k, v in expected_hyphenations.items():
        assert v == get_hyphenated(k), f"{v} != {get_hyphenated(k)} ({k})"

    expected_phoneme_split = {
        "oU": ["oU"],
        "spA@k": ["s", "p", "A", "@", "k"],
        "dI2vaIn": ["d", "I2", "v", "aI", "n"],
        "s3;kIts": ["s", "3;", "k", "I", "t", "s"],
        "s'eIkrI2d": ["s", "'eI", "k", "r", "I2", "d"],
        ",0mnIs'aI@z": [",0", "m", "n", "I", "s", "'aI", "@", "z"],
        "h'aI3": ["h", "'aI", "3"],
        "m@S'i:n": ["m", "@", "S", "'i:", "n"],
        "kri:;'eIS@nz": ["k", "r", "i:;", "'eI", "S", "@", "n", "z"],
    }
    for k, expected in expected_phoneme_split.items():
        got = get_phoneme_symbols(k)
        assert expected == got, f"expected {expected}, got {got}"

    expected_syllable_split = {
        # Problematic
        "high-er": "h'aI-3",
        "ma-chine": "m@-S'i:n",
        "whis-per": "w'Is-p3",
        "be-neath": "bI-2n,i:T",
        "hu-man-kind": "hj'u:-ma#N-k,aInd",

        # less problematic
        "a-lign": "a#-l'aIn",
        "di-vine": "dI2-v'aIn",
        "cir-cuits": "s'3:-kIts",
        "sa-cred": "s'eI-krI2d",
        "be-stow": "bI2-st'oU",
        "o-bey": "oU-b'eI",
        "a-way": "a#-w'eI",
        "be-neath": "bh-I2n,i:T",
        "an-vil’s": "'an-v@Lz",
        "hal-lowed": "h'a-loUd",
        "soft-ly": "s'0ft-li",
        "ho-ly": "h'oU-li",
        "riv-et": "r'Iv-I2t",
        "a-ligned": "a#-l'aInd",
        "with-in": "wID-,In",
        "her-e-tic": "h'Er-@-t,Ik",
        "faith-less": "f'eIT-l@s",
        "de-fy": "dI2-f'aI",
        "eve-ry": "'Ev-rI2",
        "rit-u-al": "r'ItS-u:-@L",
        "i-s": "I-z",
        "re-al": "r'i-@l",
        "om-ni-ssi-ah's": ",0m-nI-s'aI-@z",
    }
    for text_syllable, phoneme_sylable in expected_syllable_split.items():
        phonemes = phoneme_sylable.replace("-", "")
        got = "-".join(get_phoneme_syllables(text_syllable, phonemes))
        msg = f"expected {phoneme_sylable}, got {got} ({text_syllable})"
        assert phoneme_sylable == got, msg

    expected_phonemes = {
        "forever": "f3r'Ev3"
    }
    for text, phonemes in expected_phonemes.items():
        got = get_phonemes(text)
        assert phonemes == got, f"expected {phonemes}, got {got} ({text})"

if __name__ == "__main__":
    run_tests()
