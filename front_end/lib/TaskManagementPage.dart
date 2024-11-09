import 'package:flutter/material.dart';

class TaskManagementPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('課題管理'),
      ),
      body: Center(
        child: Text('ここで課題の管理をする'),
      ),
    );
  }
}