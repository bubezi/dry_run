import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

class SoberApp extends StatelessWidget {
  const SoberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sober Streak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D1117),
      ),
      home: const HomeScreen(),
    );
  }
}