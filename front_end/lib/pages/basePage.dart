import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/MordalProvider.dart';
import 'summaryPage.dart';
import 'taskManagementPage.dart';
import 'settingPage.dart';

class BasePage extends StatelessWidget {
  final Widget body;

  BasePage({required this.body});

  @override
  Widget build(BuildContext context) {
    bool isModalVisible = context.watch<ModalProvider>().isModalVisible;

    return Scaffold(
      appBar: AppBar(
        title: Text('taskEcho'),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              context.read<ModalProvider>().toggleModal();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          body,
          // フローティングアクションボタン
          Positioned(
            bottom: 30,
            right: 30,
            child: FloatingActionButton(
              onPressed: () {
                context.read<ModalProvider>().toggleModal();
              },
              backgroundColor: Colors.cyanAccent,
              child: Icon(
                isModalVisible ? Icons.close : Icons.menu,
                color: Colors.black,
              ),
            ),
          ),
          if (isModalVisible)
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  context.read<ModalProvider>().toggleModal();
                },
                child: Container(
                  color: Colors.black87.withOpacity(0.8),
                  child: Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.6,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black45,
                            blurRadius: 15,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'メニュー',
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 30),
                          ListTile(
                            leading: Icon(Icons.mic, color: Colors.cyanAccent),
                            title: Text('音声認識',
                                style: TextStyle(color: Colors.white)),
                            onTap: () {
                              // "音声認識" ページのため何もせず閉じる
                              context.read<ModalProvider>().toggleModal();
                            },
                          ),
                          Divider(color: Colors.grey),
                          ListTile(
                            leading:
                                Icon(Icons.summarize, color: Colors.cyanAccent),
                            title: Text('要約一覧',
                                style: TextStyle(color: Colors.white)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SummaryPage()),
                              );
                              context.read<ModalProvider>().toggleModal();
                            },
                          ),
                          // 他のListTileメニュー項目
                          Divider(color: Colors.grey),
                          ListTile(
                            leading: Icon(Icons.task, color: Colors.cyanAccent),
                            title: Text('課題管理',
                                style: TextStyle(color: Colors.white)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => TaskManagementPage()),
                              );
                              context.read<ModalProvider>().toggleModal();
                            },
                          ),
                          Divider(color: Colors.grey),
                          ListTile(
                            leading:
                                Icon(Icons.settings, color: Colors.cyanAccent),
                            title: Text('設定',
                                style: TextStyle(color: Colors.white)),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SettingPage()),
                              );
                              context.read<ModalProvider>().toggleModal();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
