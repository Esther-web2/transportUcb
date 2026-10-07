import 'package:flutter/material.dart';

class ThemeService {
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);

  static void toggle() {
    mode.value =
        mode.value == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }

  static void setMode(ThemeMode m) => mode.value = m;
}
