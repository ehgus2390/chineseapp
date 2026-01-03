import 'package:flutter/material.dart';
class LanguageBadge extends StatelessWidget {
  final String code; // 'ko','en','ja','zh'...
  const LanguageBadge({super.key, required this.code});

  String labelFor(BuildContext context) {
    switch (code) {
      case 'ko':
        return 'Korean';
      case 'en':
        return 'English';
      case 'ja':
        return 'Japanese';
      case 'zh':
        return 'Chinese';
      default:
        return code.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(labelFor(context)));
  }
}
