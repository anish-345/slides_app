import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'views/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const AviontiSlidesStudioApp());
}

class AviontiSlidesStudioApp extends StatelessWidget {
  const AviontiSlidesStudioApp({super.key});

  static const Color aviontiOrange = Color(0xFFC43E1C);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Avionti PowerPoint & WPS Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: aviontiOrange,
          secondary: Color(0xFF38BDF8),
          surface: Color(0xFF1E293B),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: aviontiOrange,
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
