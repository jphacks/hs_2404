import 'package:flutter/material.dart';

class SummaryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('要約一覧'),
      ),
      body: Center(
        child: Text('要約一覧の内容がここに表示されます'),
      ),
    );
  }
}