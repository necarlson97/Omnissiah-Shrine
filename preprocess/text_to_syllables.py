import os
import re
import subprocess
import json
import lexconvert
import pyphen

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
    dic = pyphen.Pyphen(lang='en')
    hyphenated = dic.inserted(word)
    # remove any trailing punctuation characters
    hyphenated = re.sub(r'[.,!?]+$', '', hyphenated)
    return {
        'hyphenated': hyphenated,
        'syllable_count': len(hyphenated.split('-')),
    }


def split_phonemes(hyphenated, espeak_phonemes):
    """
    Splits the espeak_phonemes string into chunks
    matching the hyphenated syllables.
    """
    syllables = hyphenated.split('-')

    # Non-exhaustive list of two letters that often produce 1 sound:
    alpha = "abcdefghijklmnopqrstuvwxyz"
    double_letter = [c + c for c in alpha]
    two_letter_sound = double_letter + ["th", "ch"]

    # In the phonemes text, there are characters
    # that don't represent a new 'sound' (but a modifier like 'hold')
    utility_symbols = "',%=:_|"

    result = []

    phonemes_to_split = [c for c in espeak_phonemes]

    for i, syllable in enumerate(syllables):
        # If we are on the last syllable, dump whatever is left into it
        if i == len(syllables) - 1:
            result.append("".join(phonemes_to_split))
            if len(phonemes_to_split) == 0:
                raise ValueError(
                    f"Ran out of phoneme symbols: {syllables} {result}"
                )
            return result

        # Naive method using character count
        expected_number_of_sounds = len(syllable)

        for tls in two_letter_sound:
            if tls in syllable:
                expected_number_of_sounds -= 1

        # Build up this phoneme that we are adding to the list
        current_phoneme = ""
        while len(phonemes_to_split) > 0:
            # Get the next character to add
            phoneme_symbol = phonemes_to_split.pop(0)
            current_phoneme += phoneme_symbol

            # If it was a 'real sound', remove it from expected
            if phoneme_symbol not in utility_symbols:
                expected_number_of_sounds -= 1

            # print(f"{phoneme_symbol} {utility_symbols} {phoneme_symbol in utility_symbols}")
            print(f"{current_phoneme} {phonemes_to_split} {expected_number_of_sounds}")

            # Once this syllable has used up all that we expect from it,
            # go to the next syllable
            if expected_number_of_sounds <= 0:
                break

        if current_phoneme != "":
            result.append(current_phoneme)

    raise ValueError(
        f"Why did it not return on the last syllable? {syllables}"
    )


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
        command = ["espeak", line_text, "--ipa", "-q"]
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

        for ipa_word, str_word in zip(ipa_words, str_words):
            espeak_phonemes = lexconvert.convert(
                ipa_word, "unicode-ipa", "espeak")

            filename = sanitize_ipa(espeak_phonemes)
            output_path = os.path.join(output_dir, f"{filename}.wav")

            generate_audio_with_espeak(
                espeak_phonemes, output_path, pitch, speed)

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
        print(f"({i+1}) {hymn_name}:")
        hymn_data = break_apart_hymn(hymn, pitch=pitch)
        all_hymn_data.append(hymn_data)

    # Save all hymn data to a JSON file
    with open("hymns.json", "w", encoding="utf-8") as json_file:
        json.dump(all_hymn_data, json_file, indent=4, ensure_ascii=False)

    print("All hymns processed and saved to hymns.json.")

if __name__ == "__main__":
    # Just for testing

    # with open("hymns.json") as f:
    #     for hymn_data in json.load(f):
    #         for line in hymn_data['lines']:
    #             for word in line['words']:
    #                 if len(word['hyphenated'].split('-')) > 1:
    #                     print(f"{word['hyphenated']}\n{word['espeak_phonemes']}\n\n")

    failed = 0
    success = 0
    with open("hymns.json") as f:
        for hymn_data in json.load(f)[:1]:
            for line in hymn_data['lines']:
                for word in line['words']:
                    try:
                        espeak_syllabes = split_phonemes(
                            word['hyphenated'], word['espeak_phonemes'])
                        if len(espeak_syllabes) > 1:
                            print(f"{word['hyphenated']} = {'-'.join(espeak_syllabes)}")
                        success += 1
                    except ValueError as e:
                        print(e)
                        failed += 1

    print(f"Failed {failed} of {failed + success}")
