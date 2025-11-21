import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:attendance_app/core/theme/app_theme.dart';
import 'package:attendance_app/ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBJckaRlMOqVd90pZu5hYcIwWZsi0LMWBM',
        appId: '1:278759998607:android:515c585abb88382f8d1cfa',
        messagingSenderId: '278759998607',
        projectId: 'attendance-app-1252e',
      ),
    );
    print("Firebase Terhubung: ${Firebase.app().options.projectId}");
  } catch (e) {
    print("Firebase gagal terhubung: $e");
  }
  
  runApp(const AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      // home: const SplashScreen(),
    );
  }
}