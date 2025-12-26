import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SelectScreen());
}

class SelectScreen extends StatefulWidget {
  const SelectScreen({super.key});

  @override
  State<SelectScreen> createState() => _SelectScreenState();
}

class _SelectScreenState extends State<SelectScreen> {
  final FirebaseFirestore fs = FirebaseFirestore.instance;

  List<String> categoryList = [];
  List<String> categoryTabs = [];

  int selectedCategoryIndex = 0;

  Future<void> _getCategory() async {
    final snapshot = await fs.collection('ingredients').get();

    final List<String> categories = snapshot.docs
      .map((doc) => doc['category'] as String)
      .toSet()
      .toList();

    categories.remove('기타');

    categories.sort();

    setState(() {
      categoryList = categories;
      categoryTabs = ['전체', ...categoryList, '기타'];
      print(categoryTabs);
    });
  }

  Future<void> _getIngredients() async {
    final snapshot = await fs.collection('name').get();

    final List<String> ingredients = snapshot.docs
      .map((doc)=>doc['name'] as String)
      .toList();


  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getCategory();
  }
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            // SizedBox(height: 50,),
            _categoryBar()
          ],
        ),
      ),
    );
  }

  Widget _categoryBar() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categoryTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isSelected = index == selectedCategoryIndex;
          return GestureDetector(
            onTap: (){
              setState(() {
                selectedCategoryIndex = index;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueAccent),
              ),
              child: Text(
                categoryTabs[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,

                ),
              ),
            ),
          );
        }
      ),
    );
  }
}
