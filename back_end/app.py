import sounddevice as sd
import queue
import sys
import os
import json
from google.cloud import speech
from google.oauth2 import service_account
from flask import Flask, jsonify
from flask_cors import CORS
from threading import Thread
from dotenv import load_dotenv
import google.generativeai as genai

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
recognized_text = ""
partial_text = ""
is_recognizing = False  # 音声認識の状態を保持する変数
audio_buffer = bytearray()


# 音声をキューに追加するコールバック関数
def audio_callback(indata, frames, time, status):
    global audio_buffer
    # 音声データをバッファに追加
    audio_buffer.extend(bytes(indata))

    # バッファが32000バイトに達したらキューに追加（目安1s分）
    if len(audio_buffer) >= 64000:
        audio_queue.put(bytes(audio_buffer))
        audio_buffer.clear()

# Google Speech-to-Textストリーミング認識
def recognize_audio():
    global recognized_text
    global partial_text
    global is_recognizing
    global summary

    compare_text = ["", ""]
    counter = 0

    # ストリーミング認識設定
    config = speech.RecognitionConfig(
        encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
        sample_rate_hertz=16000,
        language_code="ja-JP",
    )
    streaming_config = speech.StreamingRecognitionConfig(config=config, interim_results=True)

    # 音声をストリームで送信
    with sd.RawInputStream(samplerate=16000, blocksize=16000, dtype='int16',
                           channels=1, callback=audio_callback):
        def requests():
            while is_recognizing:  # is_recognizing が True のときだけデータを送信
                data = audio_queue.get()
                if data is None:
                    break
                yield speech.StreamingRecognizeRequest(audio_content=data)
                yield speech.StreamingRecognizeRequest(audio_content=b'')

        responses = client.streaming_recognize(config=streaming_config, requests=requests())


        for response in responses:
            for result in response.results:
                compare_text[0] = result.alternatives[0].transcript
                if result.is_final:
                    recognized_text = compare_text[0]
                    print("認識結果:", recognized_text)
                    summary = summarize_text(recognized_text)
                    print("要約結果:", summary)
                    counter = 0
                else:
                    partial_text = compare_text[0]
                    print("部分的な認識結果:", partial_text)
                    compare_text[1] = partial_text

                    if compare_text[0] == compare_text[1]:
                        counter += 1
                    if counter >= 20:
                        recognized_text = compare_text[1]
                        print("認識結果:", recognized_text)
                        summary = summarize_text(recognized_text)
                        print("要約結果:", summary)
                        counter = 0


def summarize_text(text):
    prompt = f"次のテキストを要約して結果のみをください.: {text}"
    gemini_pro = genai.GenerativeModel("gemini-pro")
    response = gemini_pro.generate_content(prompt)
    return response.text

# 音声認識を開始するエンドポイント
@app.route('/start', methods=['POST'])
def start_recognition():
    global is_recognizing
    if not is_recognizing:
        is_recognizing = True
        recognition_thread = Thread(target=recognize_audio)
        recognition_thread.daemon = True
        recognition_thread.start()
        return jsonify({"message": "音声認識を開始しました"}), 200
    else:
        return jsonify({"message": "音声認識は既に開始されています"}), 400

# 音声認識を停止するエンドポイント
@app.route('/stop', methods=['POST'])
def stop_recognition():
    global is_recognizing
    is_recognizing = False
    return jsonify({"message": "音声認識を停止しました"}), 200

# /recognizeエンドポイントを作成
@app.route('/recognize', methods=['GET'])
def get_recognized_text():
    keyword = "授業中"
    keyword_included = ["重要", "大事", "課題", "提出", "テスト", "レポート", "締め切り", "期限"]
    for k in keyword_included:
        if k in partial_text[-20:]:
            keyword = k
            break
    return jsonify({'recognized_text': recognized_text, 'keyword': keyword})

# Flaskサーバーの実行
if __name__ == '__main__':
    app.run(debug=True, port=5000)
