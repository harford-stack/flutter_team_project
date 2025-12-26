import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';  // ✅ 添加这个导入
import 'package:flutter_team_project/community/screens/community_list_screen.dart';
import '../firebase_options.dart';  // ✅ 改成 ../ (返回上一级目录)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const TempMain());  // ✅ 改成 TempMain
}

class TempMain extends StatelessWidget {
  const TempMain({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CommunityListScreen(),
                  ),
                );
              },
              child: const Text('커뮤니티 이동'),
            ),
          ],
        ),
      ),
    );
  }
}