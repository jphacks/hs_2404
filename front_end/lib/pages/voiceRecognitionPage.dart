import 'package:flutter/material.dart';
import 'basePage.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../providers/classProvider.dart';
import '../providers/textsDataProvider.dart';
import '../providers/recognitionProvider.dart';

class VoiceRecognitionPage extends StatefulWidget {
  @override
  _VoiceRecognitionPageState createState() => _VoiceRecognitionPageState();
}

class _VoiceRecognitionPageState extends State<VoiceRecognitionPage> {
  //String recognizedText = "認識結果がここに表示されます";
  //String summarizedText = "要約データがここに表示されます";
  List<String> recognizedTexts = ["認識結果1", "認識結果2", "認識結果3"];
  List<String> summarizedTexts = ["要約1", "要約2", "要約3"];
  //bool isRecognizing = false;
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
  TextEditingController classController = TextEditingController();

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
    sendKeywords(); // ウィジェットの初期化時にキーワードを送信
  }

  // サーバーからデータを取得する関数
  Future<void> fetchRecognizedText() async {
    final textsDataProvider =
        Provider.of<TextsDataProvider>(context, listen: false);
    final selectedClass =
        Provider.of<ClassProvider>(context, listen: false).selectedClass;

    try {
      final response =
          await http.get(Uri.parse('http://localhost:5000/recognize'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newRecognizedText = data['recognized_text'] ?? "データが空です";
        final newSummarizedText = data['summarized_text'] ?? "要約データが空です";

        setState(() {
          // 最新のデータが前回のデータと異なる場合のみリストに追加
          if ((recognizedTexts.isEmpty ||
                  recognizedTexts.last != newRecognizedText) &&
              (summarizedTexts.isEmpty ||
                  summarizedTexts.last != newSummarizedText)) {
            recognizedTexts.add(newRecognizedText); //こっちはここでの表示用
            summarizedTexts.add(newSummarizedText);

            textsDataProvider.addRecognizedText(
                selectedClass, newRecognizedText); //保存用
            textsDataProvider.addSummarizedText(
                selectedClass, newSummarizedText);

            if (recognizedTexts.length > 3) {
              recognizedTexts.removeAt(0);
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
  final recognitionProvider = Provider.of<RecognitionProvider>(context, listen: false);
  recognitionProvider.startRecognizing();//isRecogniiingをtrueにする

    // サーバーの/startエンドポイントにリクエストを送信
    try {
      final response =
          await http.post(Uri.parse('http://localhost:5000/start'));
      if (response.statusCode == 200) {
        print("音声認識を開始しました");
        // 定期的にデータを取得するためのタイマーを設定
        timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
          if (recognitionProvider.isRecognizing) {
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
    final recognitionProvider = Provider.of<RecognitionProvider>(context, listen: false);
    recognitionProvider.stopRecognizing();

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
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // 設定ダイアログを閉じる
                    showClassSettingDialog(context); // 授業設定ダイアログを表示
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent, // ボタンの背景色
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    '授業の設定',
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

  // 授業設定ダイアログを表示する関数
  void showClassSettingDialog(BuildContext context) {
    final classProvider = Provider.of<ClassProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('授業の設定'),
              content: Container(
                height: MediaQuery.of(context).size.height * 0.6, // ダイアログの高さを指定
                width: MediaQuery.of(context).size.width * 0.6,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //授業の削除
                    SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: classProvider.classes.map((className) {
                            return ListTile(
                              title: Text(className),
                              trailing: PopupMenuButton<String>(
                                onSelected: (String result) {
                                  if (result == '削除') {
                                    setState(() {
                                      classProvider.removeClass(className);
                                    });
                                  }
                                },
                                itemBuilder: (BuildContext context) =>
                                    <PopupMenuEntry<String>>[
                                  PopupMenuItem<String>(
                                    value: '削除',
                                    child: Text('削除'),
                                    enabled: classProvider.selectedClass !=
                                        className,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    //授業の追加
                    SizedBox(height: 16),
                    TextField(
                      controller: classController,
                      decoration: InputDecoration(hintText: "新しい授業を入力"),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("キャンセル"),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (classController.text.isNotEmpty) {
                        classProvider.addClass(classController.text);
                        classController.clear();
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text("追加"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double cardHeight =
        MediaQuery.of(context).size.height / 6; // 画面の高さの1/6
    final classProvider = Provider.of<ClassProvider>(context);
    final recognitionProvider = Provider.of<RecognitionProvider>(context);

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
            SingleChildScrollView(
            child: Center(
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
                                              fontSize: 20,
                                              color: Colors.yellow),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 20),
                                        Text(
                                          recognizedTexts[index],
                                          style: TextStyle(
                                              fontSize: 24,
                                              color: Colors.white),
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
                        recognitionProvider.isRecognizing ? Icons.stop : Icons.mic,
                        color: Colors.black,
                      ),
                      label: Text(
                        recognitionProvider.isRecognizing ? '停止' : '開始',
                        style: TextStyle(color: Colors.black),
                      ),
                      onPressed: recognitionProvider.isRecognizing ? stopRecording : startRecording,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: recognitionProvider.isRecognizing
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
                    SizedBox(height: 20),
                    DropdownButton<String>(
                      hint: Text("授業を選択"),
                      value: context.watch<ClassProvider>().selectedClass,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            context
                                .read<ClassProvider>()
                                .setSelectedClass(newValue);
                            print(
                                "選択された授業: ${context.read<ClassProvider>().selectedClass}");
                          });
                        }
                      },
                      items: classProvider.classes
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                    // 設定ボタンの追加
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: ElevatedButton(
                        onPressed: () {
                          showSettingsDialog(context); // 設定ダイアログを表示
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent, // ボタンの背景色
                          padding: EdgeInsets.all(16), // アイコンの周りのパディング
                          shape: CircleBorder(), // ボタンを円形にする
                          elevation: 0, // 影を削除
                        ),
                        child: Icon(
                          Icons.settings,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ),
          ],
        ),
      
    );
  }
}
