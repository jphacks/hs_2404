import sounddevice as sd
import queue
import sys
import json
from vosk import Model, KaldiRecognizer
import os
from flask import Flask, jsonify, request
from flask_cors import CORS 

app = Flask(__name__)
CORS(app)

model_path = os.path.join(os.path.dirname(__file__), "models", "vosk-model-small-ja-0.22")
model = Model(model_path)
recognizer = KaldiRecognizer(model, 16000)

audio_queue = queue.Queue()

def audio_callback(indata, frames, time, status):
    if status:
        print(status, file=sys.stderr)
    audio_queue.put(bytes(indata))

@app.route('/upload', methods=['POST'])
def recognize_audio():
    # 音声データを受け取る
    if 'audio' not in request.files:
        return jsonify({'error': 'No audio file provided'}), 400

    audio_file = request.files['audio']
    audio_data = audio_file.read()

    # 音声データを認識
    recognizer.AcceptWaveform(audio_data)
    result = recognizer.Result()
    text = json.loads(result)["text"]

    return jsonify({'recognized_text': text})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
