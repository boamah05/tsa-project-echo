from flask import Flask, jsonify
from cvstuff import getEmotion, getEmotionLoop
import requests

app = Flask(__name__)
ngrok_link = "https://3010-70-123-36-145.ngrok-free.app/"

@app.route("/")
def root():
    return "root directory"

@app.route("/getEmotion")
def getEm():
    return requests.get(f"{ngrok_link}/getEmotion").text

@app.route("/getEmotionLoop")
def getEmLoop(seconds):
    return requests.get(f"{ngrok_link}/getEmotionLoop").text

if __name__ == "__main__":
    app.run()
