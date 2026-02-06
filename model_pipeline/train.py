# train.py

import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.utils import to_categorical

X = np.load("X.npy")
y = np.load("y.npy")

print("Loaded:", X.shape, y.shape)

X = X / 255.0

y = to_categorical(y, 3)

input_shape = X.shape[1:]


model = models.Sequential([
    layers.Input(shape=input_shape),

    layers.Conv2D(16, (3, 3), activation="relu", padding="same"),
    layers.MaxPooling2D((2, 2)),

    layers.Conv2D(32, (3, 3), activation="relu", padding="same"),
    layers.MaxPooling2D((2, 2)),

    layers.Flatten(),
    layers.Dense(64, activation="relu"),
    layers.Dense(3, activation="softmax")
])

model.compile(
    optimizer="adam",
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)

model.summary()


model.fit(
    X,
    y,
    epochs=20,
    batch_size=8,
    validation_split=0.2
)


tf.saved_model.save(model, "echoway_model", options=tf.saved_model.SaveOptions(experimental_custom_gradients=False))

print("Model exported to echoway_model/ (SavedModel format)")
