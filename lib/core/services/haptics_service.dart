import 'package:flutter/services.dart';

class HapticsService {
  const HapticsService._();

  static Future<void> tap() => HapticFeedback.lightImpact();

  static Future<void> select() => HapticFeedback.selectionClick();

  static Future<void> success() => HapticFeedback.mediumImpact();

  static Future<void> warning() => HapticFeedback.heavyImpact();
}
