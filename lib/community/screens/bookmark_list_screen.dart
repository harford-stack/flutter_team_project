import 'package:flutter/material.dart';
import '../../common/custom_appbar.dart';
import '../../common/custom_footer.dart';
import '../../common/custom_drawer.dart';
import '../../recipes/ingreCheck_screen.dart';

class BookmarkListScreen extends StatefulWidget {
  const BookmarkListScreen({super.key});

  @override
  State<BookmarkListScreen> createState() => _BookmarkListScreenState();
}

class _BookmarkListScreenState extends State<BookmarkListScreen> {

  void _handleFooterTap(int index) {
    if (index == 2) {
      Navigator.pop(context);
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => IngrecheckScreen()),
      );
    } else if (index == 0) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('해당 기능은 개발 중입니다')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      drawer: CustomDrawer(),
      body:Container(

      ),
      bottomNavigationBar: CustomFooter(
        currentIndex: 2,
        onTap: _handleFooterTap,
      ),
    );
  }
}