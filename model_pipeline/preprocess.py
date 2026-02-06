# preprocess.py

import os
import numpy as np
import librosa

DATA_DIR = "data"
CLASSES = ["passive", "attention", "critical"]

SR = 16000
N_MELS = 128
FIXED_SECONDS = 1.0


def extract_features(path):
    audio, _ = librosa.load(path, sr=SR)

    target_len = int(SR * FIXED_SECONDS)

    if len(audio) < target_len:
        pad = target_len - len(audio)
        audio = np.pad(audio, (0, pad))
    else:
        audio = audio[:target_len]

    mel = librosa.feature.melspectrogram(
        y=audio,
        sr=SR,
        n_mels=N_MELS
    )

    mel_db = librosa.power_to_db(mel)

    return mel_db


def main():
    X = []
    y = []

    for label, class_name in enumerate(CLASSES):
        folder = os.path.join(DATA_DIR, class_name)

        for file in os.listdir(folder):
            if file.endswith((".wav", ".mp3")):
                path = os.path.join(folder, file)

                feat = extract_features(path)

                X.append(feat)
                y.append(label)

                print("Processed:", file)

    X = np.array(X)
    y = np.array(y)

    X = X[..., np.newaxis]

    np.save("X.npy", X)
    np.save("y.npy", y)

    print("\nDone!")
    print("X shape:", X.shape)
    print("y shape:", y.shape)


if __name__ == "__main__":
    main()
