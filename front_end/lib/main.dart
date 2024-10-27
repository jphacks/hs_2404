import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SpeechToTextApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '音声認識アプリ',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
        scaffoldBackgroundColor: Color(0xFF0F0F1F), // ダークテーマ背景色
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
  bool isFlashing = false; // 点滅フラグ
  bool showGradient = true; // デフォルトの背景をグラデーションに戻すためのフラグ
  bool isModalVisible = false; // モーダル表示のフラグ
  Color backgroundColor = Colors.indigoAccent; // 点滅中の背景色管理用

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
          if (keyword != "授業中") {
            startFlashing(); // 点滅開始
          } else {
            stopFlashing(); // 点滅停止
          }
        });

        // 時刻情報を含むか確認し、GoogleカレンダーのURLを生成して開く
        String? eventTime = await extractTime(recognizedText);
        if (eventTime != null) {
          String calendarUrl =
              generateGoogleCalendarUrl(eventTime, recognizedText);
          if (await canLaunchUrl(Uri.parse(calendarUrl))) {
            await launchUrl(Uri.parse(calendarUrl));
            print('カレンダーURLを開きました。');
          } else {
            print('カレンダーURLを開けませんでした。');
          }
        }
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

  // 点滅を開始する（keywordの状態によって切り替え）
  void startFlashing() {
    if (!isFlashing) {
      isFlashing = true;
      showGradient = false; // 点滅中はグラデーションを非表示に
      timer = Timer.periodic(Duration(milliseconds: 500), (Timer t) {
        setState(() {
          // 交互に赤と白を切り替える
          backgroundColor = (backgroundColor == Colors.redAccent)
              ? Colors.white
              : Colors.redAccent;
        });
      });
    }
  }

  // 点滅を停止する
  void stopFlashing() {
    if (timer != null) {
      timer?.cancel(); // タイマーをキャンセルする
      timer = null;
    }
    isFlashing = false;
    timer?.cancel();
    setState(() {
      showGradient = true; // 背景をグラデーションに戻す
    });
  }

  // // 文字列から時刻情報を抽出する関数
  // String? extractTime(String text) {
  //   final timeRegExp = RegExp(r'(\d{1,2}:\d{2})');
  //   final match = timeRegExp.firstMatch(text);
  //   return match?.group(0);
  // }

  // gooラボの時刻情報正規化APIを呼び出す関数
  Future<String?> extractTime(String text) async {
    final apiKey = dotenv.env['API_KEY']; // 環境変数からAPIキーを取得
    if (apiKey == null) {
      print('APIキーが設定されていません');
      return null;
    }

    final url = Uri.parse('https://labs.goo.ne.jp/api/chrono');
    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({'app_id': apiKey, 'sentence': text});

    try {
      print('Sending request to $url with body: $body');
      final response = await http.post(url, headers: headers, body: body);
      print('Received response with status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['datetime_list'] != null && data['datetime_list'].isNotEmpty) {
          final datetime = data['datetime_list'][0]['datetime'];
          print(datetime);
          return datetime;
        } else {
          print('datetime_listが空です。');
        }
      } else {
        print('時刻情報正規化APIの呼び出しに失敗しました。ステータスコード: ${response.statusCode}');
        print('レスポンスボディ: ${response.body}');
      }
    } catch (e) {
      print('エラーが発生しました: $e');
      setState(() {
        recognizedText = "データ取得エラー";
      });
    }
    return null;
  }

  // GoogleカレンダーのURLを生成する関数
  String generateGoogleCalendarUrl(String time, String description) {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyyMMdd');
    final timeFormat = DateFormat('HHmmss');
    final date = dateFormat.format(now);
    final startTime = timeFormat.format(DateFormat('HH:mm').parse(time));
    final endTime = timeFormat
        .format(DateFormat('HH:mm').parse(time).add(Duration(hours: 1)));

    return 'https://www.google.com/calendar/render?action=TEMPLATE&text=$description&dates=${date}T$startTime/${date}T$endTime';
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
    stopFlashing(); // 点滅停止

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

  // モーダルウィンドウの切り替え
  void toggleModal() {
    setState(() {
      isModalVisible = !isModalVisible;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // グラデーション背景または点滅する背景の表示
          showGradient
              ? AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.indigoAccent, Colors.deepPurpleAccent],
                    ),
                  ),
                )
              : AnimatedContainer(
                  duration: Duration(milliseconds: 500),
                  color: backgroundColor, // 点滅する背景色
                ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 認識結果を表示するカード（縦に広く調整）
                  Container(
                    width: double.infinity,
                    height: 200, // 縦に広く調整
                    padding: EdgeInsets.all(20.0),
                    margin: EdgeInsets.symmetric(vertical: 20.0),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        recognizedText,
                        style: TextStyle(fontSize: 24, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  // 録音開始/停止ボタン（色と視認性の改善）
                  ElevatedButton.icon(
                    icon: Icon(
                      isRecognizing ? Icons.stop : Icons.mic,
                      color: Colors.black,
                    ),
                    label: Text(
                      isRecognizing ? '停止' : '開始',
                      style: TextStyle(color: Colors.black),
                    ),
                    onPressed: isRecognizing ? stopRecording : startRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isRecognizing
                          ? Colors.redAccent
                          : Colors.tealAccent, // より視認性の高い色に変更
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 10,
                    ),
                  ),
                  SizedBox(height: 20),
                  // キーワード表示
                  Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      keyword,
                      style: TextStyle(
                        fontSize: 24,
                        color: (keyword == "授業中")
                            ? Colors.greenAccent
                            : Colors.redAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // フローティングアクションボタン
          Positioned(
            bottom: 30,
            right: 30,
            child: FloatingActionButton(
              onPressed: toggleModal,
              backgroundColor: Colors.cyanAccent,
              child: Icon(
                isModalVisible ? Icons.close : Icons.menu,
                color: Colors.black,
              ),
            ),
          ),
          // モーダルウィンドウの表示
          if (isModalVisible)
            Positioned.fill(
              child: GestureDetector(
                onTap: toggleModal,
                child: Container(
                  color: Colors.black87.withOpacity(0.8),
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.6,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 15,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'メニュー',
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 30),
                          ListTile(
                            leading: Icon(Icons.mic, color: Colors.cyanAccent),
                            title: Text('音声認識',
                                style: TextStyle(color: Colors.white)),
                            onTap: () {
                              // 現在のページが"音声認識"なので何もせずモーダルを閉じる
                              toggleModal();
                            },
                          ),
                          Divider(color: Colors.grey),
                          ListTile(
                            leading: Icon(Icons.task, color: Colors.cyanAccent),
                            title: Text('課題管理',
                                style: TextStyle(color: Colors.white)),
                            onTap: () {
                              // 課題管理画面を追加予定
                              toggleModal();
                            },
                          ),
                          Divider(color: Colors.grey),
                          ListTile(
                            leading:
                                Icon(Icons.summarize, color: Colors.cyanAccent),
                            title: Text('要約一覧',
                                style: TextStyle(color: Colors.white)),
                            onTap: () {
                              // 要約画面を追加予定
                              toggleModal();
                            },
                          ),
                          Divider(color: Colors.grey),
                          ListTile(
                            leading:
                                Icon(Icons.settings, color: Colors.cyanAccent),
                            title: Text('設定',
                                style: TextStyle(color: Colors.white)),
                            onTap: () {
                              // 設定画面を追加予定
                              toggleModal();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

void main() async {
  await dotenv.load(fileName: ".env"); // .envファイルから環境変数を読み込む
  runApp(SpeechToTextApp());
}
