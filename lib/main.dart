import 'package:flutter/material.dart';

import 'ui/evolution_theme.dart';
import 'ui/game_page.dart';

void main() {
  runApp(const GameApp());
}

class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '进化 2048',
      debugShowCheckedModeBanner: false,
      theme: EvolutionTheme.materialTheme(),
      home: const GamePage(),
    );
  }
}
