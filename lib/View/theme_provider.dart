import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  Color _primaryColor = Colors.deepPurple;

  Color get primaryColor => _primaryColor;

  ThemeProvider() {
    _loadColorFromPrefs();
  }

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    notifyListeners();
    _saveColorToPrefs(color);
  }

  Future<void> _saveColorToPrefs(Color color) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt("primaryColor", color.value);
  }

  Future<void> _loadColorFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final colorValue = prefs.getInt("primaryColor");

    if (colorValue != null) {
      _primaryColor = Color(colorValue);
      notifyListeners();
    }
  }
}
