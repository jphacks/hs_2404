import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
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
  String keyword = "授業中";

  // Flaskサーバーからデータを取得する関数
  Future<void> fetchRecognizedText() async {
    try {
      final response = await http
          .get(Uri.parse('http://localhost:5000/recognize')); // エミュレーターの場合
      // 実機の場合は localhost を Flask サーバーの IP アドレスに変更
      // final response = await http.get(Uri.parse('http://<your_ip>:5000/recognize'));

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

  // 一定間隔でデータを取得するためのタイマー
  Timer? timer;

  @override
  void initState() {
    super.initState();
    // 1秒ごとにAPIからデータを取得するタイマーを設定
    timer = Timer.periodic(
        Duration(seconds: 1), (Timer t) => fetchRecognizedText());
  }

  @override
  void dispose() {
    // ウィジェットが破棄されるときにタイマーをキャンセル
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
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(
                recognizedText,
                style: TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                keyword,
                style: TextStyle(
                    fontSize: 20,
                    color: (keyword == "授業中") ? Colors.green : Colors.red),
              ),
            ])),
      ),
    );
  }
}

void main() {
  runApp(SpeechToTextApp());
}
