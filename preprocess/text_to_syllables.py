import os
import re
import subprocess
import json
import lexconvert
import pyphen

def load_syllables(file_path='./syllables.txt'):
    """
    Load syllables from a syllables.txt file into a dictionary for quick lookup
    Format: word=hy-phen-a-ted
    """
    syllables_dict = {}
    with open(file_path, 'r', encoding='utf-8') as file:
        for line in file:
            line = line.strip()
            if '=' in line:
                word, hyphenated = line.split('=', 1)
                syllables_dict[word.lower()] = hyphenated
    return syllables_dict

# Load the syllables.txt file once
SYLLABLES_DICT = load_syllables()

def hymn_reader(file_path):
    """
    Reads hymns from a file, splitting them into a list of strings
    by double newlines.
    """
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()
    hymns = content.strip().split('\n\n')
    return hymns

def sanitize_ipa(ipa):
    """Converts IPA to a filename-safe format"""
    # TODO for now, just use ipa, as on ubuntu it is safe
    return ipa

# We want to regenerate when we rerun the script,
# but not if we re-encounter the word several times,
# so skip already seen
_already_output = set()
def generate_audio_with_espeak(espeak_phonemes, output_path, pitch=50, speed=150):
    """Calls espeak as a subprocess to generate audio for a given word."""
    if output_path in _already_output:
        return
    command = [
        "espeak",
        f"-p{pitch}",  # Set pitch
        f"-s{speed}",  # Set speed
        f"-w", output_path,
        f"[[{espeak_phonemes}]]",  # double square brackets means phoneme input
    ]

    try:
        subprocess.run(
            command, check=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        _already_output.add(output_path)
    except subprocess.CalledProcessError as e:
        print(
            f"Error generating audio for {espeak_phonemes}: "
            f"{e.stderr.decode('utf-8')}"
        )
        raise

def get_syllables(word):
    # Normalize the word (lowercase and remove trailing punctuation for lookup)
    word_cleaned = re.sub(r'[.,!?]+$', '', word.lower())

    dic = pyphen.Pyphen(lang='en')
    hyphenated = dic.inserted(word_cleaned)

    # If it wasn't hyphenated by pyphen, or syllables.txt might catch it
    hyphenated = SYLLABLES_DICT.get(word_cleaned, hyphenated)

    return {
        'hyphenated': hyphenated,
        'syllable_count': len(hyphenated.split('-')),
    }

def split_phonemes(hyphenated, espeak_phonemes):
    """
    Splits the espeak_phonemes string into chunks
    matching the hyphenated syllables. I.e.:
    separate the espeak phonemes to individual sounds
    split them based on the 'size' of each syllable.
    So if the hyphenated is:
    'di-vine' (2/6 and 4/6)
    but there are 12 phoneme symbols*, it will return
    4/12 and 8/12

    (*not true, just to make math easy)
    """
    # Sometimes, a word's vocalization is totally omitted:
    if espeak_phonemes == "":
        return []

    # Step 1: Split espeak_phonemes into symbols with utility characters
    utility_symbols = "',%=:_|"
    split_phonemes = []
    add_to_first = ""
    for i, phoneme_char in enumerate(espeak_phonemes):
        # if a utility character, add to phoneme before it
        if phoneme_char in utility_symbols:
            if i == 0:
                # if we have a utility symbol at the start, lets say
                # its for the next character
                add_to_first += phoneme_char
            else:
                split_phonemes[-1] += phoneme_char
        else:
            split_phonemes.append(phoneme_char)
    split_phonemes[0] = add_to_first + split_phonemes[0]

    # Step 2: Calculate proportional sizes of each syllable
    syllables = hyphenated.split('-')
    total_syllable_len = sum(len(s) for s in syllables)
    proportions = [len(s) / total_syllable_len for s in syllables]

    # Step 3: Map proportional sizes to phonemes
    total_phonemes = len(split_phonemes)
    result = []
    index = 0

    for i, proportion in enumerate(proportions):
        # Calculate the approximate number of phonemes for this syllable
        if i == len(proportions) - 1:  # Last syllable gets the rest
            chunk_size = total_phonemes - index
        else:
            chunk_size = round(proportion * total_phonemes)

        # Collect the phoneme chunk
        chunk = split_phonemes[index: index + chunk_size]
        result.append(''.join(chunk))
        index += chunk_size

    return result


def break_apart_hymn(hymn, output_dir="./raw_tts", pitch=50, speed=150):
    """
    Generates a wav file for each word in the hymn, and returns a dict
    that contains data about each line and word
    """
    # Split hymn text into individual lines
    hymn_lines = hymn.split('\n')

    # Ensure the output directory exists
    os.makedirs(output_dir, exist_ok=True)

    hymn_data = {
        "name": hymn_lines[0],
        "lines": []
    }

    for line_text in hymn_lines[1:]:
        line_data = {
            "text": line_text,
            "words": [],
            "syllables": [],
        }

        # Get IPA transcription using espeak directly,
        # as it is the only way to respect context for heteronyms
        command = [
            "espeak", line_text, "--ipa", "-q",
            f"-g 10",  # Tiny gap between words to prevent them getting smushed
        ]
        try:
            result = subprocess.run(
                command, check=True,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE
            )
            ipa = result.stdout.decode("utf-8").strip()
        except subprocess.CalledProcessError as e:
            print(f"Error generating IPA for hymn: {e.stderr.decode('utf-8')}")
            raise

        ipa_words = ipa.split()
        str_words = line_text.split()

        # Split apart some words that espeak smushes togeather

        if len(ipa_words) != len(str_words):
            print(f"Word / phoneme mismatch: {ipa_words} {str_words}")

        for ipa_word, str_word in zip(ipa_words, str_words, strict=True):
            espeak_phonemes = lexconvert.convert(
                ipa_word, "unicode-ipa", "espeak")

            word_data = {
                "text": str_word,
                "ipa": ipa_word,
                "espeak_phonemes": espeak_phonemes,
                **get_syllables(str_word),
            }
            line_data["words"].append(word_data)

            # Also split out the words to it's syllables,
            # and add those to a separate dict
            espeak_syllables = split_phonemes(
                word_data['hyphenated'], espeak_phonemes)
            str_syllables = word_data['hyphenated'].split('-')
            for espeak_s, str_s in zip(espeak_syllables, str_syllables):
                line_data["syllables"].append({
                    "espeak": espeak_s,
                    "text": str_s,
                })

                # TODO just for testing
                expected_long_syllables = [
                    "through", "thought", "breathes", "wreaths", "streams",
                    "science",  # from conscience
                ]
                if len(str_s) > 6 and str_s not in expected_long_syllables:
                    print(f"{str_s} ({str_word})")

                filename = sanitize_ipa(espeak_s)
                output_path = os.path.join(output_dir, f"{filename}.wav")
                generate_audio_with_espeak(
                    espeak_s, output_path, pitch, speed)

        hymn_data["lines"].append(line_data)

    return hymn_data

def create_all_hymn_audio():
    hymns = hymn_reader("hymns.txt")
    pitch = 0
    all_hymn_data = []

    # Also, have some utility words we want in the
    # library for other purposes
    print("Processing utility words:")
    break_apart_hymn("zero one", pitch=pitch)

    # Process each hymn
    print("Processing hymns:")
    for i, hymn in enumerate(hymns):
        hymn_name = hymn.split('\n')[0]
        # print(f"({i+1}) {hymn_name}:")
        hymn_data = break_apart_hymn(hymn, pitch=pitch)
        all_hymn_data.append(hymn_data)

    # Save all hymn data to a JSON file
    with open("hymns.json", "w", encoding="utf-8") as json_file:
        json.dump(all_hymn_data, json_file, indent=4, ensure_ascii=False)

    print("All hymns processed and saved to hymns.json.")

if __name__ == "__main__":
    create_all_hymn_audio()
