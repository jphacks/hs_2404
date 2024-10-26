import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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

  // Flaskサーバーからデータを取得する関数
  Future<void> fetchRecognizedText() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:5000/recognize'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          recognizedText = data['recognized_text'];
        });
      } else {
        print('サーバーからデータを取得できませんでした。ステータスコード: ${response.statusCode}');
      }
    } catch (e) {
      print('エラーが発生しました: $e');
    }
  }

  // 一定間隔でデータを取得するためのタイマー
  Timer? timer;

  @override
  void initState() {
    super.initState();
    // 1秒ごとにAPIからデータを取得するタイマーを設定
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) => fetchRecognizedText());
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
          child: Text(
            recognizedText,
            style: TextStyle(fontSize: 24),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
