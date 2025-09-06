import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Color pickerColor = themeProvider.primaryColor;

            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Pick a color"),
                  content: SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: pickerColor,
                      onColorChanged: (color) {
                        pickerColor = color;
                      },
                      enableAlpha: false,
                      pickerAreaHeightPercent: 0.8,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        themeProvider.setPrimaryColor(pickerColor);
                        Navigator.of(context).pop();
                      },
                      child: const Text("Select"),
                    ),
                  ],
                );
              },
            );
          },
          child: const Text("Change App Color"),
        ),
      ),
    );
  }
}
