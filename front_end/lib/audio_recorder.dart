import 'dart:html'; // dart:htmlをインポート
import 'dart:typed_data'; // Uint8Listを扱うために追加
import 'vosk_api.dart'; // Vosk API処理を利用

class AudioRecorder {
  MediaStream? _localStream;
  MediaRecorder? _mediaRecorder;
  List<int> _audioChunks = [];

  AudioRecorder() {
    _getUserMedia();
  }

  // マイクからの音声を取得
  Future<void> _getUserMedia() async {
    try {
      var stream = await window.navigator.mediaDevices!.getUserMedia({'audio': true});
      _localStream = stream;
      print("マイクから音声を取得しました！");
    } catch (e) {
      print("マイク入力エラー: $e");
    }
  }

  // 録音を開始
  void startRecording() {
    if (_localStream != null) {
      _mediaRecorder = MediaRecorder(_localStream!);
      _mediaRecorder!.start();

      _mediaRecorder!.addEventListener('dataavailable', (event) {
        BlobEvent blobEvent = event as BlobEvent;
        Blob blob = blobEvent.data!;

        FileReader reader = FileReader();
        reader.readAsArrayBuffer(blob);
        reader.onLoadEnd.listen((event) {
          if (reader.result != null) {
            Uint8List audioData = reader.result as Uint8List;
            _audioChunks.addAll(audioData);
          }
        });
      });

      _mediaRecorder!.addEventListener('stop', (event) {
        print("録音が停止しました。");
        _sendAudioToAPI();
      });

      print("録音を開始しました！");
    }
  }

  // 録音を停止
  void stopRecording() {
    if (_mediaRecorder != null) {
      _mediaRecorder!.stop();
      _mediaRecorder = null;
    }
  }

  // 録音データをAPIに送信
  Future<void> _sendAudioToAPI() async {
    print("音声データをAPIに送信します...");
    await VoskApi.sendAudio(_audioChunks);
  }
}
