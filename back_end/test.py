import google.generativeai as genai
import time
from dotenv import load_dotenv
import os

load_dotenv()

GOOGLE_API_KEY=os.getenv('GEMINI_API_KEY')
genai.configure(api_key=GOOGLE_API_KEY)

# 動画のファイルパス。アップロードした場所のパスを指定する
video_path = "test.mp4" # @param {type:"string"}

uploaded_video = genai.upload_file(video_path)
# アップロード完了をチェック
# `upload_file` は非同期的に実行されるため、完了を待たないと次の処理でエラーが発生してしまう
while uploaded_video.state.name == "PROCESSING":
  print("Waiting for processed.")
  time.sleep(10)
  uploaded_video = genai.get_file(uploaded_video.name)

  # Pass multimodal prompt
model_name = "gemini-1.5-flash-latest" # @param {type:"string"}
model = genai.GenerativeModel(model_name)

prompt = "音声認識の結果を返してください"

content = [prompt, uploaded_video]
response = model.generate_content(content)
print(response.text)