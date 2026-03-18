import 'package:flutter/material.dart';

import '../../core/models/pith_models.dart';
import '../../core/utils/date_labels.dart';

class QuickSparkParseResult {
  const QuickSparkParseResult({
    required this.spark,
    required this.inferredInterests,
    this.inferredBirthday,
  });

  final QuickSparkEntry spark;
  final List<ProfileInterest> inferredInterests;
  final DateTime? inferredBirthday;
}

class QuickSparkParser {
  static QuickSparkParseResult? parse({
    required String input,
    required ContactProfile profile,
    DateTime? now,
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final mentionTokens = <String>{
      '@${profile.name.toLowerCase()}',
      '@${profile.initials.toLowerCase()}',
      '@${profile.name.toLowerCase().split(' ').first}',
    };
    final mentionsInText = RegExp(r'@[A-Za-zÀ-ÿ0-9._-]+').allMatches(trimmed.toLowerCase());
    for (final match in mentionsInText) {
      final mention = match.group(0);
      if (mention == null) {
        continue;
      }
      if (!mentionTokens.contains(mention)) {
        return null;
      }
    }

    final rawContent = trimmed
        .replaceAll(RegExp(r'@[A-Za-zÀ-ÿ0-9._-]+\s*:?' ), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    final content = rawContent.isEmpty ? trimmed : rawContent;

    return QuickSparkParseResult(
      spark: QuickSparkEntry(
        dateLabel: DateLabels.monthDayYear(now ?? DateTime.now()),
        content: _normalizeSentence(content),
        highlighted: true,
      ),
      inferredInterests: _inferInterests(content, profile),
      inferredBirthday: _inferBirthday(content, now ?? DateTime.now()),
    );
  }

  static String _normalizeSentence(String content) {
    if (content.isEmpty) {
      return content;
    }

    final first = content.substring(0, 1).toUpperCase();
    final rest = content.substring(1);
    final normalized = '$first$rest';
    return RegExp(r'[.!?]$').hasMatch(normalized) ? normalized : '$normalized.';
  }

  static List<ProfileInterest> _inferInterests(
    String content,
    ContactProfile profile,
  ) {
    final normalized = content.toLowerCase();
    final existing = profile.interests.map((entry) => entry.label.toLowerCase()).toSet();
    final inferred = <ProfileInterest>[];

    void addInterest(ProfileInterest interest) {
      final label = interest.label.toLowerCase();
      if (existing.contains(label) || inferred.any((entry) => entry.label.toLowerCase() == label)) {
        return;
      }
      inferred.add(interest);
    }

    if (RegExp(r'rap|hip hop|hip-hop').hasMatch(normalized)) {
      addInterest(const ProfileInterest(label: 'Rap noventero', icon: Icons.music_note_rounded));
    }
    if (RegExp(r'vinyl|vinilo|record').hasMatch(normalized)) {
      addInterest(const ProfileInterest(label: 'Vinilo analogico', icon: Icons.album_rounded));
    }
    if (RegExp(r'coffee|cafe|roast').hasMatch(normalized)) {
      addInterest(const ProfileInterest(label: 'Tueste ligero', icon: Icons.coffee_rounded));
    }
    if (RegExp(r'sail|sailing|vela|regatta|coastal').hasMatch(normalized)) {
      addInterest(const ProfileInterest(label: 'Regata costera', icon: Icons.sailing_rounded));
    }
    if (RegExp(r'brutalis|architect|arquitect').hasMatch(normalized)) {
      addInterest(const ProfileInterest(label: 'Brutalismo', icon: Icons.architecture_rounded));
    }
    if (RegExp(r'mezcal').hasMatch(normalized)) {
      addInterest(const ProfileInterest(label: 'Mezcal', icon: Icons.liquor_rounded));
    }
    if (RegExp(r'chocolate').hasMatch(normalized)) {
      addInterest(const ProfileInterest(label: 'Chocolate oscuro', icon: Icons.cake_rounded));
    }
    if (RegExp(r'\b(hoy|manana|lunes|martes|miercoles|jueves|viernes|sabado|domingo|enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre|\d{1,2}/\d{1,2})\b').hasMatch(normalized)) {
      addInterest(const ProfileInterest(label: 'Planes con fecha', icon: Icons.event_rounded));
    }
    return inferred;
  }

  static DateTime? _inferBirthday(String content, DateTime now) {
    final normalized = content.toLowerCase();
    final hasBirthdayIntent = normalized.contains('cumple') || normalized.contains('birthday');
    if (!hasBirthdayIntent) {
      return null;
    }

    final slashMatch = RegExp(r'\b(\d{1,2})[/-](\d{1,2})(?:[/-](\d{2,4}))?\b').firstMatch(normalized);
    if (slashMatch != null) {
      final day = int.tryParse(slashMatch.group(1) ?? '');
      final month = int.tryParse(slashMatch.group(2) ?? '');
      final yearRaw = int.tryParse(slashMatch.group(3) ?? '');
      if (day != null && month != null) {
        final year = yearRaw == null
            ? now.year
            : (yearRaw < 100 ? 2000 + yearRaw : yearRaw);
        final parsed = _safeDate(year: year, month: month, day: day);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    final textMatch = RegExp(
      r'\b(\d{1,2})\s+de\s+(enero|febrero|marzo|abril|mayo|junio|julio|agosto|septiembre|octubre|noviembre|diciembre)(?:\s+de\s+(\d{4}))?\b',
    ).firstMatch(normalized);

    if (textMatch != null) {
      final day = int.tryParse(textMatch.group(1) ?? '');
      final monthName = textMatch.group(2);
      final year = int.tryParse(textMatch.group(3) ?? '') ?? now.year;
      final month = _monthFromSpanish(monthName);

      if (day != null && month != null) {
        return _safeDate(year: year, month: month, day: day);
      }
    }

    return null;
  }

  static int? _monthFromSpanish(String? value) {
    return switch (value) {
      'enero' => 1,
      'febrero' => 2,
      'marzo' => 3,
      'abril' => 4,
      'mayo' => 5,
      'junio' => 6,
      'julio' => 7,
      'agosto' => 8,
      'septiembre' => 9,
      'octubre' => 10,
      'noviembre' => 11,
      'diciembre' => 12,
      _ => null,
    };
  }

  static DateTime? _safeDate({
    required int year,
    required int month,
    required int day,
  }) {
    if (month < 1 || month > 12) {
      return null;
    }

    final nextMonth = month == 12 ? 1 : month + 1;
    final nextMonthYear = month == 12 ? year + 1 : year;
    final maxDay = DateTime(nextMonthYear, nextMonth, 0).day;
    if (day < 1 || day > maxDay) {
      return null;
    }

    return DateTime(year, month, day);
  }
}