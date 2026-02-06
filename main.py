from flask import Flask
from cvstuff import getEmotion, getEmotionLoop
from surroundSound import classify_sound
app = Flask(__name__)

@app.route('/')
def root():
    return "root directory"

@app.route('/getEmotion')
def getEm():
    return getEmotion()

@app.route('/getEmotionLoop')
def getEmLoop():
    return getEmotionLoop()


if __name__ == "__main__":
    app.run()
