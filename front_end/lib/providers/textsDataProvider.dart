import 'package:flutter/material.dart';

class TextsDataProvider with ChangeNotifier {
  Map<String, List<String>> _savedRecognizedTexts = {};
  Map<String, List<String>> _savedSummarizedTexts = {};

  //以下二つデータを取得するメソッド
  List<String> getRecognizedTexts(String className) {
    return _savedRecognizedTexts[className] ?? [];
  }

  List<String> getSummarizedTexts(String className) {
    return _savedSummarizedTexts[className] ?? [];
  }

  //以下二つデータを追加するメソッド
  void addRecognizedText(String className, String text) {
    if (_savedRecognizedTexts[className] == null) {
      _savedRecognizedTexts[className] = [];
    }
    _savedRecognizedTexts[className]!.add(text);
    notifyListeners();
  }

  void addSummarizedText(String className, String text) {
    if (_savedSummarizedTexts[className] == null) {
      _savedSummarizedTexts[className] = [];
    }
    _savedSummarizedTexts[className]!.add(text);
    notifyListeners();
  }
}