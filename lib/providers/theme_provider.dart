import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadTheme();
  }

  void toggleTheme(bool isOn) {
    _themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    _saveTheme(isOn);
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> _saveTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }
}

// Definición de Temas Modernos
class MyThemes {
  static final lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins', // If available, otherwise default
    scaffoldBackgroundColor: const Color(0xFFF3F4F6), // Light Grey Background
    primaryColor: const Color(0xFF7678ED), // Purple
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF7678ED),
      secondary: Color(0xFFFF7A55), // Orange
      surface: Colors.white,
      onSurface: Color(0xFF202022), // Dark Text
      outline: Color(0xFFE5E7EB),
    ),
    canvasColor: const Color(0xFF202022), // For Drawer/Sidebar if used
    // cardTheme commented out to avoid type mismatch in this specific environment
    // cardTheme: const CardTheme(
    //   elevation: 0,
    //   color: Colors.white,
    //   margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
    // ),
    iconTheme: const IconThemeData(color: Color(0xFF202022)),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Color(0xFF202022)),
      titleTextStyle: TextStyle(
        color: Color(0xFF202022),
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: const Color(0xFF161618), // Dark Background
    primaryColor: const Color(0xFF7678ED),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF7678ED),
      secondary: Color(0xFFFF7A55),
      surface: Color(0xFF202022), // Dark Cards
      onSurface: Colors.white,
      outline: Color(0xFF2D2D30),
    ),
    canvasColor: const Color(0xFF000000),
    // cardTheme: const CardTheme(
    //   elevation: 0,
    //   color: Color(0xFF202022),
    //   margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
    // ),
    iconTheme: const IconThemeData(color: Colors.white),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF202022),
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
  );
}
