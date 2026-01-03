import 'package:flutter/material.dart';

class LanguageBadge extends StatelessWidget {
  final String code; // 'ko','en','ja','zh'...
  const LanguageBadge({super.key, required this.code});

  String get label {
    switch (code) {
      case 'ko': return '한국어';
      case 'en': return 'English';
      case 'ja': return '日本語';
      case 'zh': return '中文';
      default: return code.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}
