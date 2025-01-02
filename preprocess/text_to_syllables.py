import os
import re
import glob
import subprocess
import json
import lexconvert
import pyphen

from add_effects import process_audio_files, drop
from sanitize_filename import espeak_to_filename

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


# We want to regenerate when we rerun the script,
# but not if we re-encounter the word several times,
# so skip already seen
_already_output = set()
def generate_audio_with_espeak(espeak_phonemes, output_path, pitch=0, speed=150):
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

def get_phonemes(line_text, ipa=False):
    """
    Given a str line, return the ascii phoneme format
    (that espeak takes as input)
    Can return ipa unicode characters instead if desired
    """
    format_flag = "-x"
    if ipa:
        format_flag = "--ipa"
    command = [
        "espeak", line_text, "-q", format_flag,
    ]
    try:
        result = subprocess.run(
            command, check=True,
            stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        phonemes = result.stdout.decode("utf-8").strip()
        # Hyphenating can come up in phonemes,
        # but it seems to have only a minor effect (?), and we want to use
        # '-' for syllable split deliminator, so removing for now
        phonemes = phonemes.replace('-', '')
        return phonemes
    except subprocess.CalledProcessError as e:
        raise f"Error generating IPA for hymn: {e.stderr.decode('utf-8')}"

def get_hyphenated(word):
    # Normalize the word (lowercase and remove trailing punctuation for lookup)
    word_cleaned = re.sub(r'[.,!?]+$', '', word.lower())

    # Look in our manual dictionary
    if word_cleaned in SYLLABLES_DICT:
        return SYLLABLES_DICT[word_cleaned]

    # Otherwise, rely on pyphen
    dic = pyphen.Pyphen(lang='en')
    hyphenated = dic.inserted(word_cleaned)
    return hyphenated

def get_phoneme_symbols(espeak_phonemes):
    """
    Return the espeak phonemes as a list of each separate phoneme.
    This method uses multiple passes to ensure prefixes,
    suffixes, and vowel groups are merged correctly.
    """
    # Sometimes, a word's vocalization is totally omitted:
    if espeak_phonemes == "":
        return []

    # Step 1: Split espeak_phonemes into single-character strings
    symbols = list(espeak_phonemes)

    # Step 2: Merge prefixes
    utility_prefix = "',"
    merged = []
    for char in reversed(symbols):
        if char in utility_prefix and merged:
            merged[-1] = char + merged[-1]
        else:
            merged.append(char)
    symbols = reversed(merged)

    # Step 3: Merge suffixes
    # (note: includes both the speak symbols and our
    # windows-filename-safe replacements)
    utility_suffix = "#%$=:;_|(12!"
    merged = []
    for char in symbols:
        if char in utility_suffix and merged:
            merged[-1] += char
        else:
            merged.append(char)
    symbols = merged

    # Step 4: Merge vowel groups (likely part of the same syllable)
    vowels = "aeiou"
    merged = []
    last_char_alpha = ""
    for char in symbols:
        # Ignore prefix/suffes when checking if it is a vowel sound
        char_alpha = "".join(
            c.lower() for c in char
            if c not in utility_prefix + utility_suffix
        )
        should_merge = (
            merged and char_alpha in vowels
            and last_char_alpha in vowels
            and len(merged[-1] + char) < 5
        )
        if should_merge:
            merged[-1] += char
        else:
            merged.append(char)
        last_char_alpha = char_alpha
    symbols = merged

    # Step 5: Merge other pairs that we expect to be in the same syllable
    merged = []
    combine = ["hj"]
    for char in symbols:
        for combine_str in combine:
            if merged and combine_str == merged[-1] + char:
                merged[-1] += char
            else:
                merged.append(char)
    symbols = merged
    return symbols

def get_phoneme_syllables(hyphenated, espeak_phonemes):
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
    split_phonemes = get_phoneme_symbols(espeak_phonemes)
    total_phonemes = len(split_phonemes)

    # Similarly to how a single 'phoneme symbol'
    # can be comprised of multiple characters,
    # we will say a single 'symbol of text' can be comprised by multiple
    # characters, such as "sh", "ch", etc
    syllables = hyphenated.split('-')
    split_text = [
        re.findall(r'ch|sh|th|\'s|.', s) for s in syllables
    ]
    total_syllable_len = sum(len(s) for s in split_text)
    proportions = [
        round(total_phonemes * (len(s) / total_syllable_len))
        for s in split_text
    ]

    result = []
    index = 0
    for i, proportion in enumerate(proportions):
        # Calculate the approximate number of phonemes for this syllable
        if i == len(proportions) - 1:  # Last syllable gets the rest
            proportion = total_phonemes - index

        # Collect the phoneme chunk
        chunk = split_phonemes[index: index + proportion]
        result.append(''.join(chunk))
        index += proportion

    return result

def break_apart_hymn(hymn):
    """
    Generates a wav file for each word in the hymn, and returns a dict
    that contains data about each line and word
    """
    # Some quick cleaning
    hymn = hymn.replace("’", "'")

    # Split hymn text into individual lines
    hymn_lines = hymn.split('\n')

    hymn_data = {
        "name": hymn_lines[0],
        "lines": []
    }

    for line_text in hymn_lines[1:]:
        line_data = {
            "text": line_text,
            "syllables": [],
        }

        str_words = line_text.split()

        espeak_phonemes = get_phonemes(line_text)
        espeak_words = espeak_phonemes.split()
        # Split apart some of the known combinations where espeak smushes
        # together two small words
        known_smushes = {
            "0vD@": "0v D@",
            "InDI": "In DI",
            "InDI2": "In DI2",
            "InDI2;": "In DI2;",
            "w'Ilt@": "w'Il t@",
        }
        espeak_words = [
            word
            for esw in espeak_words
            for word in known_smushes.get(esw, esw).split(' ')
        ]

        # I'm just going to omit seemingly empty phonemes:
        # TODO could make this regex...
        espeak_words = [
            esw for esw in espeak_words
            if esw not in [
                "_!",
            ]
        ]

        if len(espeak_words) != len(str_words):
            print(
                f"Word / phoneme mismatch:\n"
                f"{[z for z in zip(espeak_words, str_words)]}\n"
                f"{line_text}"
            )

        line_data['syllables'] = get_syllable_dicts(espeak_words, str_words)
        hymn_data["lines"].append(line_data)

    return hymn_data


def get_syllable_dicts(espeak_words, str_words):
    """
    Given the arrays of:
    * espeak phonemes split by word
    * normal text strings split by word
    Return the a list of syllable info dicts, including the espeak, text,
    filename, and other info
    """
    syllable_dicts = []
    zip_words = zip(espeak_words, str_words, strict=True)
    for espeak_phonemes, str_word in zip_words:
        # Split out the words to it's syllables,
        # and add those to json
        hyphenated = get_hyphenated(str_word)
        espeak_syllables = get_phoneme_syllables(
            hyphenated, espeak_phonemes)

        # Unfortunately, this does not actually add in syllable splits.
        # We could do espeak -> cmu -> unicode-ipa-syls,
        # and that might get us syllable splits?
        cmu = lexconvert.convert(espeak_phonemes, 'espeak', 'cmu')
        ipa = lexconvert.convert(cmu, 'cmu', 'unicode-ipa-syls')

        # Some syllable sounds need another phoneme to actually be voiced
        # TODO
        # short_phonemes = {
        #     "b": "bh",
        # }
        # espeak_syllables = [
        #     short_phonemes.get(ess, ess) for ess in espeak_syllables
        # ]

        zip_syllables = zip(espeak_syllables, hyphenated.split('-'))
        for espeak_s, str_s in zip_syllables:
            syllable_dicts.append(get_syllable_dict(espeak_s, str_s))

        # With the last syllable, lets include a little extra info, just
        # to maybe use as juice later
        syllable_dicts[-1]["finished_word"] = {
            "text": str_word,
            "hyphenated": hyphenated,
            "ipa": ipa,
            "espeak_phonemes": espeak_phonemes,
        }
    return syllable_dicts

def get_syllable_dict(espeak_s, str_s, output_dir="./raw_tts"):
    """
    Given a single syllable's espeak phonemes and normal text string,
    save out the audio file, and return dict of filename and whatnot
    """
    # Linux would be fine with even the unicode ipa as a filename,
    # but windows has countless limits - see sanitize_filename.py
    # for details
    filename = espeak_to_filename(espeak_s)

    # Sanity check
    expected_long_syllables = [
        "through", "thought", "breathes", "wreaths", "streams", "strikes",
        "steel's",
        "ation's", "science",  # from longer words like con(science)
    ]
    if len(str_s) > 6 and str_s not in expected_long_syllables:
        print(f"Long syllable? : {str_s} ({espeak_s})")

    # Ensure the output directory exists
    os.makedirs(output_dir, exist_ok=True)
    output_path = os.path.join(output_dir, f"{filename}.wav")
    generate_audio_with_espeak(espeak_s, output_path)

    return {
        "espeak": espeak_s,
        "text": str_s,
        "filename": filename,
    }


def create_all_hymn_audio():
    hymns = hymn_reader("hymns.txt")
    all_hymn_data = []

    # For now, wip dir every time:
    for file in glob.glob("./raw_tts/*.wav"):
        os.remove(file)
    for file in glob.glob("./audio/*.wav"):
        os.remove(file)

    # Also, have some utility words we want in the
    # library for other purposes
    print("Processing utility words:")
    for word in ["zero", "one"]:
        espeak_phonemes = get_phonemes(word)
        filename = espeak_to_filename(espeak_phonemes)
        output_path = os.path.join("./raw_tts/", f"{filename}(low).wav")
        generate_audio_with_espeak(
            espeak_phonemes, output_path, speed=300)
        drop(output_path, output_path)

        print(f"  saved: {filename}")

    # Process each hymn
    print("Processing hymns:")
    for i, hymn in enumerate(hymns):
        hymn_name = hymn.split('\n')[0]
        print(f"({i+1}) {hymn_name}:")
        hymn_data = break_apart_hymn(hymn)
        all_hymn_data.append(hymn_data)

    # Save all hymn data to a JSON file
    with open("hymns.json", "w", encoding="utf-8") as json_file:
        json.dump(all_hymn_data, json_file, indent=4, ensure_ascii=False)

    print("All hymns processed and saved to hymns.json.")

    process_audio_files()

if __name__ == "__main__":
    from tests import run_tests
    run_tests()
    create_all_hymn_audio()
