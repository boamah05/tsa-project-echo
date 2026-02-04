from flask import Flask
from cvstuff import getEmotion, getEmotionLoop
app = Flask(__name__)

@app.route('/')
def root():
    return "root directory"

@app.route('/getEmotion')
def getEm():
    return getEmotion()

@app.route('/getEmotionLoop/seconds=<int:seconds>')
def getEmLoop(seconds):
    return getEmotionLoop(seconds)


if __name__ == "__main__":
    app.run()