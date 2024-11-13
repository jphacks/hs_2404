import 'package:flutter/material.dart';
import 'basePage.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class VoiceRecognitionPage extends StatefulWidget {
  @override
  _VoiceRecognitionPageState createState() => _VoiceRecognitionPageState();
}

class _VoiceRecognitionPageState extends State<VoiceRecognitionPage> {
  //String recognizedText = "認識結果がここに表示されます";
  //String summarizedText = "要約データがここに表示されます";
  List<String> recognizedTexts = ["認識結果1", "認識結果2", "認識結果3"];
  List<String> summarizedTexts = ["要約1", "要約2", "要約3"];
  bool isRecognizing = false;
  String keyword = "授業中";
  Timer? timer;
  Timer? flashTimer;
  bool isFlashing = false; // 点滅フラグ
  bool showGradient = true; // デフォルトの背景をグラデーションに戻すためのフラグ
  Color backgroundColor = Colors.indigoAccent; // 点滅中の背景色管理用
  List<String> keywords = [
    "重要",
    "大事",
    "課題",
    "提出",
    "テスト",
    "レポート",
    "締め切り",
    "期限",
    "動作確認"
  ];
  int currentIndex = 0; //要約とかの文章を受け取るリストのインデックスを管理する変数

  //キーワードをapp.pyに送信
  Future<void> sendKeywords() async {
    final response = await http.post(
      Uri.parse('http://localhost:5000/set_keywords'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'keywords': keywords}),
    );

    if (response.statusCode == 200) {
      print("キーワードを送信しました");
    } else {
      print("キーワードの送信に失敗しました");
    }
  }

  @override
  void initState() {
    super.initState();
    //デバッグ用に消去。後で復活させる
    sendKeywords(); // ウィジェットの初期化時にキーワードを送信
  }

  // キーワード設定ダイアログを表示する関数
  void showKeywordSettingDialog(BuildContext context) {
    final TextEditingController keywordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('キーワードの設定'),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // キーワードの一覧を表示
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: keywords.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(keywords[index]),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  keywords.removeAt(index); // キーワードを削除
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    TextField(
                      controller: keywordController,
                      decoration: InputDecoration(hintText: "新しいキーワードを入力"),
                    ),
                    SizedBox(height: 8), // テキストフィールドと注意書きの間にスペースを追加
                    Align(
                      alignment: Alignment.centerRight, //右寄せ
                      child: Text(
                        "※「保存」を押さなければ変更が反映されません",
                        style: TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // ダイアログを閉じる
                  },
                  child: Text("キャンセル"),
                ),
                TextButton(
                  onPressed: () {
                    // 新しいキーワードを追加
                    setState(() {
                      if (keywordController.text.isNotEmpty) {
                        keywords.add(keywordController.text);
                        keywordController.clear();
                      }
                    });
                  },
                  child: Text("追加"),
                ),
                TextButton(
                  onPressed: () async {
                    // キーワードを保存（バックエンドに送信）
                    await sendKeywords();
                    Navigator.of(context).pop(); // ダイアログを閉じる
                  },
                  child: Text("保存"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // サーバーからデータを取得する関数
  Future<void> fetchRecognizedText() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:5000/recognize'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newRecognizedText = data['recognized_text'] ?? "データが空です";
        final newSummarizedText = data['summarized_text'] ?? "要約データが空です";

        setState(() {
          // 最新のデータが前回のデータと異なる場合のみリストに追加
          if (recognizedTexts.isEmpty ||
              recognizedTexts.last != newRecognizedText) {
            recognizedTexts.add(newRecognizedText);
            if (recognizedTexts.length > 3) {
              recognizedTexts.removeAt(0);
            }
          }

          if (summarizedTexts.isEmpty ||
              summarizedTexts.last != newSummarizedText) {
            summarizedTexts.add(newSummarizedText);
            if (summarizedTexts.length > 3) {
              summarizedTexts.removeAt(0);
            }
          }

          currentIndex = recognizedTexts.length - 1; // 最新のデータのインデックスを更新

          keyword = data['keyword'];
          if (keyword != "授業中") {
            startFlashing(); // 点滅開始
          } else {
            stopFlashing(); // 点滅停止
          }
        });

        // 時刻情報を含むか確認し、GoogleカレンダーのURLを生成して開く
        String? eventTime = await extractTime(recognizedTexts[currentIndex]);
        if (eventTime != null) {
          String calendarUrl = generateGoogleCalendarUrl(
              eventTime, recognizedTexts[currentIndex]);
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
        recognizedTexts[currentIndex] = "データ取得エラー";
      });
    }
  }

  // 点滅を開始する（keywordの状態によって切り替え）
  void startFlashing() {
    if (!isFlashing) {
      isFlashing = true;
      showGradient = false; // 点滅中はグラデーションを非表示に
      flashTimer = Timer.periodic(Duration(milliseconds: 500), (Timer t) {
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
    if (flashTimer != null) {
      flashTimer?.cancel(); // タイマーをキャンセルする
      flashTimer = null;
    }
    isFlashing = false;
    flashTimer?.cancel();
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
        recognizedTexts[currentIndex] = "データ取得エラー";
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
      //recognizedTexts[currentIndex] = "音声認識中...";
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
        recognizedTexts[currentIndex] = "音声認識開始エラー";
      });
    }
  }

  // 音声認識の停止
  Future<void> stopRecording() async {
    setState(() {
      isRecognizing = false;
      //recognizedTexts[currentIndex] = "認識結果がここに表示されます";
    });

    // タイマーが設定されていればキャンセル
    timer?.cancel();
    stopFlashing(); // 点滅停止
    keyword = "授業中"; // キーワードをリセット

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

  void showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('設定'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 設定ダイアログを閉じる
                    showKeywordSettingDialog(context); // キーワード設定ダイアログを表示
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent, // ボタンの背景色
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'キーワードを設定',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                SizedBox(height: 20),
                // 他の設定項目を追加
                ElevatedButton(
                  onPressed: () {
                    // 他の設定項目の処理
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent, // ボタンの背景色
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    '他の設定項目',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double cardHeight =
        MediaQuery.of(context).size.height / 6; // 画面の高さの1/6
    return BasePage(
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
                  Column(
                    children: List.generate(summarizedTexts.length, (index) {
                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                content: SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      Text(
                                        summarizedTexts[index],
                                        style: TextStyle(
                                            fontSize: 20, color: Colors.yellow),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 20),
                                      Text(
                                        recognizedTexts[index],
                                        style: TextStyle(
                                            fontSize: 24, color: Colors.white),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: 20),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('閉じる'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          height: cardHeight,
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
                            child: Column(
                              children: [
                                Text(
                                  summarizedTexts[index],
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: (keyword == "授業中")
                                        ? Colors.white
                                        : Colors.redAccent,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
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
                  SizedBox(height: 40),
                  // キーワード設定ボタンの追加
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
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showSettingsDialog(context); // 設定ダイアログを表示
                      },
                      icon: Icon(
                        Icons.settings,
                        color: Colors.black,
                      ),
                      label: Text(
                        '設定',
                        style: TextStyle(color: Colors.black),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent, // ボタンの背景色
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
