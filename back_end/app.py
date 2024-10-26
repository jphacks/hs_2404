import sounddevice as sd
import queue
import sys
import os
import json
from google.cloud import speech
from google.oauth2 import service_account
from flask import Flask, jsonify
from flask_cors import CORS

# Flaskサーバーの初期化
app = Flask(__name__)
CORS(app)

# Google Cloudの認証情報を読み込む
def get_speech_client():
    credentials = service_account.Credentials.from_service_account_file(
        './assets/service_account.json'  # 認証情報ファイルのパスを指定
    )
    client = speech.SpeechClient(credentials=credentials)
    return client

client = get_speech_client()

# キューと変数の初期化
audio_queue = queue.Queue()
recognized_text = ""  # 認識結果を保持する変数

# 音声をキューに追加するコールバック関数
def audio_callback(indata, frames, time, status):
    if status:
        print(status, file=sys.stderr)
    audio_queue.put(bytes(indata))

# Google Speech-to-Textストリーミング認識
def recognize_audio():
    global recognized_text

    # ストリーミング認識設定
    config = speech.RecognitionConfig(
        encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
        sample_rate_hertz=16000,
        language_code="ja-JP",
    )
    streaming_config = speech.StreamingRecognitionConfig(config=config, interim_results=True)

    # 音声をストリームで送信
    with sd.RawInputStream(samplerate=16000, blocksize=4000, dtype='int16',
                           channels=1, callback=audio_callback):
        def requests():
            while True:
                data = audio_queue.get()
                if data is None:
                    break
                yield speech.StreamingRecognizeRequest(audio_content=data)
            # 空データでストリームを維持
                yield speech.StreamingRecognizeRequest(audio_content=b'')

        responses = client.streaming_recognize(config=streaming_config, requests=requests())

        for response in responses:
            for result in response.results:
                if result.is_final:
                    recognized_text = result.alternatives[0].transcript
                    print("認識結果:", recognized_text)
                else:
                    partial_text = result.alternatives[0].transcript
                    print("部分的な認識結果:", partial_text)

# /recognizeエンドポイントを作成
@app.route('/recognize', methods=['GET'])
def get_recognized_text():
    return jsonify({'recognized_text': recognized_text})

# Flaskサーバーの実行
if __name__ == '__main__':
    from threading import Thread

    recognition_thread = Thread(target=recognize_audio)
    recognition_thread.daemon = True
    recognition_thread.start()

    app.run(debug=True, port=5000)
