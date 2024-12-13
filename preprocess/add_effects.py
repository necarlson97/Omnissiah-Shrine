import os
import soundfile as sf
import librosa

# For some reason `from audioFX.Fx import Fx` does not work,
# but we can manually force including
import sys
sys.path.append(os.path.abspath("./env/lib/python3.10/site-packages/audioFX"))
from audioFX.Fx import Fx


def apply_effects(input_path, output_path):
    """Apply retro effects using audioFX."""
    # Load the audio file
    audio, sample_rate = librosa.load(input_path, sr=None)
    fx = Fx(sample_rate)

    fx_chain = {
        "distortion": 2,
        "chorus": 1,
        "pitch": 1,
    }

    optional = {
        "chorus_frequency": 2,
        "chorus_depth": 0,
        "chorus_delay": 30,
        "pitch_semitones": -3,
    }

    # Apply the effects chain
    processed_audio = fx.process_audio(audio, fx_chain, optional)

    # Save the processed audio to output path
    sf.write(output_path, processed_audio, sample_rate)
    print(f"{output_path} done")

def process_audio_files(input_dir="./raw_tts", output_dir="./audio"):
    """Process all WAV files in the input directory, applying effects."""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    for root, _, files in os.walk(input_dir):
        # TODO limiting just for testing
        for file in files:
            if file.endswith(".wav"):
                input_path = os.path.join(root, file)
                relative_path = os.path.relpath(input_path, input_dir)
                output_path = os.path.join(output_dir, relative_path)

                try:
                    # Apply effects and save the processed file
                    apply_effects(input_path, output_path)
                except librosa.util.exceptions.ParameterError as e:
                    print(f"Error on {input_path}: {e}")

if __name__ == "__main__":
    input_directory = "./raw_tts"
    output_directory = "./audio"

    print("Processing audio files...")
    process_audio_files(input_directory, output_directory)
    print("All audio files processed and saved.")
