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

  List<String> ingredientList = [];

  int selectedCategoryIndex = 0;

  final Set<int> selectedIngredients = {};

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
      _getIngredients();
    });
  }

  Future<void> _getIngredients() async {
    String selectedCategory = categoryTabs[selectedCategoryIndex];

    Query query = fs.collection('ingredients');

    if (selectedCategory != "전체") {
      query = query.where('category', isEqualTo: selectedCategory);
    }

    final snapshot = await query.get();

    final List<String> ingredients = snapshot.docs
        .map((doc)=>doc['name'] as String)
        .toList();

    setState(() {
      ingredientList = ingredients;
      print(ingredientList);
    });
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
            searchIngredients(),
            _categoryBar(),
            Expanded(
                child: ingredientsGrid()
            )
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
                  print(categoryTabs[selectedCategoryIndex]);
                  _getIngredients();
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

  Widget ingredientsGrid() {
    return GridView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: ingredientList.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1
        ),
        itemBuilder: (context, index) {
          final isSelected = selectedIngredients.contains(index);

          return GestureDetector(
            onTap: (){
              setState(() {
                if (isSelected) {
                  selectedIngredients.remove(index);
                } else {
                  selectedIngredients.add(index);
                }

                final selectedNames = selectedIngredients.map((i)=>ingredientList[i]).toList();
                print('$selectedNames');
              });
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: Colors.blueAccent, width: 2)
                    : null,
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      ingredientList[index],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  if(isSelected)
                    const Positioned(
                      top: 6,
                      left: 6,
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.blueAccent,
                        size: 20,
                      )
                    )
                ],
              ),
            ),
          );
        }
    );
  }

  Widget searchIngredients() {
    return TextField();
  }
}
