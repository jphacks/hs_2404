import 'package:flutter/material.dart';
import 'basePage.dart';
import 'package:provider/provider.dart';
import '../providers/classProvider.dart';

class SummaryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //String selectedClass = context.watch<ClassProvider>().selectedClass;
    List<String> classes = context.watch<ClassProvider>().classes;

    return BasePage(
      body: Center(
        child: ListView.builder(
          itemCount: classes.length,
          itemBuilder: (context, index) {
            return Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height / 6,
              child: Card(
                child: Center(
                  child: Text(classes[index]),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}