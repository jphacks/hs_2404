import sounddevice as sd
import queue
import sys
import json
from vosk import Model, KaldiRecognizer
import os
from flask import Flask, jsonify
from flask_cors import CORS  # 追加

# Flaskサーバーの初期化
app = Flask(__name__)

# CORSの有効化
CORS(app)  # 追加

# モデルのパスを指定してください（解凍したフォルダへのパス）
model_path = os.path.join(os.path.dirname(__file__), "models", "vosk-model-small-ja-0.22")

# VOSKのモデルをロード
model = Model(model_path)

custom_vocabulary = '課題,提出,テスト,レポート'
custom_vocabulary = json.dumps(custom_vocabulary.split(','), ensure_ascii=False)

# カスタム語彙を適用したKaldiRecognizerのインスタンスを作成
recognizer = KaldiRecognizer(model, 16000)#, custom_vocabulary

# 音声データを格納するキュー
audio_queue = queue.Queue()

# 音声データの取得
def audio_callback(indata, frames, time, status):
    if status:
        print(status, file=sys.stderr)
    audio_queue.put(bytes(indata))

# 音声認識結果を保持する変数
recognized_text = ""

# 音声入力のストリーム設定
def recognize_audio():
    global recognized_text
    try:
        """ with sd.RawInputStream(samplerate=16000, blocksize=8000, dtype='int16',
                               channels=1, callback=audio_callback): """
        with sd.RawInputStream(samplerate=16000, blocksize=8000, dtype='int16',
                           channels=1, callback=audio_callback):
            while True:
                try:
                    data = audio_queue.get(timeout=5)  # 5秒間データを待つ
                    if recognizer.AcceptWaveform(data):
                        result = recognizer.Result()
                        text = json.loads(result)["text"]
                        recognized_text = text  # 認識結果を変数に保存
                        print("認識結果:", text)
                    else:
                        partial_result = recognizer.PartialResult()
                        partial_text = json.loads(partial_result)["partial"]
                        # print("部分的な認識結果:", partial_text)
                except queue.Empty:
                    print("オーディオデータの取得タイムアウト")  # デバッグ用
                    break
    except Exception as e:
        print("オーディオストリームのエラー:", str(e))  # デバッグ用

# /recognizeエンドポイントを作成
@app.route('/recognize', methods=['GET'])
def get_recognized_text():
    keyword = "授業中"
    # キーワードが含まれているかどうかを判定
    keyword_included = ["重要", "大事", "課題", "提出", "テスト", "レポート", "締め切り", "期限"]
    for k in keyword_included:
        if k in recognized_text:
            keyword = k
            break
    return jsonify({'recognized_text': recognized_text, 'keyword': keyword})

# Flaskサーバーの実行
if __name__ == '__main__':
    try:
        # 音声認識を別スレッドで実行
        from threading import Thread
        recognition_thread = Thread(target=recognize_audio)
        recognition_thread.daemon = True
        recognition_thread.start()

        # Flaskサーバーを起動
        app.run(debug=True, port=5000)
    except KeyboardInterrupt:
        print("\n終了します")
    except Exception as e:
        print("エラーが発生しました:", str(e))