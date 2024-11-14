import 'package:flutter/material.dart';
import 'package:flutter_speech_to_text/pages/voiceRecognitionPage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart'; // providerをインポート
import 'providers/MordalProvider.dart';
import 'providers/classProvider.dart';
import 'providers/textsDataProvider.dart';

class SpeechToTextApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'taskEcho',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
        scaffoldBackgroundColor: Color(0xFF0F0F1F), // ダークテーマ背景色
      ),
      home: VoiceRecognitionPage(),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter のバインディングを初期化
  await dotenv.load(fileName: ".env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ClassProvider()),
        ChangeNotifierProvider(create: (context) => ModalProvider()),
        ChangeNotifierProvider(create: (_) => TextsDataProvider()),
      ],
      child: SpeechToTextApp(),
    ),
  );
}
