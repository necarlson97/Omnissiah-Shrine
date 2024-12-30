import numpy as np
import librosa
import os
from scipy.io.wavfile import write


def apply_vocoder_effect(audio_path: str, output_path="output.wav", pitch: float = 440) -> str:
    """
    Apply a vocoder effect to an audio file and save the output as a WAV file.

    Args:
        audio_path (str): Path to the input audio file.
        pitch (float): The pitch for the carrier signal (default 440 Hz).

    Returns:
        str: Path to the output WAV file with the vocoder effect applied.
    """
    # Load the modulator (voice) signal
    modulator, sr = librosa.load(audio_path, sr=None)

    # Generate a carrier signal (sine wave at the specified pitch)
    duration = len(modulator) / sr
    t = np.linspace(0, duration, len(modulator), endpoint=False)
    carrier = 0.5 * np.sin(2 * np.pi * pitch * t)

    # Ensure both signals are the same length
    min_len = min(len(carrier), len(modulator))
    carrier = carrier[:min_len]
    modulator = modulator[:min_len]

    # Frame the signals
    frame_size = 1024
    hop_size = 512

    print(f"Working on: {audio_path}")
    # TODO bad, sloopy
    if "./raw_tts/.wav" in audio_path:
        return audio_path

    def frame_signal(signal, frame_size, hop_size):
        num_frames = 1 + (len(signal) - frame_size) // hop_size
        frames = np.lib.stride_tricks.as_strided(
            signal, shape=(num_frames, frame_size),
            strides=(signal.strides[0] * hop_size, signal.strides[0])
        )
        return frames

    carrier_frames = frame_signal(carrier, frame_size, hop_size)
    modulator_frames = frame_signal(modulator, frame_size, hop_size)

    # Perform STFT
    def stft(frames, n_fft):
        return np.fft.rfft(frames, n=n_fft)

    n_fft = 1024
    carrier_stft = stft(carrier_frames, n_fft)
    modulator_stft = stft(modulator_frames, n_fft)

    # Compute amplitude envelopes
    modulator_amplitude = np.abs(modulator_stft)

    # Modulate the carrier signal
    carrier_amplitude = np.abs(carrier_stft)
    modulated_stft = carrier_stft * (modulator_amplitude / np.maximum(carrier_amplitude, 1e-10))

    # Perform inverse STFT
    def istft(stft_matrix, hop_size):
        num_frames, n_fft = stft_matrix.shape
        frame_size = (n_fft - 1) * 2
        signal = np.zeros(num_frames * hop_size + frame_size - hop_size)
        for n, i in enumerate(range(0, len(signal) - frame_size, hop_size)):
            signal[i:i + frame_size] += np.fft.irfft(stft_matrix[n])
        return signal

    output_signal = istft(modulated_stft, hop_size)

    # Normalize the output signal
    output_signal = output_signal / np.max(np.abs(output_signal))

    # Save the output WAV file
    write(output_path, sr, (output_signal * 32767).astype(np.int16))

    return output_path


if __name__ == "__main__":
    input_audio_path = "./raw_tts/z(pri)i@ro^u.wav"
    result = apply_vocoder_effect(input_audio_path)
    print(f"Vocoder output saved to: {result}")
