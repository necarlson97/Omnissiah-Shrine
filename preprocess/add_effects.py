import os
import soundfile as sf
import librosa

from vocoder import apply_vocoder_effect

# For some reason `from audioFX.Fx import Fx` does not work,
# but we can manually force including
import sys
sys.path.append(os.path.abspath("./env/lib/python3.10/site-packages/audioFX"))
sys.path.append(os.path.abspath(".\\env\\Lib\\site-packages\\audioFX"))
from audioFX.Fx import Fx


def apply_effects(input_path, output_path):
    """
    The simple shortlist of effects to get a retro, robotic voice
    """
    audio, sample_rate = librosa.load(input_path, sr=None)
    fx = Fx(sample_rate)

    fx_chain = {
        # "distortion": 2,  # was causing issues with vocoder output
        "chorus": 1,
        "pitch": 1,
    }

    optional = {
        "chorus_frequency": 2,
        "chorus_depth": 0,
        "chorus_delay": 30,
        "pitch_semitones": -3,
    }

    processed_audio = fx.process_audio(audio, fx_chain, optional)
    sf.write(output_path, processed_audio, sample_rate)


def drop(input_path, output_path):
    """
    Drop down a wavs pitch (for zeros and ones)
    """
    audio, sample_rate = librosa.load(input_path, sr=None)
    fx = Fx(sample_rate)

    fx_chain = {
        "pitch": 1,
    }
    optional = {
        "pitch_semitones": -4,
    }

    processed_audio = fx.process_audio(audio, fx_chain, optional)
    sf.write(output_path, processed_audio, sample_rate)


def process_audio_files(input_dir="./raw_tts", output_dir="./audio"):
    """Process all WAV files in the input directory, applying effects."""
    print("Processing audio files...")
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for root, _, files in os.walk(input_dir):
        # TODO limiting just for testing
        for file in files:
            if file == ".wav":
                continue
            if file.endswith(".wav"):
                input_path = os.path.join(root, file)
                relative_path = os.path.relpath(input_path, input_dir)
                output_path = os.path.join(output_dir, relative_path)

                try:
                    apply_vocoder_effect(input_path, output_path)
                    # Apply effects and save the processed file
                    apply_effects(output_path, output_path)

                except Exception as e:
                    print(f"Error on {input_path}: {e}")
    print("All audio files processed and saved.")


if __name__ == "__main__":
    process_audio_files()
