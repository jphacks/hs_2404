import 'package:flutter/material.dart';

class RecognitionProvider with ChangeNotifier {
  bool _isRecognizing = false;

  bool get isRecognizing => _isRecognizing;

  void startRecognizing() {
    _isRecognizing = true;
    notifyListeners();
  }

  void stopRecognizing() {
    _isRecognizing = false;
    notifyListeners();
  }
}