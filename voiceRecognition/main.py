import sounddevice as sd
import queue
import sys
import json
from vosk import Model, KaldiRecognizer
import os

# モデルのパスを指定してください（解凍したフォルダへのパス）
#model_path = "C:/Users/shihe/vosk-model-small-ja-0.22"
model_path = os.path.join(os.path.dirname(__file__), "models", "vosk-model-small-ja-0.22")


# VOSKのモデルをロード
model = Model(model_path)
recognizer = KaldiRecognizer(model, 16000)  # サンプリングレートは16kHz

# 音声データを格納するキュー
audio_queue = queue.Queue()

# 音声データの取得
def audio_callback(indata, frames, time, status):
    if status:
        print(status, file=sys.stderr)
    audio_queue.put(bytes(indata))

# 音声入力のストリーム設定
def recognize_audio():
    with sd.RawInputStream(samplerate=16000, blocksize=8000, dtype='int16',
                           channels=1, callback=audio_callback):
        print("音声認識を開始しました。終了するにはCtrl+Cを押してください。")
        while True:
            data = audio_queue.get()
            if recognizer.AcceptWaveform(data):
                result = recognizer.Result()
                text = json.loads(result)["text"]
                print("認識結果:", text)
            else:
                partial_result = recognizer.PartialResult()
                partial_text = json.loads(partial_result)["partial"]
                print("部分的な認識結果:", partial_text)

try:
    recognize_audio()
except KeyboardInterrupt:
    print("\n終了します")
except Exception as e:
    print("エラーが発生しました:", str(e))
