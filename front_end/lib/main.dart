import 'package:flutter/material.dart';
import 'audio_recorder.dart'; // 音声録音処理のインポート
import 'google_speech_api.dart'; // Google Speech API処理のインポート

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AudioRecorder _audioRecorder = AudioRecorder();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('マイク録音テスト')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _audioRecorder.startRecording,
                child: Text('録音を開始'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _audioRecorder.stopRecording,
                child: Text('録音を停止'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
