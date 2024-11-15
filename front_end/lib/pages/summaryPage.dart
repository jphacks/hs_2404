import 'package:flutter/material.dart';
import 'basePage.dart';
import 'package:provider/provider.dart';
import '../providers/classProvider.dart';
import 'classDetailPage.dart';

class SummaryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<String> classes = context.watch<ClassProvider>().classes;

    return BasePage(
      body: Center(
        child: ListView.builder(
          itemCount: classes.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ClassDetailPage(className: classes[index]),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.symmetric(vertical: 8.0),
                width: MediaQuery.of(context).size.width * 0.9, // カードの幅を調整
                height: MediaQuery.of(context).size.height / 6,
                child: Card(
                  child: Center(
                    child: Text(classes[index], style: TextStyle(fontSize: 24)),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

