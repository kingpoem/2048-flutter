import 'package:flutter/material.dart';

class EvolutionTheme {
  static const background = Color(0xFF0B1A14);
  static const board = Color(0xFF163328);
  static const boardBorder = Color(0xFF2A5C45);
  static const emptyCell = Color(0xFF1E3D30);
  static const accent = Color(0xFF5CE1A8);
  static const accentSoft = Color(0xFF3DB88A);
  static const textPrimary = Color(0xFFE8F5EE);
  static const textMuted = Color(0xFF8FB9A5);
  static const mergeGlow = Color(0xFF7FFFD4);

  static const stages = <int, EvolutionStage>{
    2: EvolutionStage('原核生物', '单细胞 · 细菌'),
    4: EvolutionStage('变形虫', '单细胞 · 伪足'),
    8: EvolutionStage('藻类', '单细胞 · 光合'),
    16: EvolutionStage('草履虫', '原生生物'),
    32: EvolutionStage('水母', '刺胞动物'),
    64: EvolutionStage('蠕虫', '环节动物'),
    128: EvolutionStage('鱼类', '脊椎动物'),
    256: EvolutionStage('两栖类', '登陆先锋'),
    512: EvolutionStage('爬行类', '鳞甲生灵'),
    1024: EvolutionStage('鸟类', '天空翱翔'),
    2048: EvolutionStage('哺乳类', '智慧生命'),
  };

  static EvolutionStage stageFor(int value) {
    if (value == 0) {
      return const EvolutionStage('', '');
    }
    return stages[value] ?? const EvolutionStage('智慧生命+', '超越进化');
  }

  static Color tileColor(int value) {
    return switch (value) {
      0 => emptyCell,
      2 => const Color(0xFF2E6B4F),
      4 => const Color(0xFF3A7D5C),
      8 => const Color(0xFF4A9B6E),
      16 => const Color(0xFF5CB87F),
      32 => const Color(0xFF6FD492),
      64 => const Color(0xFF8BE0A8),
      128 => const Color(0xFF4DA3C9),
      256 => const Color(0xFF5BB8D4),
      512 => const Color(0xFF7A8FD4),
      1024 => const Color(0xFFB08BE0),
      2048 => const Color(0xFFE8C96A),
      _ => const Color(0xFFFF8A65),
    };
  }

  static Color creatureColor(int value) {
    return switch (value) {
      0 => Colors.transparent,
      2 => const Color(0xFF9AE6B8),
      4 => const Color(0xFFB8F0CE),
      8 => const Color(0xFF7DDFA0),
      16 => const Color(0xFFD4FFE8),
      32 => const Color(0xFFB3E5FC),
      64 => const Color(0xFFFFCCBC),
      128 => const Color(0xFF81D4FA),
      256 => const Color(0xFFA5D6A7),
      512 => const Color(0xFFCE93D8),
      1024 => const Color(0xFFFFF59D),
      2048 => const Color(0xFFFFE082),
      _ => const Color(0xFFFFFFFF),
    };
  }

  static ThemeData materialTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.dark,
        surface: board,
      ),
      useMaterial3: true,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: textPrimary),
      ),
    );
  }
}

class EvolutionStage {
  const EvolutionStage(this.name, this.subtitle);

  final String name;
  final String subtitle;
}
