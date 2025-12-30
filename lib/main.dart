import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_team_project/recipes/ingreCheck_screen.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'auth/splash_screen.dart';
import 'auth/auth_provider.dart';
import 'providers/temp_ingre_provider.dart'; // 추가 (현지)
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // dotenv 초기화 (ai 레시피 받기위해)
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<TempIngredientProvider>(
          create: (_) => TempIngredientProvider(),
        ),
      ],
      child: MaterialApp(
        title: '어플 이름',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        ),
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}