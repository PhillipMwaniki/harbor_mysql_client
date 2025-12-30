import 'package:flutter/material.dart';
import 'ui/theme/app_theme.dart';
import 'ui/screens/main_screen.dart';

void main() {
  runApp(const HarborApp());
}

class HarborApp extends StatelessWidget {
  const HarborApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Harbor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}
