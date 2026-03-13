import '../../core/models/pith_models.dart';

class GiftSuggestion {
  const GiftSuggestion({required this.title, required this.reason});

  final String title;
  final String reason;
}

class GiftRecommender {
  static List<GiftSuggestion> recommend(ContactProfile profile) {
    final source = '${profile.interests.map((entry) => entry.label).join(' ')} '
        '${profile.sparks.map((entry) => entry.content).join(' ')}'
            .toLowerCase();

    final suggestions = <GiftSuggestion>[];

    void add(String title, String reason) {
      if (suggestions.any((item) => item.title == title)) {
        return;
      }
      suggestions.add(GiftSuggestion(title: title, reason: reason));
    }

    if (_hasAny(source, ['rap', 'hip-hop', 'hip hop', 'vinyl'])) {
      add(
        'Rare 90s hip-hop vinyl pressing',
        'Matches the profile preference for rap history and analog records.',
      );
    }

    if (_hasAny(source, ['coffee', 'roast', 'espresso'])) {
      add(
        'Single-origin light roast set',
        'Fits recurring mentions around coffee rituals and tasting details.',
      );
    }

    if (_hasAny(source, ['garden', 'flowers', 'flor'])) {
      add(
        'Curated cream-tone flower arrangement',
        'Aligned with previous sparks about floral taste and warm palettes.',
      );
    }

    if (_hasAny(source, ['opera', 'piano', 'music'])) {
      add(
        'Opera or chamber music evening',
        'Builds on documented preference for classical performances.',
      );
    }

    if (_hasAny(source, ['chocolate', 'mezcal'])) {
      add(
        'Craft dark chocolate + mezcal pair',
        'Directly references saved sparks about flavor preferences.',
      );
    }

    if (suggestions.isEmpty) {
      add(
        'Handwritten premium gift note',
        'Safe fallback while gathering more preference signals.',
      );
    }

    return suggestions.take(3).toList(growable: false);
  }

  static bool _hasAny(String source, List<String> terms) {
    for (final term in terms) {
      if (source.contains(term)) {
        return true;
      }
    }
    return false;
  }
}