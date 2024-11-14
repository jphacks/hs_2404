import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'basePage.dart';
import '../providers/textsDataProvider.dart';

class ClassDetailPage extends StatelessWidget {
  final String className;

  ClassDetailPage({required this.className});

  @override
  Widget build(BuildContext context) {
    final textsDataProvider = Provider.of<TextsDataProvider>(context);
    List<String> recognizedTexts =
        textsDataProvider.getRecognizedTexts(className);
    List<String> summarizedTexts =
        textsDataProvider.getSummarizedTexts(className);

    // リストの長さを一致させる
    int itemCount = recognizedTexts.length < summarizedTexts.length
        ? recognizedTexts.length
        : summarizedTexts.length;

    // ここに授業の詳細ページの内容を追加します
    return Scaffold(
      appBar: AppBar(
        title: Text('$className'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: BasePage(
        body: ListView.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) {
            int reverseIndex = itemCount - 1 - index;
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Container(
                height: 150,
                child: ListTile(
                  title: Center(
                      child: Text(
                    summarizedTexts[reverseIndex],
                    style: TextStyle(fontSize: 24),
                  )),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('詳細'),
                          content: Text(recognizedTexts[reverseIndex]),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('閉じる'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
