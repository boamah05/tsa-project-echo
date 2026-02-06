# convert_to_coreml.py

import coremltools as ct

mlmodel = ct.convert(
    "echoway_model",
    source="tensorflow"
)


mlmodel.save("ProjectEchoSoundClassifier.mlpackage")

