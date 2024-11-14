import 'package:flutter/material.dart';
import 'basePage.dart';

class SummaryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BasePage(
      body: Center(
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height / 6,
          child: Card(
            child: Center(
              child: Text('授業名'),
            ),
          ),
        ),
      ),
    );
  }
}
