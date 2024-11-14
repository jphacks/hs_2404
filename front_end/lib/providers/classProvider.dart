import 'package:flutter/material.dart';

class ClassProvider with ChangeNotifier {
  String _selectedClass = "プログラミングの授業";
  List<String> _classes = ["プログラミングの授業"];

  String get selectedClass => _selectedClass;
  List<String> get classes => _classes;

  void setSelectedClass(String newClass) {
    _selectedClass = newClass;
    notifyListeners();
  }

  void addClass(String newClass) {
    _classes.add(newClass);
    notifyListeners();
  }

  void removeClass(String targetClass) {
    _classes.remove(targetClass);
    notifyListeners();
  }

  void updateClass(String targetClass, String newClass) {
    _classes[_classes.indexOf(targetClass)] = newClass;
    notifyListeners();
  }
}