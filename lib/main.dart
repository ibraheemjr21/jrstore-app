import 'package:flutter/material.dart';
import 'package:jr_store/firebase_options.dart';
import 'screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase Initialized Successfully");
  } catch (e) {
    print("Firebase Initialization Error: $e");
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jr Store',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black, // خلفية التطبيق سوداء
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green, // شريط العنوان أخضر
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(
              color: Colors.white), // تصحيح اللون ليكون مرئيًا على الأسود
          bodyMedium: TextStyle(color: Colors.white),
        ),
        cardColor: Colors.grey[900], // لون البطاقات أسود غامق
      ),
      home: HomeScreen(),
    );
  }
}
