import 'dart:convert';
import 'package:http/http.dart' as http;

class VoskApi {
  static const String apiUrl = 'http://192.168.2.94:5000/upload'; // Flask APIのURL

  // 録音データをVosk APIに送信
  static Future<void> sendAudio(List<int> audioChunks) async {
    final response = await http.post(
      Uri.parse(apiUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'audio': audioChunks}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // 音声認識結果を表示
      print('認識結果: ${data['recognized_text']}');
    } else {
      print('APIエラー: ${response.statusCode}');
    }
  }
}
