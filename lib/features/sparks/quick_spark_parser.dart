import 'package:flutter/material.dart';

import '../../core/models/pith_models.dart';

class QuickSparkParseResult {
  const QuickSparkParseResult({
    required this.spark,
    required this.inferredInterests,
  });

  final QuickSparkEntry spark;
  final List<ProfileInterest> inferredInterests;
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

    final mentionMatch = RegExp(r'^@([^:]+):').firstMatch(trimmed);
    if (mentionMatch != null) {
      final mention = mentionMatch.group(1)?.trim().toLowerCase() ?? '';
      final allowed = [profile.name.toLowerCase(), profile.initials.toLowerCase()];
      if (!allowed.any((entry) => entry.contains(mention) || mention.contains(entry))) {
        return null;
      }
    }

    final rawContent = trimmed.replaceFirst(RegExp(r'^@[^:]+:\s*'), '').trim();
    final content = rawContent.isEmpty ? trimmed : rawContent;

    return QuickSparkParseResult(
      spark: QuickSparkEntry(
        dateLabel: _formatDate(now ?? DateTime.now()),
        content: _normalizeSentence(content),
        highlighted: true,
      ),
      inferredInterests: _inferInterests(content, profile),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
      addInterest(const ProfileInterest(label: '90s Rap', icon: Icons.music_note_rounded));
    }
    if (RegExp(r'vinyl|vinilo|record').hasMatch(normalized)) {
      addInterest(const ProfileInterest(label: 'Analog Vinyl', icon: Icons.album_rounded));
    }
    if (RegExp(r'coffee|cafe|roast').hasMatch(normalized)) {
      addInterest(const ProfileInterest(label: 'Light Roast', icon: Icons.coffee_rounded));
    }
    if (RegExp(r'sail|sailing|vela|regatta|coastal').hasMatch(normalized)) {
      addInterest(const ProfileInterest(label: 'Coastal Racing', icon: Icons.sailing_rounded));
    }
    if (RegExp(r'brutalis|architect|arquitect').hasMatch(normalized)) {
      addInterest(const ProfileInterest(label: 'Brutalism', icon: Icons.architecture_rounded));
    }
    if (RegExp(r'mezcal').hasMatch(normalized)) {
      addInterest(const ProfileInterest(label: 'Mezcal', icon: Icons.liquor_rounded));
    }
    if (RegExp(r'chocolate').hasMatch(normalized)) {
      addInterest(const ProfileInterest(label: 'Dark Chocolate', icon: Icons.cake_rounded));
    }

    return inferred;
  }
}