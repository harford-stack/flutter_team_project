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

        // --- 한글입력 관련(시작) --- // 아직 안됨 ㅠㅠ (현지)
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko', 'KR'), // 한국어 우선 설정
          Locale('en', 'US'), // 영어
        ],
        locale: const Locale('ko', 'KR'), // 앱의 기본 언어를 한국어로 강제 설정
        // --- 여기까지 ---

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