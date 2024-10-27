import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SpeechToTextApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '音声認識結果表示',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RecognizePage(),
    );
  }
}

class RecognizePage extends StatefulWidget {
  @override
  _RecognizePageState createState() => _RecognizePageState();
}

class _RecognizePageState extends State<RecognizePage> {
  String recognizedText = "認識結果がここに表示されます";
  bool isRecognizing = false;
  String keyword = "授業中";
  Timer? timer;

  // サーバーからデータを取得する関数
  Future<void> fetchRecognizedText() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:5000/recognize'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          recognizedText = data['recognized_text'] ?? "データが空です";
          keyword = data['keyword'];
        });
      } else {
        print('サーバーからデータを取得できませんでした。ステータスコード: ${response.statusCode}');
      }
    } catch (e) {
      print('エラーが発生しました: $e');
      setState(() {
        recognizedText = "データ取得エラー";
      });
    }
  }

  // 音声認識の開始
  Future<void> startRecording() async {
    setState(() {
      isRecognizing = true;
      recognizedText = "音声認識中...";
    });

    // サーバーの/startエンドポイントにリクエストを送信
    try {
      final response =
          await http.post(Uri.parse('http://localhost:5000/start'));
      if (response.statusCode == 200) {
        print("音声認識を開始しました");
        // 定期的にデータを取得するためのタイマーを設定
        timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
          if (isRecognizing) {
            fetchRecognizedText();
          } else {
            t.cancel();
          }
        });
      } else {
        print("音声認識開始のリクエストが失敗しました");
      }
    } catch (e) {
      print('エラーが発生しました: $e');
      setState(() {
        recognizedText = "音声認識開始エラー";
      });
    }
  }

  // 音声認識の停止
  Future<void> stopRecording() async {
    setState(() {
      isRecognizing = false;
      recognizedText = "認識結果がここに表示されます";
    });

    // タイマーが設定されていればキャンセル
    timer?.cancel();

    // サーバーの/stopエンドポイントにリクエストを送信
    try {
      final response = await http.post(Uri.parse('http://localhost:5000/stop'));
      if (response.statusCode == 200) {
        print("音声認識を停止しました");
      } else {
        print("音声認識停止のリクエストが失敗しました");
      }
    } catch (e) {
      print('エラーが発生しました: $e');
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('リアルタイム音声認識結果'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                recognizedText,
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isRecognizing ? stopRecording : startRecording,
                child: Text(isRecognizing ? '停止' : '開始'),
              ),
              SizedBox(height: 20),
              Text(
                keyword,
                style: TextStyle(
                    fontSize: 20,
                    color: (keyword == "授業中") ? Colors.green : Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(SpeechToTextApp());
}
