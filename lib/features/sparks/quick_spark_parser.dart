import 'package:flutter/material.dart';

import '../../core/models/pith_models.dart';
import '../../core/utils/date_labels.dart';

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

    final mentionMatch = RegExp(r'^@([^:]+?)\s*:').firstMatch(trimmed);
    if (mentionMatch != null) {
      final mention = mentionMatch.group(1)?.trim().toLowerCase() ?? '';
      if (mention.isEmpty) {
        return null;
      }
      final allowed = [profile.name.toLowerCase(), profile.initials.toLowerCase()];
      if (!allowed.any((entry) => entry.contains(mention) || mention.contains(entry))) {
        return null;
      }
    }

    final rawContent = trimmed.replaceFirst(RegExp(r'^@[^:]+?\s*:\s*'), '').trim();
    final content = rawContent.isEmpty ? trimmed : rawContent;

    return QuickSparkParseResult(
      spark: QuickSparkEntry(
        dateLabel: DateLabels.monthDayYear(now ?? DateTime.now()),
        content: _normalizeSentence(content),
        highlighted: true,
      ),
      inferredInterests: _inferInterests(content, profile),
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

    return inferred;
  }
}