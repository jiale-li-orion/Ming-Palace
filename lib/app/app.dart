import 'package:flutter/material.dart';

import '../presentation/screens/experience_screen.dart';
import 'theme.dart';

/// The root widget of the Ming Palace AR experience.
///
/// Wires up the Material [ThemeData] and sets the home screen.
/// Routing is entirely state-driven (see [router.dart]), so no route table
/// is configured here.
class MingPalaceApp extends StatelessWidget {
  const MingPalaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ming Palace',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const ExperienceApp(),
    );
  }
}
