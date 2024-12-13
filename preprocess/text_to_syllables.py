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

def generate_audio_with_espeak(ipa, output_path, pitch=50, speed=150):
    """Calls espeak as a subprocess to generate audio for a given word."""
    if output_path in _already_output:
        return

    espeak_phonemes = lexconvert.convert(ipa, "unicode-ipa", "espeak")
    print(f"  {ipa} = {espeak_phonemes}")
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
            f"Error generating audio for '{ipa}' ({espeak_phonemes}): "
            f"{e.stderr.decode('utf-8')}"
        )
        raise

def get_syllables(word):
    dic = pyphen.Pyphen(lang='en')
    hyphenated = dic.inserted(word)
    return {
        'hyphenated': hyphenated,
        'syllable_count': len(hyphenated.split('-')),
    }

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
            "words": []
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

            filename = sanitize_ipa(ipa_word)
            output_path = os.path.join(output_dir, f"{filename}.wav")

            generate_audio_with_espeak(ipa_word, output_path, pitch, speed)

            line_data["words"].append({
                "text": str_word,
                "ipa": ipa_word,
                "espeak_phonemes": espeak_phonemes,
                **get_syllables(str_word),
            })

        hymn_data["lines"].append(line_data)

    return hymn_data

if __name__ == "__main__":
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
