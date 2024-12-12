import os
import sys
import io

# Set UTF-8 as the default encoding for all files
sys.stdin.reconfigure(encoding='utf-8')
sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

os.environ['PYTHONIOENCODING'] = 'utf-8'

import epitran
import pyphen
from typing import List, Dict


def text_to_syllables(text: str) -> List[Dict[str, str]]:
    # Initialize libraries
    epi = epitran.Epitran('eng-Latn')  # Epitran for English
    dic = pyphen.Pyphen(lang='en')     # Pyphen for syllabification

    syllables = []

    # Break the text into words
    words = text.split()

    for word in words:
        # Get syllables for the word
        word_syllables = dic.inserted(word).split('-')

        for syllable in word_syllables:
            # Convert syllable to IPA
            ipa = epi.transliterate(syllable)

            # Convert IPA to ASCII IPA (using Kirshenbaum-like mapping)
            ascii_ipa = ipa_to_ascii(ipa)

            # Add syllable dictionary to the list
            syllables.append({
                'text': syllable,
                'ipa': ipa,
                'ascii_ipa': ascii_ipa
            })

    return syllables


def ipa_to_ascii(ipa: str) -> str:
    # Simplified example of IPA to ASCII conversion (expand as needed)
    mapping = {
        'ɑ': 'A', 'æ': '{', 'ʌ': 'V', 'ɔ': 'O', 'ə': '@', 'ɛ': 'E', 'ɪ': 'I',
        'i': 'i', 'u': 'u', 'ʊ': 'U', 'o': 'o', 'e': 'e', 'ː': ':', 'ŋ': 'N',
        'ʃ': 'S', 'ʒ': 'Z', 'θ': 'T', 'ð': 'D', 'tʃ': 'C', 'dʒ': 'J', 'j': 'j',
        'p': 'p', 'b': 'b', 't': 't', 'd': 'd', 'k': 'k', 'g': 'g', 'f': 'f',
        'v': 'v', 's': 's', 'z': 'z', 'h': 'h', 'm': 'm', 'n': 'n', 'r': 'r',
        'l': 'l', 'w': 'w', 'ʔ': '?', 'ˈ': "'", 'ˌ': ',', ' ': ' '
    }
    ascii_ipa = ''.join(mapping.get(char, char) for char in ipa)
    return ascii_ipa


# Example usage
text = "Testing 1 2 3"
result = text_to_syllables(text)
for syllable in result:
    print(syllable)
