import 'package:flutter/material.dart';

class MoodColors {
  static Color glow(String mood) {
    switch (mood.toLowerCase()) {
      case 'cheerful':
        return Colors.pinkAccent;
      case 'energetic':
        return Colors.orangeAccent;
      case 'calm':
        return Colors.lightBlueAccent;
      case 'romantic':
        return Colors.purpleAccent;
      case 'focused':
        return Colors.cyanAccent;
      case 'creative':
        return Colors.indigoAccent;
      default:
        return Colors.purpleAccent;
    }
  }
}
