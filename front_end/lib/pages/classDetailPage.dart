import 'package:flutter/material.dart';

class ClassDetailPage extends StatelessWidget {
  final String className;

  ClassDetailPage({required this.className});

  @override
  Widget build(BuildContext context) {
    // ここに授業の詳細ページの内容を追加します
    return Scaffold(
      appBar: AppBar(
        title: Text(className),
      ),
      body: Center(
        child: Text('授業の詳細ページ: $className'),
      ),
    );
  }
}