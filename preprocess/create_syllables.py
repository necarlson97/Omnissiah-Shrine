import os
import subprocess
import re

from librosa import load
import soundfile as sf
# For some reason `from audioFX.Fx import Fx` does not work,
# but we can manually force including
import sys
sys.path.append(os.path.abspath("./env/lib/site-packages/audioFX"))

# Directories for generated audio
RAW_DIR = "./raw-tts/"
PROCESSED_DIR = "./audio/"
os.makedirs(RAW_DIR, exist_ok=True)
os.makedirs(PROCESSED_DIR, exist_ok=True)

# Hymns to process
test_hymn = [
    "Oh spark divine, through circuits flow",
    "Thy sacred light, all truths bestow",
    "In steel we kneel, thy word obey",
    "Through thee, the flesh shall fall away"
]
# For now, just testing from a single hymn, but later we will load from a file
hymns = [test_hymn]

def get_ipa(line):
    """Get the IPA transcription for the given line using espeak."""
    try:
        result = subprocess.run(
            ["espeak", "-q", "--ipa", line],
            text=True,
            encoding="utf-8",
            capture_output=True,
            check=True
        )
        ipa_output = result.stdout.strip()
        return ipa_output
    except subprocess.CalledProcessError as e:
        print(f"Error calling espeak: {e}")
        return None

def split_into_syllables(line):
    """Split the given line into syllables."""
    syllables = []
    dic = pyphen.Pyphen(lang="en_US")
    words = line.split()
    for word in words:
        syllabified_word = dic.inserted(word)
        syllables.extend(syllabified_word.split("-"))
    return syllables

def map_ipa_to_syllables(ipa, syllables):
    """Map IPA transcription to syllables."""
    ipa_parts = ipa.split()  # Break IPA into words
    mapped_syllables = []

    for syllable, ipa_part in zip(syllables, ipa_parts):
        mapped_syllables.append((syllable, ipa_part))

    return mapped_syllables

def generate_tts(syllable, output_path):
    """Generate audio for a syllable using espeak."""
    try:
        # Call espeak with the text and output path
        subprocess.run([
            "espeak", syllable,
            "-v", "en-us",  # Voice
            "-p", "30",     # Pitch
            "-s", "120",    # Speed
            "-w", output_path
        ], check=True)
        print(f"Generated TTS for: {syllable} -> {output_path}")
    except subprocess.CalledProcessError as e:
        print(f"Error generating TTS for {syllable}: {e}")


def apply_effects(input_path, output_path):
    """Apply retro effects using audioFX."""
    # Load the audio file
    audio, sample_rate = load(input_path, sr=None)
    fx = Fx(sample_rate)

    fx_chain = {
        "distortion": 0.5,
        "reverb": 0.8,
    }
    optional_parameters = {
        "reverb_room_size": 0.9,
        "distortion_drive": 0.8,
    }

    processed_audio = fx.process_audio(audio, fx_chain, optional_parameters)
    sf.write(output_path, processed_audio, sample_rate)


def process_hymns(hymns):
    """Process hymns into syllable audio clips with effects."""
    for hymn in hymns:
        for hymn_idx, line in enumerate(hymn):
            print(f"Processing line: {line}")

            # Get IPA and syllables from the line
            syllables = get_ascii_phonemes_and_syllables(line)

            for syllable_ipa in syllables:
                # Create filenames
                raw_path = os.path.join(
                    RAW_DIR, f"{syllable_ipa}.wav")
                processed_path = os.path.join(
                    PROCESSED_DIR, f"{syllable_ipa}.wav")

                # Generate TTS if not already present
                if not os.path.exists(raw_path):  # Skip if already exists
                    generate_tts(syllable_ipa, raw_path)

                    # Apply effects if processed version doesn't already exist
                    apply_effects(raw_path, processed_path)
                    print(f"Processed and saved: {processed_path}")
                else:
                    print(f"Already found: {processed_path}")


# Process all hymns
# process_hymns(hymns)


if __name__ == "__main__":
    print(get_ipa_with_syllables("testing 1 2 3"))
    print(get_ipa_with_syllables("Oh spark divine, through circuits flow"))
