import 'package:flutter/material.dart';

class ModalProvider with ChangeNotifier {
  bool _isModalVisible = false;

  bool get isModalVisible => _isModalVisible;

  void toggleModal() {
    _isModalVisible = !_isModalVisible;
    notifyListeners();
  }
}
